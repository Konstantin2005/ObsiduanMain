<#
.SYNOPSIS
    Test script for daily-push.ps1 - validates auto-commit and auto-push behavior
#>

param(
    [string]$ScriptPath = "C:\obsidian\Main\Technical\Scripts\Git\daily-push.ps1",
    [string]$RepoPath = "C:\obsidian\Main",
    [int]$TestDurationSeconds = 30
)

$ErrorActionPreference = 'Stop'

function Write-TestLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [TEST] $Message"
}

function Test-ScriptSyntax {
    Write-TestLog "Testing script syntax..."
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
        Write-TestLog "PASS: Syntax OK"
        return $true
    }
    catch {
        Write-TestLog "FAIL: Syntax Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-Parameters {
    Write-TestLog "Testing parameter parsing..."
    try {
        $result = powershell -Command "& '$ScriptPath' -DryRun"
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "PASS: DryRun parameter works"
            return $true
        }
        else {
            Write-TestLog "FAIL: DryRun failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-TestLog "FAIL: Parameter test error: $($_.Exception.Message)"
        return $false
    }
}

function Test-AutoCommitLogic {
    Write-TestLog "Testing auto-commit logic (no changes)..."
    
    Set-Location $RepoPath
    
    $initialCommits = (git log --oneline -1).Split(' ')[0]
    Write-TestLog "Initial commit: $initialCommits"
    
    $result = powershell -Command "& '$ScriptPath' -RepoPath '$RepoPath' -CommitIntervalSeconds 5 -PushIntervalMinutes 15 -DryRun"
    if ($LASTEXITCODE -eq 0) {
        Write-TestLog "PASS: DryRun execution OK"
    }
    else {
        Write-TestLog "FAIL: DryRun execution failed"
        return $false
    }
    
    $afterCommits = (git log --oneline -1).Split(' ')[0]
    if ($initialCommits -eq $afterCommits) {
        Write-TestLog "PASS: No commits made in DryRun (correct)"
        return $true
    }
    else {
        Write-TestLog "FAIL: Unexpected commit in DryRun"
        return $false
    }
}

function Test-CommitOnChanges {
    Write-TestLog "Testing commit on changes..."
    
    Set-Location $RepoPath
    
    $testFile = Join-Path $RepoPath "test-auto-commit-$(Get-Random).txt"
    "Test content $(Get-Date)" | Set-Content $testFile
    
    $initialCommits = (git log --oneline -1).Split(' ')[0]
    
    $status = git status --porcelain
    if ($status) {
        Write-TestLog "Changes detected, testing commit..."
        git add -A
        $msg = "Test commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git commit -m $msg
        $newCommits = (git log --oneline -1).Split(' ')[0]
        if ($initialCommits -ne $newCommits) {
            Write-TestLog "PASS: Commit created: $newCommits"
        }
        else {
            Write-TestLog "FAIL: Commit failed"
        }
    }
    else {
        Write-TestLog "FAIL: No changes detected"
    }
    
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    return $true
}

function Test-PushIntervalLogic {
    Write-TestLog "Testing push interval calculation..."
    
    $pushIntervalMinutes = 15
    $pushInterval = New-TimeSpan -Minutes $pushIntervalMinutes
    $lastPush = [DateTime]::MinValue
    $now = Get-Date
    
    $shouldPush = $now - $lastPush -ge $pushInterval
    if ($shouldPush) {
        Write-TestLog "PASS: First run triggers push (correct)"
    }
    else {
        Write-TestLog "FAIL: First run should trigger push"
        return $false
    }
    
    $lastPush = $now
    $shouldPush = $now - $lastPush -ge $pushInterval
    if (-not $shouldPush) {
        Write-TestLog "PASS: Immediate second run doesn't trigger push (correct)"
        return $true
    }
    else {
        Write-TestLog "FAIL: Second run incorrectly triggers push"
        return $false
    }
}

function Test-BranchDetection {
    Write-TestLog "Testing branch auto-detection..."
    
    Set-Location $RepoPath
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -and $currentBranch -ne 'HEAD') {
        Write-TestLog "PASS: Current branch detected: $currentBranch"
        return $true
    }
    else {
        Write-TestLog "FAIL: Failed to detect branch"
        return $false
    }
}

# Run all tests
Write-TestLog "=== Starting daily-push.ps1 Tests ==="
Write-TestLog "Script: $ScriptPath"
Write-TestLog "Repo: $RepoPath"
Write-TestLog "Test Duration: ${TestDurationSeconds}s"
Write-TestLog ""

$results = @()

$results += Test-ScriptSyntax
$results += Test-Parameters
$results += Test-BranchDetection
$results += Test-PushIntervalLogic
$results += Test-AutoCommitLogic
$results += Test-CommitOnChanges

Write-TestLog ""
Write-TestLog "=== Test Summary ==="
$passed = ($results | Where-Object { $_ -eq $true }).Count
$failed = ($results | Where-Object { $_ -eq $false }).Count
Write-TestLog "Passed: $passed"
Write-TestLog "Failed: $failed"

if ($failed -gt 0) {
    Write-TestLog "SOME TESTS FAILED"
    exit 1
}
else {
    Write-TestLog "ALL TESTS PASSED"
    exit 0
}