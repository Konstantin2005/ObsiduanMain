[CmdletBinding()]
param(
    [string]$VaultPath = '',
    [string]$OutPath = ''
)

$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'build-calendula-graph-store.js'
$defaultVaultPath = Join-Path $PSScriptRoot '..\..\Calendula-20K'
if ([string]::IsNullOrWhiteSpace($VaultPath)) {
    $VaultPath = $defaultVaultPath
}

$argsList = @($scriptPath, '--vault', (Resolve-Path -LiteralPath $VaultPath).Path)
if (-not [string]::IsNullOrWhiteSpace($OutPath)) {
    $argsList += @('--out', $OutPath)
}

& node @argsList
if ($LASTEXITCODE -ne 0) {
    throw "Graph store build failed with exit code $LASTEXITCODE"
}
