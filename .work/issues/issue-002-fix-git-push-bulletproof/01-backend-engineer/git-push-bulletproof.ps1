<#
.SYNOPSIS
    Bulletproof Git Push — never falls, self-heals, 3-layer push.

.DESCRIPTION
    A comprehensive git push system designed for non-interactive environments
    (Task Scheduler, background jobs). Features:
    
    - Pre-flight self-healing (stale locks, stuck rebase, stale processes)
    - git fetch + pull --rebase before push (prevents rejection)
    - 3-layer push: HTTPS+token → SSH → gh CLI
    - Comprehensive logging
    - Idempotent (safe to run repeatedly)
    - Non-interactive by design

.PARAMETER RepoPath
    Path to the git repository. Default: C:\obsidian\Main

.PARAMETER CommitMessage
    Custom commit message. Default: "Auto-commit: <timestamp>"

.PARAMETER PushOnly
    Skip commit, only push existing commits.

.PARAMETER DryRun
    Show what would be done without making changes.

.EXAMPLE
    .\git-push-bulletproof.ps1
    .\git-push-bulletproof.ps1 -PushOnly
    .\git-push-bulletproof.ps1 -DryRun -Verbose
#>

param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$CommitMessage = "",
    [switch]$PushOnly,
    [switch]$DryRun,
    [switch]$Verbose
)

# ============================================================
# CONFIGURATION
# ============================================================
$REMOTE_NAME = "origin"
$REMOTE_BRANCH = "main"
$REMOTE_HTTPS = "https://github.com/Konstantin2005/ObsiduanMain.git"
$REMOTE_SSH = "git@github.com:Konstantin2005/ObsiduanMain.git"
$LOG_DIR = "C:\obsidian\Main\Technical\Scripts\Logs"
$LOG_FILE = "$LOG_DIR\git-push-bulletproof.log"
$SCRIPT_NAME = "git-push-bulletproof.ps1"
$MAX_RETRIES = 3
$RETRY_DELAY_MS = 2000
$STALE_PROCESS_MINUTES = 5
$MAX_AHEAD_PUSH = 100

# ============================================================
# LOGGING
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $line = "[$timestamp] [$Level] [$SCRIPT_NAME] $Message"
    Write-Host $line
    if ($Verbose -or $Level -ne "DEBUG") {
        try { Add-Content -Path $LOG_FILE -Value $line -Encoding UTF8 -ErrorAction Stop } catch {}
    }
}

function Write-Step {
    param([string]$Message)
    Write-Log ">>> $Message" "STEP"
}

function Write-OK {
    param([string]$Message)
    Write-Log "OK $Message" "OK"
}

function Write-Warn {
    param([string]$Message)
    Write-Log "$Message" "WARN"
}

function Write-Error {
    param([string]$Message)
    Write-Log "$Message" "ERROR"
}

# ============================================================
# MUTEX (prevent concurrent runs)
# ============================================================

$MUTEX_NAME = "Global\ObsidianGitPushBulletproof"
$script:Mutex = $null

function Acquire-Mutex {
    try {
        $script:Mutex = New-Object System.Threading.Mutex($false, $MUTEX_NAME)
        if (-not $script:Mutex.WaitOne(0)) {
            Write-Warn "Another instance is already running. Exiting."
            exit 0
        }
        return $true
    } catch {
        Write-Warn "Mutex acquisition failed (non-critical): $_"
        return $false
    }
}

function Release-Mutex {
    if ($script:Mutex) {
        try { $script:Mutex.ReleaseMutex(); $script:Mutex.Dispose() } catch {}
    }
}

# ============================================================
# SELF-HEALING — Pre-flight checks
# ============================================================

function Test-GitInstalled {
    $gitPath = Get-Command "git" -ErrorAction SilentlyContinue
    if (-not $gitPath) {
        Write-Error "Git is not installed or not in PATH"
        return $false
    }
    $version = & git --version 2>&1
    if (-not $version) {
        Write-Error "Git binary found but fails to run"
        return $false
    }
    Write-OK "Git: $version"
    return $true
}

function Test-GitDir {
    $gitDir = Join-Path $RepoPath ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Error ".git directory not found at $gitDir"
        return $false
    }
    return $true
}

