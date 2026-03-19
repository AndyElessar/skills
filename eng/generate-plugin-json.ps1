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

$scriptPath = Join-Path $PSScriptRoot '..' 'plugins' 'plugin-creator' 'skills' 'plugin-creator' 'scripts' 'generate-plugin-json.ps1'
$resolvedScriptPath = (Resolve-Path $scriptPath).Path

& $resolvedScriptPath @PSBoundParameters
