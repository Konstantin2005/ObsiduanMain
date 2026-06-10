param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "Mini diaries feature removed. No consolidation is performed."