function Repair-StaleLock {
    $lockFile = Join-Path $RepoPath ".git" "index.lock"
    if (Test-Path $lockFile) {
        $age = (Get-Date) - (Get-Item $lockFile).CreationTime
        if ($age.TotalMinutes -gt 1) {
            if ($DryRun) {
                Write-Log "[DRY-RUN] Would remove stale index.lock ($([math]::Round($age.TotalMinutes,1)) min old)"
            } else {
                Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $lockFile)) {
                    Write-OK "Removed stale index.lock ($([math]::Round($age.TotalMinutes,1)) min old)"
                } else {
                    Write-Error "Failed to remove index.lock"
                }
            }
        } else {
            Write-Warn "index.lock is recent ($([math]::Round($age.TotalSeconds,0))s old) — might be in use"
        }
    }
}

function Repair-StaleProcesses {
    $staleProcs = Get-Process -Name "git" -ErrorAction SilentlyContinue | 
        Where-Object { $_.StartTime -lt (Get-Date).AddMinutes(-$STALE_PROCESS_MINUTES) -and $_.Id -ne $PID }
    foreach ($proc in $staleProcs) {
        if ($DryRun) {
            Write-Log "[DRY-RUN] Would kill stale git process PID $($proc.Id) (running since $($proc.StartTime))"
        } else {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-OK "Killed stale git process PID $($proc.Id)"
            } catch {
                Write-Warn "Could not kill git PID $($proc.Id): $_"
            }
        }
    }
}

function Repair-StuckRebase {
    $rebaseDirs = @(
        Join-Path $RepoPath ".git" "rebase-merge",
        Join-Path $RepoPath ".git" "rebase-apply",
        Join-Path $RepoPath ".git" "CHERRY_PICK_HEAD",
        Join-Path $RepoPath ".git" "MERGE_HEAD"
    )
    foreach ($path in $rebaseDirs) {
        if (Test-Path $path) {
            if ($DryRun) {
                Write-Log "[DRY-RUN] Would remove stuck state: $path"
            } else {
                if (Test-Path -LiteralPath $path -PathType Container) {
                    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
                }
                if (-not (Test-Path $path)) {
                    Write-OK "Removed stuck state: $path"
                }
            }
        }
    }
}

function Invoke-PreFlight {
    Write-Step "Pre-flight self-healing"
    
    $ok = $true
    if (-not (Test-GitInstalled)) { $ok = $false }
    if (-not (Test-GitDir)) { $ok = $false }
    if (-not $ok) { return $false }
    
    Repair-StaleLock
    Repair-StaleProcesses
    Repair-StuckRebase
    
    # Configure git for non-interactive use
    if (-not $DryRun) {
        $env:GIT_TERMINAL_PROMPT = "0"
        $env:GIT_ASKPASS = "echo"
        $env:GCM_INTERACTIVE = "never"
    }
    
    return $true
}

# ============================================================
# GIT OPERATIONS
# ============================================================

function Invoke-Git {
    param(
        [string[]]$Arguments,
        [int]$Retries = $MAX_RETRIES,
        [int]$TimeoutSec = 120
    )
    
    $lastError = $null
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            $output = & "git" -C $RepoPath @Arguments 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return @{ Output = $output; ExitCode = 0; Success = $true }
            }
            
            $outputStr = "$output"
            $lastError = @{ Output = $output; ExitCode = $exitCode; Success = $false }
            
            # Lock conflict — retry after delay
            if ($outputStr -match "index\.lock|Unable to create") {
                if ($attempt -lt $Retries) {
                    Write-Warn "Lock conflict (attempt $attempt/$Retries), retrying in ${RETRY_DELAY_MS}ms..."
                    Start-Sleep -Milliseconds $RETRY_DELAY_MS
                    continue
                }
            }
            
            # Other errors — break immediately
            break
        } catch {
            $lastError = @{ Output = @($_.Exception.Message); ExitCode = -1; Success = $false }
            if ($attempt -lt $Retries) {
                Start-Sleep -Milliseconds $RETRY_DELAY_MS
                continue
            }
            break
        }
    }
    
    return $lastError
}

function Get-CurrentBranch {
    $r = Invoke-Git -Arguments @("rev-parse", "--abbrev-ref", "HEAD")
    if ($r.Success -and $r.Output) {
        return ($r.Output -join '').Trim()
    }
    return $null
}

function Get-AheadBehind {
    $branch = Get-CurrentBranch
    if (-not $branch) { return $null }
    
    $r = Invoke-Git -Arguments @("rev-list", "--count", "${REMOTE_NAME}/${branch}..${branch}")
    $ahead = 0
    if ($r.Success -and $r.Output -match '(\d+)') { $ahead = [int]$Matches[1] }
    
    $r = Invoke-Git -Arguments @("rev-list", "--count", "${branch}..${REMOTE_NAME}/${branch}")
    $behind = 0
    if ($r.Success -and $r.Output -match '(\d+)') { $behind = [int]$Matches[1] }
    
    return @{ Ahead = $ahead; Behind = $behind; Branch = $branch }
}

