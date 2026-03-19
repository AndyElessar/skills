<#
.SYNOPSIS
    Generates plugin.json and marketplace.json files for both Copilot CLI and Claude Code.

.DESCRIPTION
    Reads .github/plugin/marketplace.json and generates:
      - plugin.json at each plugin root (Copilot CLI)
      - .claude-plugin/plugin.json inside each plugin directory (Claude Code)
      - .claude-plugin/marketplace.json at the repository root (Claude Code)

    Uses marketplace.json as the source of truth — existing files are overwritten.

    Fields mapped from marketplace.json plugin entries:
      name, description, version, author, keywords, category, tags,
      homepage, repository, license,
      agents, skills, commands, hooks, mcpServers, lspServers

.PARAMETER MarketplacePath
    Path to marketplace.json. Defaults to .github/plugin/marketplace.json
    relative to the repository root.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER DryRun
    Show what would be generated without writing any files.

.PARAMETER Target
    Which platform(s) to generate for. Valid values:
      All     - Generate for both Copilot CLI and Claude Code (default)
      Copilot - Generate only Copilot CLI manifests (plugin.json at root)
      Claude  - Generate only Claude Code manifests (.claude-plugin/plugin.json + marketplace.json)

.EXAMPLE
    # Run from the plugin-creator skill directory — generates for both platforms
    ./scripts/generate-plugin-json.ps1

    # Dry-run to preview output
    ./scripts/generate-plugin-json.ps1 -DryRun

    # Force overwrite without confirmation
    ./scripts/generate-plugin-json.ps1 -Force

    # Generate only Copilot CLI manifests
    ./scripts/generate-plugin-json.ps1 -Force -Target Copilot

    # Generate only Claude Code manifests
    ./scripts/generate-plugin-json.ps1 -Force -Target Claude

    # Custom marketplace path
    ./scripts/generate-plugin-json.ps1 -MarketplacePath ./custom/marketplace.json
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$MarketplacePath,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [ValidateSet('All', 'Copilot', 'Claude')]
    [string]$Target = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve paths ───────────────────────────────────────────────────────────

# Walk upward until we find a directory containing .github/plugin/marketplace.json
# and treat that directory as the repository root for this script.
$repoRoot = $null
$currentDir = Get-Item -LiteralPath $PSScriptRoot

while ($currentDir) {
    if (Test-Path (Join-Path $currentDir.FullName '.github' 'plugin' 'marketplace.json')) {
        $repoRoot = $currentDir.FullName
        break
    }

    $currentDir = $currentDir.Parent
}

if (-not $repoRoot) {
    throw "No ancestor directory containing .github/plugin/marketplace.json was found when walking up from script path: $PSScriptRoot."
}

if (-not $MarketplacePath) {
    $MarketplacePath = Join-Path $repoRoot '.github' 'plugin' 'marketplace.json'
}

if (-not (Test-Path $MarketplacePath)) {
    Write-Error "marketplace.json not found at: $MarketplacePath"
    exit 1
}

Write-Host "📦 Reading marketplace.json from: $MarketplacePath" -ForegroundColor Cyan

# ── Parse marketplace ───────────────────────────────────────────────────────

$marketplace = Get-Content -Raw $MarketplacePath | ConvertFrom-Json

if (-not $marketplace.plugins -or $marketplace.plugins.Count -eq 0) {
    Write-Warning 'No plugins found in marketplace.json.'
    exit 0
}

$owner = $marketplace.owner

# ── Platform flags ──────────────────────────────────────────────────────────

$doCopilot = $Target -in @('All', 'Copilot')
$doClaude  = $Target -in @('All', 'Claude')

# ── Metadata fields to copy from marketplace entry to plugin.json ───────────

$metadataFields = @(
    'description', 'version', 'author', 'homepage', 'repository',
    'license', 'keywords', 'category', 'tags'
)

$componentFields = @(
    'agents', 'skills', 'commands', 'hooks', 'mcpServers', 'lspServers'
)

# ── Helper: build a plugin.json object from a marketplace entry ─────────────

function Build-PluginJson {
    param(
        [Parameter(Mandatory)] $Entry,
        [Parameter(Mandatory)] $Owner
    )

    $pluginJson = [ordered]@{
        name = $Entry.name
    }

    # Copy metadata fields (if present on the marketplace entry)
    foreach ($field in $script:metadataFields) {
        $value = $Entry.PSObject.Properties[$field]
        if ($value -and $null -ne $value.Value) {
            $pluginJson[$field] = $value.Value
        }
    }

    # Fall back to marketplace owner as author if not set on the entry
    if (-not $pluginJson.Contains('author') -and $Owner) {
        $authorObj = [ordered]@{ name = $Owner.name }
        if ($Owner.PSObject.Properties['email'] -and $Owner.email) {
            $authorObj['email'] = $Owner.email
        }
        $pluginJson['author'] = $authorObj
    }

    # Copy component path fields (if present)
    foreach ($field in $script:componentFields) {
        $value = $Entry.PSObject.Properties[$field]
        if ($value -and $null -ne $value.Value) {
            $pluginJson[$field] = $value.Value
        }
    }

    return $pluginJson
}

# ── Helper: write or preview a JSON file ────────────────────────────────────

