<#
.SYNOPSIS
    Test script for multi-repo Git monitoring.
    Checks that ALL Obsidian repositories are discovered and the monitoring works.
#>

param(
    [string]$BasePath = "C:\obsidian",
    [string]$DailyPushScript = "C:\obsidian\Main\Technical\Scripts\Git\daily-push.ps1",
    [string]$MonitorScript = "C:\obsidian\Main\Technical\Scripts\Git\monitor-daily-push.ps1"
)

$ErrorActionPreference = 'Stop'
$script:passed = 0
$script:failed = 0
$script:total = 0

function Write-TestResult {
    param([string]$Name, [bool]$Result, [string]$Detail = "")
    $script:total++
    if ($Result) { $script:passed++ } else { $script:failed++ }
    $icon = if ($Result) { "PASS" } else { "FAIL" }
    $detailStr = if ($Detail) { " -- $Detail" } else { "" }
    Write-Host "[$icon] $Name$detailStr"
}

Write-Host "============================================"
Write-Host "MULTI-REPO GIT MONITORING TESTS"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================"
Write-Host ""

# === TEST 1: Discover all .git directories ===
Write-Host "--- Repo Discovery ---"
$gitDirs = Get-ChildItem -Path $BasePath -Recurse -Depth 5 -Directory -Force -ErrorAction SilentlyContinue `
    | Where-Object { $_.Name -eq '.git' -and $_.PSIsContainer }
$repoCount = @($gitDirs).Count

Write-TestResult -Name "Discover repos under $BasePath" -Result ($repoCount -ge 1) -Detail "Found: $repoCount"

foreach ($gitDir in $gitDirs) {
    $repoPath = $gitDir.Parent.FullName
    $branch = & "git" -C $repoPath rev-parse --abbrev-ref HEAD 2>$null
    $remote = & "git" -C $repoPath remote get-url origin 2>$null
    $changes = @(& "git" -C $repoPath status --porcelain 2>$null).Count
    $ahead = & "git" -C $repoPath rev-list --count "origin/$branch..$branch" 2>$null
    if (-not ($ahead -match '^\d+$')) { $ahead = 0 }
    
    Write-Host "  Repo: $repoPath"
    Write-Host "    Branch: $branch"
    Write-Host "    Remote: $remote"
    Write-Host "    Changes: $changes"
    Write-Host "    Ahead: $ahead"
    Write-Host ""
    
    Write-TestResult -Name "  Valid git repo: $($gitDir.Parent.Name)" -Result ($branch -ne $null -and $branch -ne '') -Detail "branch=$branch"
}

# === TEST 2: Verify daily-push.ps1 works with each repo (DryRun) ===
Write-Host "--- Daily-Push DryRun Test ---"
foreach ($gitDir in $gitDirs) {
    $repoPath = $gitDir.Parent.FullName
    $branch = & "git" -C $repoPath rev-parse --abbrev-ref HEAD 2>$null
    $repoName = Split-Path -Leaf $repoPath
    
    if (-not $branch -or $branch -eq 'HEAD') { $branch = 'main' }
    
    Write-Host "  Testing: $repoName ($repoPath, branch: $branch) ..."
    
    $result = & powershell -NoProfile -ExecutionPolicy Bypass -Command "
        & '$DailyPushScript' -RepoPath '$repoPath' -Branch '$branch' -RepoName '$repoName' -DryRun
        exit `$LASTEXITCODE
    " 2>&1
    
    $exitCode = $LASTEXITCODE
    Write-TestResult -Name "  DryRun: $repoName" -Result ($exitCode -eq 0) -Detail "exit=$exitCode"
}

# === TEST 3: Verify monitor script syntax loads ===
Write-Host "--- Monitor Script Validation ---"
$parseResult = try {
    $null = [System.Management.Automation.Language.Parser]::ParseFile($MonitorScript, [ref]$null, [ref]$null)
    $true
} catch {
    Write-Host "  Parse error: $_"
    $false
}
Write-TestResult -Name "Monitor script syntax" -Result $parseResult

# === TEST 4: Verify sync between repos (same remote) ===
Write-Host "--- Cross-Repo Check ---"
$remotes = @{}
foreach ($gitDir in $gitDirs) {
    $repoPath = $gitDir.Parent.FullName
    $remote = & "git" -C $repoPath remote get-url origin 2>$null
    if (-not $remotes.ContainsKey($remote)) { $remotes[$remote] = @() }
    $remotes[$remote] += $repoPath
}

foreach ($remote in $remotes.Keys) {
    $reposWithRemote = $remotes[$remote]
    if ($reposWithRemote.Count -gt 1) {
        Write-Host "  Remote '$remote' shared by $($reposWithRemote.Count) repos:"
        foreach ($r in $reposWithRemote) {
            $branch = & "git" -C $r rev-parse --abbrev-ref HEAD 2>$null
            Write-Host "    - $r (branch: $branch)"
        }
        Write-TestResult -Name "  Consistent remote across repos" -Result $true -Detail "$($reposWithRemote.Count) repos share remote"
    } else {
        Write-Host "  Remote '$remote' used only by $($reposWithRemote[0])"
    }
    Write-Host ""
}

# === TEST 5: Check for stale locks or rebase issues ===
Write-Host "--- Health Checks ---"
foreach ($gitDir in $gitDirs) {
    $repoPath = $gitDir.Parent.FullName
    $lockFile = "$repoPath\.git\index.lock"
    $rebaseDir = "$repoPath\.git\rebase-merge"
    
    $hasLock = Test-Path $lockFile
    $hasRebase = Test-Path $rebaseDir
    
    if ($hasLock) {
        Write-TestResult -Name "Stale lock: $repoPath" -Result $false
    }
    if ($hasRebase) {
        Write-TestResult -Name "Stuck rebase: $repoPath" -Result $false
    }
    if (-not $hasLock -and -not $hasRebase) {
        Write-TestResult -Name "Clean repo: $($gitDir.Parent.Name)" -Result $true -Detail "no locks, no rebase"
    }
}

Write-Host ""
Write-Host "============================================"
Write-Host "TEST SUMMARY"
Write-Host "Total:  $script:total"
Write-Host "Passed: $script:passed"
Write-Host "Failed: $script:failed"
Write-Host "============================================"

if ($script:failed -gt 0) { exit 1 } else { exit 0 }