function Test-HasChanges {
    $r = Invoke-Git -Arguments @("status", "--porcelain")
    if ($r.Success -and ($r.Output -join '') -ne '') {
        return $true
    }
    return $false
}

function Get-ChangeStats {
    $r = Invoke-Git -Arguments @("diff", "--numstat")
    if (-not $r.Success) { return @{ Files = 0; Lines = 0 } }
    
    $files = @($r.Output | Where-Object { $_ -match '^\d+' }).Count
    $lines = 0
    foreach ($line in $r.Output) {
        if ($line -match '^(\d+)\s+(\d+)') {
            $lines += [int]$Matches[1] + [int]$Matches[2]
        }
    }
    return @{ Files = $files; Lines = $lines }
}

# ============================================================
# SYNC — Fetch and pull before push
# ============================================================

function Invoke-Sync {
    Write-Step "Syncing with remote"
    
    # Ensure correct remote URL (HTTPS for reliable auth)
    $currentRemote = Invoke-Git -Arguments @("remote", "get-url", $REMOTE_NAME)
    if ($currentRemote.Success) {
        $currentUrl = ($currentRemote.Output -join '').Trim()
        if ($currentUrl -ne $REMOTE_HTTPS -and $currentUrl -ne $REMOTE_SSH) {
            Write-Warn "Unknown remote URL: $currentUrl"
        }
    }
    
    # Fetch with retry
    $fetchResult = Invoke-Git -Arguments @("fetch", $REMOTE_NAME) -TimeoutSec 60
    if (-not $fetchResult.Success) {
        Write-Warn "Fetch failed: $($fetchResult.Output -join '; ')"
        Write-Log "Continuing with local data only..."
    } else {
        Write-OK "Fetch completed"
    }
    
    # Check ahead/behind
    $ab = Get-AheadBehind
    if (-not $ab) {
        Write-Warn "Could not determine ahead/behind — no upstream?"
        return $true
    }
    
    Write-Log "Branch status: $($ab.Ahead) ahead, $($ab.Behind) behind"
    
    # If behind, pull --rebase
    if ($ab.Behind -gt 0) {
        Write-Log "Remote is ahead by $($ab.Behind) commits. Pulling with rebase..."
        
        if ($DryRun) {
            Write-Log "[DRY-RUN] Would pull --rebase"
            return $true
        }
        
        # Stash any local changes first
        $hasChanges = Test-HasChanges
        $stashed = $false
        if ($hasChanges) {
            $stashResult = Invoke-Git -Arguments @("stash")
            if ($stashResult.Success) { $stashed = $true }
        }
        
        # Try pull --rebase
        $pullResult = Invoke-Git -Arguments @("pull", "--rebase", $REMOTE_NAME, $ab.Branch) -TimeoutSec 60
        if (-not $pullResult.Success) {
            $pullOutput = $pullResult.Output -join '; '
            Write-Error "Pull --rebase failed: $pullOutput"
            
            # If rebase fails, try merge instead
            if ($pullOutput -match "conflict|merge|CONFLICT") {
                Write-Warn "Rebase conflicts detected. Aborting rebase and trying merge..."
                Invoke-Git -Arguments @("rebase", "--abort") | Out-Null
                $mergeResult = Invoke-Git -Arguments @("pull", "--no-rebase", $REMOTE_NAME, $ab.Branch) -TimeoutSec 60
                if (-not $mergeResult.Success) {
                    Write-Error "Merge pull also failed. Manual intervention needed."
                    # Restore stashed changes
                    if ($stashed) { Invoke-Git -Arguments @("stash", "pop") | Out-Null }
                    return $false
                }
                Write-OK "Pull (merge) completed"
            } else {
                if ($stashed) { Invoke-Git -Arguments @("stash", "pop") | Out-Null }
                return $false
            }
        } else {
            Write-OK "Pull (rebase) completed"
        }
        
        # Restore stashed changes
        if ($stashed) { Invoke-Git -Arguments @("stash", "pop") | Out-Null }
    } else {
        Write-OK "Already up to date with remote"
    }
    
    return $true
}

# ============================================================
# COMMIT
# ============================================================

