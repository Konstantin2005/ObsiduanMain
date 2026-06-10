[CmdletBinding()]
param(
    [string]$VaultPath = (Join-Path $PSScriptRoot '..\..\Calendula-20K'),
    [string]$StoreRoot = '',
    [int]$NodeBudget = 3000,
    [int]$EdgeBudget = 5000,
    [int]$MinimumNodes = 30000,
    [string]$NodePath = 'node',
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($StoreRoot)) {
    $StoreRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("calendula-graph-benchmark-" + [guid]::NewGuid().ToString("N"))
}

$vault = Resolve-Path -LiteralPath $VaultPath
$measureScript = Join-Path $PSScriptRoot 'measure-calendula-graph-performance.js'
$nodeArgs = @(
    $measureScript,
    '--vault', $vault.Path,
    '--store', $StoreRoot,
    '--node-budget', $NodeBudget,
    '--edge-budget', $EdgeBudget,
    '--minimum-nodes', $MinimumNodes
)

$output = & $NodePath @nodeArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    throw ($output -join [Environment]::NewLine)
}

$json = $output -join [Environment]::NewLine
$report = $json | ConvertFrom-Json

if (-not $report.ok) {
    throw "Calendula graph performance report failed validation: $json"
}

if ([int]$report.stats.nodes -lt $MinimumNodes) {
    throw "Expected at least $MinimumNodes nodes, got $($report.stats.nodes)."
}

if ($PassThru) {
    return $report
}

$json
