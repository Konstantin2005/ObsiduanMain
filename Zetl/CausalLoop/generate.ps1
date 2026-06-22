# Causal Loop Graph Generator - PowerShell Wrapper
# Calls the Python generator script
$ErrorActionPreference = "Stop"
$baseDir = "C:\obsidian\Main\CausalLoop"
$pythonScript = Join-Path $baseDir "generate.py"

Write-Host "Running Causal Loop Graph Generator..." -ForegroundColor Cyan
& python $pythonScript
Write-Host "Generation complete!" -ForegroundColor Green
