<#
.SYNOPSIS
    Weekly git garbage collection.
    Designed to run via Windows Task Scheduler (weekly).
.EXAMPLE
    .\vault\gc.ps1
#>

$VaultRoot = Split-Path -Parent $PSScriptRoot
Set-Location $VaultRoot

Write-Host "[gc] Starting git gc..."
git gc --aggressive 2>&1
Write-Host "[gc] Done"

exit 0
