# test-core.ps1 - Unit tests for core.ps1 module
# Run: powershell -NoProfile -File Technical\Scripts\tests\test-core.ps1

$ErrorActionPreference = "Stop"
$passed = 0
$failed = 0
$skipped = 0

# Source core
. (Join-Path $PSScriptRoot "..\system\core.ps1")

# Test temp directory
$testRoot = Join-Path $env:TEMP "obsidian-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

function Write-TestResult {
    param([string]$Name, [bool]$Result, [string]$Detail = "")
    if ($Result) { $script:passed++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:failed++; Write-Host "  [FAIL] $Name : $Detail" -ForegroundColor Red }
}

function New-TestRepo {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Push-Location $Path
    git init 2>&1 | Out-Null
    git config user.email "test@test.com"
    git config user.name "Test"
    Set-Content "test.md" "# Test" -NoNewline
    git add -A 2>&1 | Out-Null
    git commit -m "initial" --no-gpg-sign 2>&1 | Out-Null
    Pop-Location
}

function Remove-TestRepo {
    param([string]$Path)
    if (Test-Path $Path) { Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue }
}

# =============================================
# TEST GROUP: Git helpers
# =============================================
Write-Host "`n=== Git Helpers ===" -ForegroundColor Cyan

# Test Invoke-Git
$testRepo = Join-Path $testRoot "invoke-git"
New-TestRepo -Path $testRepo
$result = Invoke-Git -RepoPath $testRepo -Arguments @("rev-parse", "--git-dir")
Write-TestResult "Invoke-Git basic" ($result -match "\.git")
Remove-TestRepo -Path $testRepo

# Test Get-GitDir
$testRepo = Join-Path $testRoot "get-gitdir"
New-TestRepo -Path $testRepo
$gitDir = Get-GitDir -RepoPath $testRepo
Write-TestResult "Get-GitDir returns .git path" ($gitDir -eq "$testRepo\.git")
Remove-TestRepo -Path $testRepo

# =============================================
# TEST GROUP: Change detection
# =============================================
Write-Host "`n=== Change Detection ===" -ForegroundColor Cyan

$testRepo = Join-Path $testRoot "changes"
New-TestRepo -Path $testRepo

# No changes
$count = Get-ChangeCount -RepoPath $testRepo
Write-TestResult "Get-ChangeCount detects 0 changes" ($count -eq 0) "Got: $count"

# One changed file
Set-Content -Path "$testRepo\test.md" -Value "# Test Changed" -NoNewline
$count = Get-ChangeCount -RepoPath $testRepo
Write-TestResult "Get-ChangeCount detects 1 change" ($count -eq 1) "Got: $count"

$lineCount = Get-ChangeLineCount -RepoPath $testRepo
Write-TestResult "Get-ChangeLineCount returns lines" ($lineCount -ge 0)

Remove-TestRepo -Path $testRepo

# =============================================
# TEST GROUP: Health checks
# =============================================
Write-Host "`n=== Health Checks ===" -ForegroundColor Cyan

$testRepo = Join-Path $testRoot "health"
New-TestRepo -Path $testRepo

# Test-GitRepo
$result = Test-GitRepo -RepoPath $testRepo
Write-TestResult "Test-GitRepo OK" ($result.Status -eq "OK") "Got: $($result.Status)"

# Test-GitRepo with invalid path
$result = Test-GitRepo -RepoPath "Z:\nonexistent"
Write-TestResult "Test-GitRepo fails on bad path" ($result.Status -eq "FAIL") "Got: $($result.Status)"

# Test-LockFile (no lock)
$result = Test-LockFile -RepoPath $testRepo
Write-TestResult "Test-LockFile no lock" ($result.Status -eq "OK")

# Test-LockFile detects fresh lock (returns LOCKED)
$lockFile = "$testRepo\.git\index.lock"
Set-Content -Path $lockFile -Value "stale" -NoNewline
$result = Test-LockFile -RepoPath $testRepo
Write-TestResult "Test-LockFile detects lock exists" ($result.Status -eq "LOCKED") "Got: $($result.Status)"
Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue

# Test-Rebase
$result = Test-Rebase -RepoPath $testRepo
Write-TestResult "Test-Rebase no rebase" ($result.Status -eq "OK")

# Test-Rebase with stuck rebase
$rebaseDir = "$testRepo\.git\rebase-merge"
New-Item -ItemType Directory -Path $rebaseDir -Force | Out-Null
Set-Content -Path "$rebaseDir\head-name" -Value "main" -NoNewline
$result = Test-Rebase -RepoPath $testRepo
Write-TestResult "Test-Rebase detects stuck rebase" ($result.Status -eq "STALE")

Remove-TestRepo -Path $testRepo

# =============================================
# TEST GROUP: Self-healing
# =============================================
Write-Host "`n=== Self-Healing ===" -ForegroundColor Cyan

$testRepo = Join-Path $testRoot "heal"
New-TestRepo -Path $testRepo

# Create stale lock and repair
$lockFile = "$testRepo\.git\index.lock"
Set-Content -Path $lockFile -Value "stale" -NoNewline
$repaired = Repair-LockFile -RepoPath $testRepo
Write-TestResult "Repair-LockFile removes lock" ($repaired -eq $true) "Got: $repaired"
Write-TestResult "Lock file actually gone" (-not (Test-Path $lockFile))

# Create stuck rebase and repair
$rebaseDir = "$testRepo\.git\rebase-merge"
New-Item -ItemType Directory -Path $rebaseDir -Force | Out-Null
Set-Content -Path "$rebaseDir\head-name" -Value "main" -NoNewline
$repaired = Repair-Rebase -RepoPath $testRepo
Write-TestResult "Repair-Rebase removes rebase" ($repaired -eq $true)
Write-TestResult "Rebase dir actually gone" (-not (Test-Path $rebaseDir))

Remove-TestRepo -Path $testRepo

# =============================================
# TEST GROUP: Commit
# =============================================
Write-Host "`n=== Commit ===" -ForegroundColor Cyan

$testRepo = Join-Path $testRoot "commit"
New-TestRepo -Path $testRepo

# Commit a change
Set-Content -Path "$testRepo\new.md" -Value "# New File" -NoNewline
$result = Invoke-Commit -RepoPath $testRepo -Message "test commit"
Write-TestResult "Invoke-Commit succeeds" ($global:LASTEXITCODE -eq 0 -or $result -match "changed" -or $result -match "1 file") "Got: $(($result | Out-String).Substring(0, [Math]::Min(100, ($result | Out-String).Length)))"

# Verify commit exists
$log = Invoke-Git -RepoPath $testRepo -Arguments @("log", "--oneline", "-1")
Write-TestResult "Commit message saved" ($log -match "test commit") "Got: $log"

Remove-TestRepo -Path $testRepo

# =============================================
# SUMMARY
# =============================================
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "RESULTS: $passed passed, $failed failed, $skipped skipped" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "=====================================" -ForegroundColor Cyan

# Cleanup
Remove-TestRepo -Path $testRoot

if ($failed -gt 0) { exit 1 } else { exit 0 }
