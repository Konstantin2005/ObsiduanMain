param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "People split feature removed. No consolidation is performed."
