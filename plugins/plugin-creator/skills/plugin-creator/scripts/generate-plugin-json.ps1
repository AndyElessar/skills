<#
.SYNOPSIS
    Generates plugin.json files for each plugin defined in marketplace.json.

.DESCRIPTION
    Reads .github/plugin/marketplace.json and creates a plugin.json manifest
    in each plugin's source directory. Uses marketplace.json as the source of
    truth — existing plugin.json files are overwritten.

    Fields mapped from marketplace.json plugin entries:
      name, description, version, author, keywords, category, tags,
      agents, skills, commands, hooks, mcpServers, lspServers

.PARAMETER MarketplacePath
    Path to marketplace.json. Defaults to .github/plugin/marketplace.json
    relative to the repository root.

.PARAMETER Force
    Overwrite existing plugin.json files without prompting.

.PARAMETER DryRun
    Show what would be generated without writing any files.

.EXAMPLE
    # Run from repo root
    .\eng\generate-plugin-json.ps1

    # Dry-run to preview output
    .\eng\generate-plugin-json.ps1 -DryRun

    # Force overwrite without confirmation
    .\eng\generate-plugin-json.ps1 -Force

    # Custom marketplace path
    .\eng\generate-plugin-json.ps1 -MarketplacePath .\custom\marketplace.json
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$MarketplacePath,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve paths ───────────────────────────────────────────────────────────

# PSScriptRoot is the eng/ folder → parent is the repo root
$repoRoot = Split-Path -Parent $PSScriptRoot

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

# ── Metadata fields to copy from marketplace entry to plugin.json ───────────

$metadataFields = @(
    'description', 'version', 'author', 'homepage', 'repository',
    'license', 'keywords', 'category', 'tags'
)

$componentFields = @(
    'agents', 'skills', 'commands', 'hooks', 'mcpServers', 'lspServers'
)

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
    if (-not $sourcePath) {
        Write-Warning "Plugin '$pluginName' has no 'source' field — skipping."
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

    $pluginJsonPath = Join-Path $pluginDir 'plugin.json'

    # ── Check existing file ─────────────────────────────────────────────
    if ((Test-Path $pluginJsonPath) -and -not $Force -and -not $DryRun) {
        $answer = Read-Host "  plugin.json already exists for '$pluginName'. Overwrite? [y/N]"
        if ($answer -notin @('y', 'Y', 'yes', 'Yes')) {
            Write-Host "  ⏭ Skipped '$pluginName'" -ForegroundColor Yellow
            $skipped++
            continue
        }
    }

    # ── Build plugin.json object ────────────────────────────────────────
    $pluginJson = [ordered]@{
        name = $pluginName
    }

    # Copy metadata fields (if present on the marketplace entry)
    foreach ($field in $metadataFields) {
        $value = $entry.PSObject.Properties[$field]
        if ($value -and $null -ne $value.Value) {
            $pluginJson[$field] = $value.Value
        }
    }

    # Fall back to marketplace owner as author if not set on the entry
    if (-not $pluginJson.Contains('author') -and $owner) {
        $authorObj = [ordered]@{ name = $owner.name }
        if ($owner.PSObject.Properties['email'] -and $owner.email) {
            $authorObj['email'] = $owner.email
        }
        $pluginJson['author'] = $authorObj
    }

    # Copy component path fields (if present)
    foreach ($field in $componentFields) {
        $value = $entry.PSObject.Properties[$field]
        if ($value -and $null -ne $value.Value) {
            $pluginJson[$field] = $value.Value
        }
    }

    # ── Serialize ───────────────────────────────────────────────────────
    $json = $pluginJson | ConvertTo-Json -Depth 10

    if ($DryRun) {
        Write-Host "`n── $pluginName ($pluginJsonPath) ──" -ForegroundColor Magenta
        Write-Host $json
        $generated++
        continue
    }

    # ── Write file ──────────────────────────────────────────────────────
    $json | Set-Content -Path $pluginJsonPath -Encoding UTF8
    Write-Host "  ✅ Generated: $pluginJsonPath" -ForegroundColor Green
    $generated++
}

# ── Summary ─────────────────────────────────────────────────────────────────

Write-Host ''
if ($DryRun) {
    Write-Host "🔍 Dry-run complete — $generated plugin(s) previewed, $skipped skipped." -ForegroundColor Cyan
} else {
    Write-Host "✅ Done — $generated plugin.json file(s) generated, $skipped skipped." -ForegroundColor Green
}
