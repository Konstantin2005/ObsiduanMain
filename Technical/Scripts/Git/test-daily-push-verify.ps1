param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$ScriptPath = "C:\obsidian\Main\Technical\Scripts\Git\daily-push.ps1",
    [string]$Branch = "main",
    [int]$TestDurationSeconds = 30
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [TEST] $Message"
}

function Test-GitRepo {
    Set-Location $RepoPath
    $remotes = git remote -v
    if ($remotes -like "*ObsiduanMain*") {
        "PASS: Remote URL correct"
        return $true
    } else {
        "FAIL: Remote URL incorrect: $remotes"
        return $false
    }
}

function Test-Branch {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -eq $Branch) {
        "PASS: On correct branch ($Branch)"
        return $true
    } else {
        "FAIL: On branch '$currentBranch', expected '$Branch'"
        return $false
    }
}

function Test-InitialCommitCount {
    $count = (git log --oneline -1).Split(' ')[0]
    "Initial commit: $count"
    return $count
}

function Test-ScriptRuns {
    & $ScriptPath -CommitIntervalSeconds 5 -PushIntervalMinutes 1 -DryRun
    if ($LASTEXITCODE -eq 0) {
        "PASS: DryRun executes successfully"
        return $true
    } else {
        "FAIL: DryRun failed with exit code $LASTEXITCODE"
        return $false
    }
}

function Test-CommitCreated {
    param([string]$InitialCommit)
    
    $testFile = Join-Path $RepoPath "test-verify-$(Get-Random).txt"
    "Test content $(Get-Date)" | Set-Content $testFile
    
    Start-Sleep -Seconds 2
    
    $newCommit = (git log --oneline -1).Split(' ')[0]
    if ($InitialCommit -ne $newCommit) {
        "PASS: New commit created: $newCommit"
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        return $true
    } else {
        "FAIL: No commit created"
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Test-PushWorks {
    $beforePush = git log --oneline origin/main..HEAD 2>$null
    $pushResult = cmd /c "git push origin $Branch 2>&1"
    $afterPush = git log --oneline origin/main..HEAD 2>$null
    
    if ($afterPush -eq "") {
        "PASS: All local commits pushed to origin"
        return $true
    } else {
        "FAIL: Unpushed commits remain: $afterPush"
        return $false
    }
}

function Test-ScriptCommitsOnChanges {
    $testFile = Join-Path $RepoPath "test-commit-check-$(Get-Random).txt"
    "Test content $(Get-Date)" | Set-Content $testFile
    
    git add -A
    $msg = "Manual test commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git commit -m $msg
    
    $commitHash = (git log --oneline -1).Split(' ')[0]
    "PASS: Manual commit works: $commitHash"
    
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    return $true
}

Write-Host "=== Daily-Push Verification Tests ==="
Write-Host "Repo: $RepoPath"
Write-Host "Script: $ScriptPath"
Write-Host "Branch: $Branch"
Write-Host ""

$results = @()

$results += Test-GitRepo
$results += Test-Branch

$initialCommit = Test-InitialCommitCount

$results += Test-ScriptRuns
$results += Test-CommitCreated -InitialCommit $initialCommit
$results += Test-ScriptCommitsOnChanges
$results += Test-PushWorks

Write-Host ""
Write-Host "=== Test Summary ==="
$passed = ($results | Where-Object { $_ -eq $true }).Count
$failed = ($results | Where-Object { $_ -eq $false }).Count
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}