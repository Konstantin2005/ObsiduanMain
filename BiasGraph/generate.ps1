# BiasGraph Vault Generator - calls Python generator
python "C:\obsidian\Main\BiasGraph\generate.py"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error running generator"
    exit 1
}
