# Personality Graph Generator
# This script calls the Python generator which handles UTF-8 Cyrillic properly
# PowerShell 5.1 has encoding issues with Cyrillic characters in .ps1 scripts

$scriptDir = $PSScriptRoot
if (-not $scriptDir -or $scriptDir -eq "") { $scriptDir = "C:\obsidian\Main\PersonalityGraph" }

$pythonScript = Join-Path $scriptDir "generate.py"

if (Test-Path $pythonScript) {
    Write-Host "Running Python generator..." -ForegroundColor Cyan
    python $pythonScript
} else {
    Write-Host "Error: generate.py not found at $pythonScript" -ForegroundColor Red
}