function Invoke-Commit {
    if ($PushOnly) {
        Write-Log "PushOnly mode — skipping commit"
        return $true
    }
    
    Write-Step "Checking for changes to commit"
    
    if (-not (Test-HasChanges)) {
        Write-Log "No changes to commit (clean worktree)"
        return $true
    }
    
    $stats = Get-ChangeStats
    Write-Log "Changes detected: $($stats.Files) files, $($stats.Lines) lines"
    
    if ($DryRun) {
        Write-Log "[DRY-RUN] Would add and commit changes"
        return $true
    }
    
    # Stage all changes
    $addResult = Invoke-Git -Arguments @("add", "-A")
    if (-not $addResult.Success) {
        Write-Error "git add failed: $($addResult.Output -join '; ')"
        return $false
    }
    Write-OK "Staged all changes"
    
    # Commit
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if (-not $CommitMessage) {
        $CommitMessage = "Auto-commit: $date"
    }
    
    $commitResult = Invoke-Git -Arguments @("commit", "-m", $CommitMessage, "--no-gpg-sign")
    if ($commitResult.Success) {
        Write-OK "Commit successful: $CommitMessage"
        return $true
    } else {
        $outputStr = $commitResult.Output -join ' '
        if ($outputStr -match "nothing to commit|nothing changed") {
            Write-Log "Nothing to commit (clean after add)"
            return $true
        }
        Write-Error "Commit failed: $outputStr"
        return $false
    }
}

# ============================================================
# PUSH — Triple-layer fallback
# ============================================================

function Push-Https {
    param([string]$Branch)
    
    # Set remote to HTTPS
    Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_HTTPS) | Out-Null
    
    Write-Log "Push Layer 1: HTTPS + credential manager..."
    
    $env:GIT_TERMINAL_PROMPT = "0"
    $env:GCM_INTERACTIVE = "never"
    
    # Store gh token in credential store if available
    $ghToken = & gh auth token 2>$null
    if ($ghToken) {
        $credentialData = "protocol=https`nhost=github.com`nusername=token`npassword=$ghToken"
        try {
            $credentialData | git credential-store store 2>$null
            Write-Log "Stored gh token in credential store" "DEBUG"
        } catch {}
    }
    
    $result = Invoke-Git -Arguments @("push", $REMOTE_NAME, $Branch) -TimeoutSec 120
    
    if ($result.Success) {
        Write-OK "Push via HTTPS successful"
        return $true
    }
    
    $outputStr = $result.Output -join '; '
    Write-Warn "HTTPS push failed: $outputStr"
    return $false
}

