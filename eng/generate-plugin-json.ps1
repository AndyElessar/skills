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
    throw "Repository root not found from script path: $PSScriptRoot. Expected to find .github/plugin/marketplace.json in this repository."
}

$scriptPath = Join-Path $repoRoot 'plugins' 'plugin-creator' 'skills' 'plugin-creator' 'scripts' 'generate-plugin-json.ps1'
$resolvedScriptPath = Resolve-Path $scriptPath -ErrorAction SilentlyContinue

if (-not $resolvedScriptPath) {
    throw "Unable to find the plugin generator script at: $scriptPath. Expected repository layout: plugins/plugin-creator/skills/plugin-creator/scripts/generate-plugin-json.ps1"
}

& $resolvedScriptPath.Path @PSBoundParameters
