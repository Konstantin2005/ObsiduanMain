param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [int]$Threshold = 4,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "People split feature removed. Original diary files are left unchanged."