function Write-JsonFile {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Label,
        [Parameter(Mandatory)] $JsonObject,
        [Parameter(Mandatory)] [bool]$IsDryRun,
        [Parameter(Mandatory)] [bool]$IsForce
    )

    $json = $JsonObject | ConvertTo-Json -Depth 10

    if ($IsDryRun) {
        Write-Host "`n── $Label ($Path) ──" -ForegroundColor Magenta
        Write-Host $json
        return $true
    }

    # Check existing file
    if ((Test-Path $Path) -and -not $IsForce) {
        $answer = Read-Host "  File already exists at '$Path'. Overwrite? [y/N]"
        if ($answer -notin @('y', 'Y', 'yes', 'Yes')) {
            Write-Host "  ⏭ Skipped '$Label'" -ForegroundColor Yellow
            return $false
        }
    }

    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $Path
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $json | Set-Content -Path $Path -Encoding UTF8
    Write-Host "  ✅ Generated: $Path" -ForegroundColor Green
    return $true
}

# ── Generate plugin.json for each plugin ────────────────────────────────────

$generated = 0
$skipped   = 0

foreach ($entry in $marketplace.plugins) {
    $pluginName = $entry.name

    if (-not $pluginName) {
        Write-Warning "Skipping plugin entry with no 'name' field."
        $skipped++
        continue
    }

    # Resolve plugin source directory relative to repo root
    $sourcePath = $entry.source

    # source can be a string or an object; only process string (relative path) sources
    if (-not $sourcePath -or $sourcePath -is [PSCustomObject]) {
        Write-Warning "Plugin '$pluginName' has no relative 'source' path — skipping plugin.json generation."
        $skipped++
        continue
    }

    # Normalise ./plugins/foo → plugins/foo
    $relPath = $sourcePath -replace '^\.\/', '' -replace '^\.\\\/', ''
    $pluginDir = Join-Path $repoRoot $relPath

    if (-not (Test-Path $pluginDir)) {
        Write-Warning "Plugin directory not found for '$pluginName': $pluginDir — skipping."
        $skipped++
        continue
    }

    # Build the plugin.json content
    $pluginJson = Build-PluginJson -Entry $entry -Owner $owner

    # ── Copilot CLI: plugin.json at plugin root ─────────────────────────
    if ($doCopilot) {
        $copilotPath = Join-Path $pluginDir 'plugin.json'
        $result = Write-JsonFile -Path $copilotPath -Label "$pluginName (Copilot)" `
            -JsonObject $pluginJson -IsDryRun $DryRun.IsPresent -IsForce $Force.IsPresent
        if ($result) { $generated++ } else { $skipped++ }
    }

    # ── Claude Code: .claude-plugin/plugin.json ─────────────────────────
    if ($doClaude) {
        $claudePluginDir = Join-Path $pluginDir '.claude-plugin'
        $claudePath = Join-Path $claudePluginDir 'plugin.json'
        $result = Write-JsonFile -Path $claudePath -Label "$pluginName (Claude)" `
            -JsonObject $pluginJson -IsDryRun $DryRun.IsPresent -IsForce $Force.IsPresent
        if ($result) { $generated++ } else { $skipped++ }
    }
}

# ── Generate Claude Code marketplace.json ───────────────────────────────────

if ($doClaude) {
    Write-Host ''
    Write-Host '📦 Generating Claude Code marketplace.json ...' -ForegroundColor Cyan

    # Build the Claude marketplace.json from the Copilot one
    $claudeMarketplace = [ordered]@{
        name = $marketplace.name
    }

    # Copy owner
    if ($owner) {
        $claudeMarketplace['owner'] = [ordered]@{ name = $owner.name }
        if ($owner.PSObject.Properties['email'] -and $owner.email) {
            $claudeMarketplace['owner']['email'] = $owner.email
        }
    }

    # Copy metadata
    if ($marketplace.PSObject.Properties['metadata'] -and $marketplace.metadata) {
        $meta = [ordered]@{}
        foreach ($prop in $marketplace.metadata.PSObject.Properties) {
            $meta[$prop.Name] = $prop.Value
        }
        $claudeMarketplace['metadata'] = $meta
    }

    # Build plugins array — keep all fields, ensure source paths use ./
    $claudePlugins = @()

    foreach ($entry in $marketplace.plugins) {
        $pluginEntry = [ordered]@{}

        foreach ($prop in $entry.PSObject.Properties) {
            $pluginEntry[$prop.Name] = $prop.Value
        }

        # Ensure relative source paths start with ./
        if ($pluginEntry.Contains('source') -and $pluginEntry['source'] -is [string]) {
            $src = $pluginEntry['source']
            if ($src -notmatch '^\./') {
                $pluginEntry['source'] = "./$src"
            }
        }

        $claudePlugins += $pluginEntry
    }

    $claudeMarketplace['plugins'] = $claudePlugins

    # Write to .claude-plugin/marketplace.json at repo root
    $claudeMarketplacePath = Join-Path $repoRoot '.claude-plugin' 'marketplace.json'
    $result = Write-JsonFile -Path $claudeMarketplacePath -Label 'Claude marketplace.json' `
        -JsonObject $claudeMarketplace -IsDryRun $DryRun.IsPresent -IsForce $Force.IsPresent
    if ($result) { $generated++ } else { $skipped++ }
}

# ── Summary ─────────────────────────────────────────────────────────────────

Write-Host ''
$targetLabel = switch ($Target) {
    'All'     { 'Copilot CLI + Claude Code' }
    'Copilot' { 'Copilot CLI only' }
    'Claude'  { 'Claude Code only' }
}

if ($DryRun) {
    Write-Host "🔍 Dry-run complete ($targetLabel) — $generated file(s) previewed, $skipped skipped." -ForegroundColor Cyan
} else {
    Write-Host "✅ Done ($targetLabel) — $generated file(s) generated, $skipped skipped." -ForegroundColor Green
}
