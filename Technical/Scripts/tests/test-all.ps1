#!/usr/bin/env powershell
# test-all.ps1 - Run all test suites
param([switch]$Quick,[switch]$Verbose)
$root = Split-Path -Parent $PSScriptRoot
$testsDir = Join-Path $root "tests"
$startTime = Get-Date
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OBSIDIAN VAULT AUTO-GIT TEST SUITE" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
$global:allPassed = 0
$global:allFailed = 0
$global:allSkipped = 0
function Run-TestFile {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) {
        Write-Host "[SKIP] $Label - file not found" -ForegroundColor Yellow
        $global:allSkipped++
        return
    }
    Write-Host "-- Running $Label --" -ForegroundColor Magenta
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { 
        if ($Verbose -or $_ -match '\[PASS\]|\[FAIL\]|ERROR|RESULT') {
            Write-Host "  $_"
        }
    }
    if ($exitCode -eq 0) {
        Write-Host "  -> PASSED`n" -ForegroundColor Green
        $global:allPassed++
    } else {
        Write-Host "  -> FAILED (exit code $exitCode)`n" -ForegroundColor Red
        $global:allFailed++
    }
}
Run-TestFile -Path (Join-Path $testsDir "test-core.ps1") -Label "Unit Tests"
if (-not $Quick) {
    Run-TestFile -Path (Join-Path $testsDir "integration\test-repos.ps1") -Label "Integration Tests"
} else {
    Write-Host "[SKIP] Integration tests (Quick mode)" -ForegroundColor Yellow
    $global:allSkipped++
}
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE COMPLETE" -ForegroundColor Cyan
Write-Host "  Duration: ${duration}s" -ForegroundColor Cyan
Write-Host "  Passed: $global:allPassed  Failed: $global:allFailed  Skipped: $global:allSkipped" -ForegroundColor $(if ($global:allFailed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan
if ($global:allFailed -gt 0) { exit 1 } else { exit 0 }
