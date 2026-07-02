<#
.SYNOPSIS
    Registers Windows Task Scheduler tasks for vault automation.
    Run as Administrator.
    Устаревший. Используйте: .\vault\git-worker.ps1 -Mode setup
.EXAMPLE
    .\vault\register-tasks.ps1
    .\vault\register-tasks.ps1 -Remove
#>

param([switch]$Remove)

$VaultRoot = Split-Path -Parent $PSScriptRoot
$GitWorker = Join-Path $PSScriptRoot "git-worker.ps1"

if (-not (Test-Path $GitWorker)) {
    Write-Host "ERROR: git-worker.ps1 not found at $GitWorker" -ForegroundColor Red
    Write-Host "Run: .\vault\git-worker.ps1 -Mode setup"
    exit 1
}

# Делегируем всё новому единому скрипту
if ($Remove) {
    & $GitWorker -Mode setup -Remove
} else {
    & $GitWorker -Mode setup
}