function Push-Ssh {
    param([string]$Branch)
    
    # Set remote to SSH
    Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_SSH) | Out-Null
    
    Write-Log "Push Layer 2: SSH with explicit identity..."
    
    # Find an SSH key
    $sshKeyPaths = @(
        "$env:USERPROFILE\.ssh\id_ed25519",
        "$env:USERPROFILE\.ssh\id_rsa",
        "$env:USERPROFILE\.ssh\id_ecdsa",
        "$env:USERPROFILE\.ssh\id_ed25519_sk",
        "$env:USERPROFILE\.ssh\id_ecdsa_sk"
    )
    
    $foundKey = $null
    foreach ($keyPath in $sshKeyPaths) {
        if (Test-Path $keyPath) {
            $foundKey = $keyPath
            break
        }
    }
    
    if ($foundKey) {
        Write-Log "Using SSH key: $foundKey" "DEBUG"
        $env:GIT_SSH_COMMAND = "ssh -i `"$foundKey`" -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
    } else {
        Write-Log "No SSH key found, using default SSH" "DEBUG"
        $env:GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
    }
    
    $env:GIT_TERMINAL_PROMPT = "0"
    
    $result = Invoke-Git -Arguments @("push", $REMOTE_NAME, $Branch) -TimeoutSec 120
    
    # Clean up GIT_SSH_COMMAND
    $env:GIT_SSH_COMMAND = $null
    
    if ($result.Success) {
        Write-OK "Push via SSH successful"
        return $true
    }
    
    Write-Warn "SSH push failed: $($result.Output -join '; ')"
    return $false
}

function Push-GhCli {
    param([string]$Branch)
    
    Write-Log "Push Layer 3: gh CLI token..."
    
    # Set remote to HTTPS (gh token works with HTTPS)
    Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_HTTPS) | Out-Null
    
    # Get gh token
    $ghToken = & gh auth token 2>$null
    if (-not $ghToken) {
        Write-Warn "gh CLI not authenticated — cannot use Layer 3"
        return $false
    }
    
    Write-Log "Using gh token for authentication" "DEBUG"
    
    # gh can't do push directly, but we can use the token with git
    # The token is already in credential.helper=manager or credential-store
    # Try pushing with token as password
    $env:GIT_ASKPASS = "echo"
    $env:GIT_TERMINAL_PROMPT = "0"
    
    # Alternative: use GIT_PASSWORD with the token
    $credString = "protocol=https`nhost=github.com`nusername=token`npassword=$ghToken`n"
    try {
        $credString | git credential-store store 2>$null
    } catch {}
    
    # Wait a moment for credential store to update
    Start-Sleep -Milliseconds 500
    
    $result = Invoke-Git -Arguments @("push", $REMOTE_NAME, $Branch) -TimeoutSec 120
    
    if ($result.Success) {
        Write-OK "Push via gh token successful"
        return $true
    }
    
    Write-Warn "gh token push failed: $($result.Output -join '; ')"
    return $false
}

function Invoke-Push {
    Write-Step "Pushing to remote"
    
    $branch = Get-CurrentBranch
    if (-not $branch) {
        Write-Error "Cannot determine current branch"
        return $false
    }
    
    Write-Log "Current branch: $branch"
    
    # Check ahead count
    $ab = Get-AheadBehind
    if ($ab -and $ab.Ahead -eq 0) {
        Write-Log "Nothing to push - 0 commits ahead"
        return $true
    }
    
    if ($ab -and $ab.Ahead -gt $MAX_AHEAD_PUSH) {
        Write-Error "Too many commits ahead ($($ab.Ahead) > $MAX_AHEAD_PUSH). Push manually."
        return $false
    }
    
    if ($DryRun) {
        Write-Log "[DRY-RUN] Would push $($ab.Ahead) commits to $REMOTE_NAME/$branch"
        return $true
    }
    
    # Try layers in sequence
    $pushLayers = @(
        @{ Name = "HTTPS"; Function = ${function:Push-Https} },
        @{ Name = "SSH"; Function = ${function:Push-Ssh} },
        @{ Name = "gh CLI"; Function = ${function:Push-GhCli} }
    )
    
    foreach ($layer in $pushLayers) {
        Write-Log "Attempting push via $($layer.Name)..."
        try {
            if (& $layer.Function $branch) {
                # Success — restore preferred remote URL (SSH for normal use)
                Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_SSH) | Out-Null
                return $true
            }
        } catch {
            Write-Warn "$($layer.Name) threw exception: $_"
        }
    }
    
    # All layers failed
    Write-Error "ALL push layers FAILED"
    Write-Log "Check: github auth status, SSH keys, gh CLI auth"
    Write-Log "Run: gh auth status"
    Write-Log "Run: ssh -T git@github.com"
    
    # Restore SSH remote as default
    Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_SSH) | Out-Null
    
    return $false
}

# ============================================================
# MAIN
# ============================================================

try {
    # Ensure log directory exists
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
    
    Write-Log "=== START ==="
    Write-Log "Repo: $RepoPath"
    Write-Log "Mode: $(if ($DryRun) { 'DRY-RUN' } else { 'LIVE' })"
    if ($PushOnly) { Write-Log "PushOnly mode (no commit)" }
    
    # Acquire mutex
    Acquire-Mutex
    
    # Step 1: Pre-flight
    $preFlightOk = Invoke-PreFlight
    if (-not $preFlightOk) {
        Write-Error "Pre-flight checks failed. Cannot continue."
        Release-Mutex
        exit 1
    }
    
    # Step 2: Sync
    $syncOk = Invoke-Sync
    if (-not $syncOk) {
        Write-Warn "Sync failed, attempting push anyway..."
    }
    
    # Step 3: Commit
    $commitOk = Invoke-Commit
    if (-not $commitOk) {
        Write-Error "Commit failed. Aborting."
        Release-Mutex
        exit 1
    }
    
    # Step 4: Push
    $pushOk = Invoke-Push
    
    # Final status
    Write-Step "COMPLETE"
    if ($pushOk) {
        Write-OK "All operations completed successfully"
        Release-Mutex
        exit 0
    } else {
        Write-Error "Push failed after all retries. Changes committed locally."
        Write-Log "Run manually: git push origin $(Get-CurrentBranch)"
        Release-Mutex
        exit 2
    }
    
} catch {
    Write-Error "UNHANDLED EXCEPTION: $_"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    Release-Mutex
    exit 3
}
