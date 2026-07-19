param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$Branch = "main",
    [string]$RepoName = "",
    [string]$GitPath = "git",
    [string]$LogPath = "",
    [int]$CheckIntervalSeconds = 5,
    [int]$PushIntervalMinutes = 60,
    [int]$MaxLogSizeMB = 100,
    [switch]$DryRun
)

# === AUTO-DETECT REPO NAME & LOG PATH ===
if (-not $RepoName) {
    $parentName = Split-Path -Leaf (Split-Path -Parent $RepoPath)
    $leafName = Split-Path -Leaf $RepoPath
    $RepoName = if ($parentName -and $parentName -ne $leafName) { "$parentName-$leafName" } else { $leafName }
}
if (-not $LogPath) {
    $logDir = "C:\obsidian\Main\Technical\Scripts\Logs"
    $LogPath = Join-Path $logDir "daily-push-$RepoName.log"
}

$ErrorActionPreference = 'Continue'

# === LOCK FILE (repo-specific) ===
$lockDir = Split-Path -Parent $LogPath
$lockFile = Join-Path $lockDir ".daily-push-$RepoName.lock"
if (Test-Path $lockFile) {
    $lockPid = Get-Content $lockFile -ErrorAction SilentlyContinue
    if ($lockPid -and (Get-Process -Id $lockPid -ErrorAction SilentlyContinue)) {
        Write-Host "[$RepoName] Another instance (PID $lockPid) already running. Exiting."
        exit 0
    } else {
        # Stale lock file
        Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
    }
}
$PID | Out-File $lockFile -Force

# === LOGGING WITH ROTATION ===
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$RepoName] $Message"
    Write-Host $line
    try {
        $logDir = Split-Path -Parent $LogPath
        if (-not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        # Rotate log if too large
        if ((Test-Path $LogPath) -and ((Get-Item $LogPath).Length -gt ($MaxLogSizeMB * 1MB))) {
            $rotated = "$LogPath.old"
            Remove-Item -LiteralPath $rotated -Force -ErrorAction SilentlyContinue
            Rename-Item -LiteralPath $LogPath -NewName "$LogPath.old" -Force -ErrorAction SilentlyContinue
            Write-Host "[$timestamp] [$RepoName] Log rotated (>${MaxLogSizeMB}MB)"
        }
        Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    } catch {}
}

# === GIT WRAPPER (silent - only log errors) ===
function Invoke-Git-Silent {
    param([string[]]$Args, [switch]$ThrowOnError)
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $output = & $GitPath @Args 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP
    if ($code -ne 0 -and $ThrowOnError) {
        $errMsg = ($output | Out-String).Trim()
        throw "git $($Args -join ' ') failed (code $code): $errMsg"
    }
    return ,$output  # comma preserves array
}

# === STATUS CHECK ===
function Test-HasChanges {
    $status = & $GitPath status --porcelain 2>$null
    return $status -ne $null -and $status -ne ""
}

# === COMMIT ===
$script:lastCommitAttempt = [DateTime]::MinValue
$script:minCommitInterval = [TimeSpan]::FromSeconds(5)

function Commit-Changes {
    try {
        Ensure-OnBranch
        
        # Rate limit: don't attempt commit more than once per interval
        $now = Get-Date
        if ($now - $script:lastCommitAttempt -lt $script:minCommitInterval) { return }
        $script:lastCommitAttempt = $now
        
        if (-not (Test-HasChanges)) { return }
        
        # There are changes - commit them
        & $GitPath add -A 2>&1 | Out-Null
        $addCode = $LASTEXITCODE
        if ($addCode -ne 0) {
            Write-Log "git add failed (code $addCode)"
            return
        }
        
        $msg = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $commitOut = & $GitPath commit -m $msg 2>&1
        $commitCode = $LASTEXITCODE
        
        if ($commitCode -eq 0) {
            # Extract short hash from output
            $hash = if ($commitOut -match '\[main [a-f0-9]+') { $matches[0] } else { "???" }
            Write-Log "Committed: $hash — $msg"
        }
        # When nothing to commit, just silently skip
    }
    catch {
        Write-Log "Commit error: $($_.Exception.Message)"
    }
}

# === BRANCH MANAGEMENT ===
function Ensure-OnBranch {
    $currentBranch = & $GitPath rev-parse --abbrev-ref HEAD 2>$null
    if ($currentBranch -ne $Branch) {
        Write-Log "Branch mismatch: on '$currentBranch', expected '$Branch'. Switching..."
        & $GitPath checkout $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "ERROR: Failed to switch to branch '$Branch'"
        }
    }
}

# === PUSH ===
$script:fetchOk = $true

function Push-Changes {
    if (-not $Branch) {
        Write-Log "ERROR: Branch name is empty"
        return
    }
    
    try {
        Ensure-OnBranch
        Write-Log "Pushing to origin/$Branch ..."
        
        # Fetch (with error tolerance)
        & $GitPath fetch --all --prune 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            if ($script:fetchOk) {
                Write-Log "WARNING: fetch failed, will retry"
                $script:fetchOk = $false
            }
            # Continue anyway — push may still work
        } else {
            $script:fetchOk = $true
        }
        
        # Pull rebase
        & $GitPath pull --rebase --autostash origin $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "WARNING: pull --rebase failed, pushing anyways"
        }
        
        # Push
        $pushOut = & $GitPath push origin $Branch 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Push completed successfully"
        } else {
            $errMsg = ($pushOut | Out-String).Trim()
            Write-Log "Push failed: $errMsg"
        }
    }
    catch {
        Write-Log "Push error: $($_.Exception.Message)"
    }
}

# === MAIN LOOP ===
Set-Location -LiteralPath $RepoPath

# Verify branch on startup
$currentBranch = & $GitPath rev-parse --abbrev-ref HEAD
if ($currentBranch -ne $Branch) {
    Write-Log "Switching from '$currentBranch' to '$Branch'..."
    & $GitPath checkout $Branch 2>&1 | Out-Null
}

Write-Log "Starting (check: ${CheckIntervalSeconds}s, push: ${PushIntervalMinutes}m)"

if ($DryRun) {
    Write-Log "DryRun mode - exiting"
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
    exit 0
}

$lastPush = [DateTime]::MinValue
$pushInterval = New-TimeSpan -Minutes $PushIntervalMinutes
$loopCount = 0

while ($true) {
    try {
        $now = Get-Date
        $loopCount++
        
        # Commit if there are changes
        Commit-Changes
        
        # Push if interval elapsed
        if ($now - $lastPush -ge $pushInterval) {
            Push-Changes
            $lastPush = $now
        }
        
        # Brief heartbeat log every 100 iterations (~500s at 5s interval)
        if ($loopCount % 100 -eq 0) {
            $changes = & $GitPath status --porcelain 2>$null
            $changeCount = if ($changes) { @($changes).Count } else { 0 }
            Write-Log "Heartbeat: $changeCount file(s) changed"
        }
    }
    catch {
        Write-Log "LOOP ERROR: $($_.Exception.Message)"
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
}