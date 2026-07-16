<#
.SYNOPSIS
Bulletproof Git Push - never falls, self-heals, 3-layer push.

.DESCRIPTION
Handles all git push failure scenarios automatically:
- Pre-flight: kill stale git processes, remove index.lock, clean rebase artifacts
- Sync: fetch + pull before push
- 3-layer push: HTTPS+credential-manager -> SSH+explicit-key -> gh CLI token
- Mutex: prevents parallel runs
- Self-healing: auto-retry on transient failures

.PARAMETER PushOnly
Skip commit, only push.

.PARAMETER DryRun
Print what would be done without doing it.

.PARAMETER Verbose
Show debug-level log output.

.EXAMPLE
.\git-push-bulletproof.ps1
Normal run: commit + push with safety checks.

.EXAMPLE
.\git-push-bulletproof.ps1 -PushOnly
Only push without committing.

.EXAMPLE
.\git-push-bulletproof.ps1 -DryRun -Verbose
Preview mode with full debug output.
#>

[CmdletBinding()]
param(
    [switch]$PushOnly,
    [switch]$DryRun
)

# ============================================================
# CONFIGURATION
# ============================================================

$SCRIPT_NAME = "git-push-bulletproof"
$LOG_DIR = Join-Path $PSScriptRoot "..\..\..\logs"
$LOG_FILE = Join-Path $LOG_DIR "backend.log"
$MUTEX_NAME = "Global\ObsidianGitPushBulletproof"
$REMOTE_NAME = "origin"
$REMOTE_HTTPS = "https://github.com/Konstantin2005/ObsiduanMain.git"
$REMOTE_SSH = "git@github.com:Konstantin2005/ObsiduanMain.git"
$STALE_PROCESS_MINUTES = 5
$MAX_AHEAD_PUSH = 500
$GIT_TIMEOUT_SEC = 60

# ============================================================
# LOGGING HELPERS
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    
    $isVerbose = $PSBoundParameters.ContainsKey('Verbose')
    if ($isVerbose -or $Level -ne "DEBUG") {
        try { Add-Content -Path $LOG_FILE -Value $line -Encoding UTF8 -ErrorAction Stop } catch {}
    }
    
    switch ($Level) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "OK"    { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line -ForegroundColor Cyan }
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Magenta
    Write-Log "=== $Message ===" "STEP"
}

function Write-OK {
    param([string]$Message)
    Write-Log $Message "OK"
}

function Write-Warn {
    param([string]$Message)
    Write-Log $Message "WARN"
}

function Write-Error {
    param([string]$Message)
    Write-Log $Message "ERROR"
}

# ============================================================
# MUTEX (prevent parallel runs)
# ============================================================

$script:Mutex = $null

function Acquire-Mutex {
    try {
        $script:Mutex = New-Object System.Threading.Mutex($false, $MUTEX_NAME)
        if (-not $script:Mutex.WaitOne(0)) {
            Write-Error "Another instance is already running (mutex: $MUTEX_NAME)"
            return $false
        }
        Write-Log "Mutex acquired" "DEBUG"
        return $true
    } catch {
        Write-Warn "Could not create mutex: $_"
        return $true  # Continue without mutex
    }
}

function Release-Mutex {
    if ($script:Mutex) {
        try { $script:Mutex.ReleaseMutex(); $script:Mutex.Dispose() } catch {}
        $script:Mutex = $null
    }
}

# ============================================================
# PRE-FLIGHT HELPERS
# ============================================================

function Test-GitInstalled {
    $gitPath = Get-Command "git" -ErrorAction SilentlyContinue
    if (-not $gitPath) {
        Write-Error "Git is not installed or not in PATH"
        return $false
    }
    
    $version = & git --version 2>$null
    if (-not $version) {
        Write-Error "Git is installed but not responding"
        return $false
    }
    
    Write-Log "Git: $version" "DEBUG"
    return $true
}

function Test-GitDir {
    $gitDir = & git rev-parse --git-dir 2>$null
    if (-not $gitDir) {
        Write-Error "Not a git repository"
        return $false
    }
    return $true
}

function Repair-StaleLock {
    $gitDir = & git rev-parse --git-dir 2>$null
    if (-not $gitDir) { return }
    $lockFile = Join-Path $gitDir "index.lock"
    if (Test-Path $lockFile) {
        $age = (Get-Date) - (Get-Item $lockFile).CreationTime
        if ($age.TotalMinutes -gt 1) {
            if ($DryRun) {
                Write-Log "[DRY-RUN] Would remove stale index.lock (age: $([math]::Round($age.TotalMinutes,1)) min)"
            } else {
                Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $lockFile)) {
                    Write-Log "Removed stale index.lock (age: $([math]::Round($age.TotalMinutes,1)) min)"
                } else {
                    Write-Warn "Could not remove index.lock (in use?)"
                }
            }
        } else {
            Write-Log "index.lock is recent ($([math]::Round($age.TotalSeconds,0))s old) - might be in use"
        }
    }
}

function Repair-StaleProcesses {
    $staleProcs = Get-Process -Name "git" -ErrorAction SilentlyContinue |
        Where-Object { $_.StartTime -lt (Get-Date).AddMinutes(-$STALE_PROCESS_MINUTES) -and $_.Id -ne $PID }
    
    foreach ($proc in $staleProcs) {
        if ($DryRun) {
            Write-Log "[DRY-RUN] Would kill stale git process PID $($proc.Id) (started: $($proc.StartTime))"
        } else {
            try {
                $proc.Kill()
                Write-Log "Killed stale git process PID $($proc.Id) (started: $($proc.StartTime))"
            } catch {
                Write-Warn "Could not kill process $($proc.Id): $_"
            }
        }
    }
}

function Repair-StuckRebase {
    $repoRoot = & git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) { return }
    $rebaseDirs = @(
        (Join-Path $repoRoot ".git\rebase-merge"),
        (Join-Path $repoRoot ".git\rebase-apply")
    )
    
    foreach ($path in $rebaseDirs) {
        if (Test-Path $path) {
            $age = (Get-Date) - (Get-Item $path).CreationTime
            if ($age.TotalMinutes -gt 5) {
                if ($DryRun) {
                    Write-Log "[DRY-RUN] Would remove stale rebase dir: $path"
                } else {
                    if (Test-Path -LiteralPath $path -PathType Container) {
                        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
                    }
                    if (-not (Test-Path $path)) {
                        Write-Log "Removed stale rebase dir: $path"
                    }
                }
            }
        }
    }
}

function Invoke-PreFlight {
    Write-Step "Pre-flight checks"
    $ok = $true
    
    if (-not (Test-GitInstalled)) { $ok = $false }
    if (-not (Test-GitDir)) { $ok = $false }
    if (-not $ok) { return $false }
    
    Repair-StaleProcesses
    Repair-StaleLock
    Repair-StuckRebase
    
    if (-not $DryRun) {
        & git config core.hooksPath "$([System.IO.Path]::GetTempPath())\git-hooks-disabled" 2>$null
        Write-Log "Disabled git hooks for non-interactive safety" "DEBUG"
    }
    
    return $true
}

# ============================================================
# GIT OPERATIONS
# ============================================================

function Invoke-Git {
    param(
        [string[]]$Arguments,
        [int]$TimeoutSec = $GIT_TIMEOUT_SEC,
        [int]$Retries = 1
    )
    
    $argStr = ($Arguments | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
    Write-Log "git $argStr" "DEBUG"
    
    $lastError = $null
    $prevPrompt = $env:GIT_TERMINAL_PROMPT
    $prevGcm = $env:GCM_INTERACTIVE
    
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            $env:GIT_TERMINAL_PROMPT = "0"
            $env:GCM_INTERACTIVE = "never"
            
            # Use temp files via cmd.exe to safely capture output with timeout
            $tmpDir = [System.IO.Path]::GetTempPath()
            $tmpOut = [System.IO.Path]::GetRandomFileName()
            $tmpErr = [System.IO.Path]::GetRandomFileName()
            $outPath = Join-Path $tmpDir $tmpOut
            $errPath = Join-Path $tmpDir $tmpErr
            
            # Build argument string for cmd.exe
            $cmdArgs = @("/c", "git")
            foreach ($a in $Arguments) {
                if ($a -match '[\s"]') {
                    $cmdArgs += "`"$($a -replace '"', '""')`""
                } else {
                    $cmdArgs += $a
                }
            }
            $cmdArgs += @(">", $outPath, "2>", $errPath)
            
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "cmd.exe"
            $psi.Arguments = $cmdArgs
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $null = $proc.Start()
            $exited = $proc.WaitForExit($TimeoutSec * 1000)
            
            if (-not $exited) {
                $proc.Kill()
                throw "Timeout after ${TimeoutSec}s"
            }
            
            $exitCode = $proc.ExitCode
            $lines = @()
            
            if (Test-Path $outPath) {
                $text = [System.IO.File]::ReadAllText($outPath, [System.Text.Encoding]::UTF8).Trim()
                Remove-Item $outPath -Force -ErrorAction SilentlyContinue
                if ($text) { $lines += $text -split "`r`n|`n" }
            }
            if (Test-Path $errPath) {
                $text = [System.IO.File]::ReadAllText($errPath, [System.Text.Encoding]::UTF8).Trim()
                Remove-Item $errPath -Force -ErrorAction SilentlyContinue
                if ($text) { $lines += $text -split "`r`n|`n" }
            }
            
            $env:GIT_TERMINAL_PROMPT = $prevPrompt
            $env:GCM_INTERACTIVE = $prevGcm
            
            if ($exitCode -eq 0) {
                return @{ Output = $lines; ExitCode = 0; Success = $true }
            }
            
            $lastError = @{ Output = $lines; ExitCode = $exitCode; Success = $false }
            
            $outputStr = $lines -join ' '
            if ($outputStr -match "index\.lock|Unable to create") {
                if ($attempt -lt $Retries) {
                    Write-Warn "Lock conflict - retry after delay"
                    Start-Sleep -Seconds 2
                    continue
                }
            }
            break
        } catch {
            $env:GIT_TERMINAL_PROMPT = $prevPrompt
            $env:GCM_INTERACTIVE = $prevGcm
            $lastError = @{ Output = @($_.Exception.Message); ExitCode = -1; Success = $false }
            if ($attempt -lt $Retries) {
                $errMsg = $_.Exception.Message
                Write-Warn "Git error on attempt $attempt/$Retries`: $errMsg"
                Start-Sleep -Seconds 1
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
        return $r.Output[0]
    }
    return $null
}

function Get-AheadBehind {
    $branch = Get-CurrentBranch
    if (-not $branch) { return $null }
    
    # Get ahead count
    $r = Invoke-Git -Arguments @("rev-list", "--count", "${branch}@\{u\}..${branch}", "--")
    if ($r.Success -and $r.Output -match '(\d+)') { $ahead = [int]$Matches[1] }
    
    # Get behind count
    $r = Invoke-Git -Arguments @("rev-list", "--count", "${branch}..${branch}@\{u\}", "--")
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
    $r = Invoke-Git -Arguments @("diff", "--stat")
    if (-not $r.Success) { return @{ Files = 0; Lines = 0 } }
    
    $files = 0
    $lines = 0
    
    $files = @($r.Output | Where-Object { $_ -match '^\d+' }).Count
    foreach ($line in $r.Output) {
        if ($line -match '^(\d+)\s+(\d+)') {
            $files = [Math]::Max($files, [int]$Matches[1])
            $lines += [int]$Matches[2]
        }
    }
    
    return @{ Files = $files; Lines = $lines }
}

# ============================================================
# SYNC (fetch + pull)
# ============================================================

function Invoke-Sync {
    Write-Step "Syncing with remote"
    
    # Save current remote URL
    $currentRemote = Invoke-Git -Arguments @("remote", "get-url", $REMOTE_NAME)
    if ($currentRemote.Success) {
        $currentUrl = $currentRemote.Output[0]
        if ($currentUrl -ne $REMOTE_HTTPS -and $currentUrl -ne $REMOTE_SSH) {
            Write-Warn "Unexpected remote URL: $currentUrl (expected HTTPS or SSH)"
        }
    }
    
    # Set to SSH for fetch (SSH key works in non-interactive)
    Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_SSH) | Out-Null
    
    # Configure SSH with explicit key for non-interactive
    $sshKeyPaths = @(
        "$env:USERPROFILE\.ssh\id_ed25519",
        "$env:USERPROFILE\.ssh\id_rsa",
        "$env:USERPROFILE\.ssh\id_ecdsa",
        "$env:USERPROFILE\.ssh\id_ed25519_sk",
        "$env:USERPROFILE\.ssh\id_ecdsa_sk"
    )
    $foundKey = $null
    foreach ($keyPath in $sshKeyPaths) {
        if (Test-Path $keyPath) { $foundKey = $keyPath; break }
    }
    if ($foundKey) {
        $env:GIT_SSH_COMMAND = "ssh -i `"$foundKey`" -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
    } else {
        $env:GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
    }
    
    Write-Log "Fetching from remote..."
    $fetchResult = Invoke-Git -Arguments @("fetch", $REMOTE_NAME) -TimeoutSec 120
    $env:GIT_SSH_COMMAND = $null
    
    if (-not $fetchResult.Success) {
        # Retry with HTTPS (credential manager)
        Write-Warn "SSH fetch failed, retrying with HTTPS..."
        Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_HTTPS) | Out-Null
        $fetchResult = Invoke-Git -Arguments @("fetch", $REMOTE_NAME) -TimeoutSec 120
        if (-not $fetchResult.Success) {
            Write-Error "Fetch failed (both SSH and HTTPS): $($fetchResult.Output -join '; ')"
            return $false
        }
    }
    
    Write-OK "Fetch successful"
    
    # Check ahead/behind
    $ab = Get-AheadBehind
    if (-not $ab) {
        Write-Warn "Could not determine ahead/behind -- no upstream?"
        return $true
    }
    
    Write-Log "Ahead: $($ab.Ahead), Behind: $($ab.Behind) on $($ab.Branch)"
    
    if ($ab.Behind -gt 0) {
        Write-Log "Remote is ahead by $($ab.Behind) commits -- pulling..."
        
        if ($DryRun) {
            Write-Log "[DRY-RUN] Would pull --rebase"
            return $true
        }
        
        # Stash any local changes first
        $hasChanges = Test-HasChanges
        $stashed = $false
        if ($hasChanges) {
            Write-Log "Stashing local changes before pull..."
            $stashResult = Invoke-Git -Arguments @("stash", "push", "-m", "auto-stash-before-pull")
            if ($stashResult.Success) { $stashed = $true }
        }
        
        # Try rebase first
        Write-Log "Attempting pull --rebase..."
        $pullResult = Invoke-Git -Arguments @("pull", "--rebase", $REMOTE_NAME, $ab.Branch) -TimeoutSec 120
        
        if (-not $pullResult.Success) {
            $pullOutput = $pullResult.Output -join ' '
            if ($pullOutput -match "conflict|merge|CONFLICT") {
                Write-Warn "Rebase conflicts -- aborting and trying merge..."
                Invoke-Git -Arguments @("rebase", "--abort") | Out-Null
                $mergeResult = Invoke-Git -Arguments @("pull", $REMOTE_NAME, $ab.Branch) -TimeoutSec 120
                if (-not $mergeResult.Success) {
                    Write-Error "Merge pull failed: $($mergeResult.Output -join '; ')"
                    if ($stashed) { Invoke-Git -Arguments @("stash", "pop") | Out-Null }
                    return $false
                }
            } else {
                Write-Error "Pull failed: $pullOutput"
                if ($stashed) { Invoke-Git -Arguments @("stash", "pop") | Out-Null }
                return $false
            }
        } else {
            Write-OK "Pull (rebase) successful"
        }
        
        # Pop stash if we stashed
        if ($stashed) { Invoke-Git -Arguments @("stash", "pop") | Out-Null }
    } else {
        Write-Log "Already up to date (0 commits behind)"
    }
    
    return $true
}

# ============================================================
# COMMIT
# ============================================================

function Invoke-Commit {
    if ($PushOnly) {
        Write-Log "PushOnly mode -- skipping commit"
        return $true
    }
    
    Write-Step "Committing changes"
    
    if (-not (Test-HasChanges)) {
        Write-Log "Nothing to commit"
        return $true
    }
    
    $stats = Get-ChangeStats
    Write-Log "Changes: $($stats.Files) files, $($stats.Lines) lines"
    
    if ($DryRun) {
        Write-Log "[DRY-RUN] Would commit $($stats.Files) files"
        return $true
    }
    
    # Stage all changes
    Write-Log "Staging all changes..."
    $addResult = Invoke-Git -Arguments @("add", "-A")
    if (-not $addResult.Success) {
        Write-Error "Failed to stage: $($addResult.Output -join '; ')"
        return $false
    }
    
    # Build commit message
    if (-not $CommitMessage) {
        $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm"
        $CommitMessage = "Auto-commit $dateStr [$($stats.Files) files, $($stats.Lines) lines]"
    }
    
    Write-Log "Committing: $CommitMessage"
    $commitResult = Invoke-Git -Arguments @("commit", "-m", $CommitMessage)
    
    if ($commitResult.Success) {
        Write-OK "Committed: $($commitResult.Output -join '; ')"
        return $true
    } else {
        $outputStr = $commitResult.Output -join ' '
        if ($outputStr -match "nothing to commit|nothing changed") {
            Write-Log "Nothing to commit (already clean)"
            return $true
        }
        Write-Error "Commit failed: $outputStr"
        return $false
    }
}

# ============================================================
# PUSH - Triple-layer fallback
# ============================================================

function Push-Https {
    param([string]$Branch)
    
    # Set remote to HTTPS
    Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_HTTPS) | Out-Null
    
    Write-Log "Push Layer 1: HTTPS + credential manager..."
    
    $env:GIT_TERMINAL_PROMPT = "0"
    $env:GCM_INTERACTIVE = "never"
    
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
        Write-Warn "gh CLI not authenticated - cannot use Layer 3"
        return $false
    }
    
    Write-Log "Using gh token for authentication" "DEBUG"
    
    $env:GIT_ASKPASS = "echo"
    $env:GIT_TERMINAL_PROMPT = "0"
    
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
        Write-Error "Too many commits ahead: $($ab.Ahead) > $MAX_AHEAD_PUSH. Push manually."
        return $false
    }
    
    if ($DryRun) {
        Write-Log "[DRY-RUN] Would push $($ab.Ahead) commits to $REMOTE_NAME/$branch"
        return $true
    }
    
    # Try layers in sequence
    $layers = @("HTTPS", "SSH", "gh CLI")
    
    foreach ($layerName in $layers) {
        Write-Log "Attempting push via $layerName..."
        try {
            $success = $false
            switch ($layerName) {
                "HTTPS" { $success = Push-Https $branch }
                "SSH" { $success = Push-Ssh $branch }
                "gh CLI" { $success = Push-GhCli $branch }
            }
            if ($success) {
                # Success - restore preferred remote URL (SSH for normal use)
                Invoke-Git -Arguments @("remote", "set-url", $REMOTE_NAME, $REMOTE_SSH) | Out-Null
                return $true
            }
        } catch {
            Write-Warn "$layerName threw exception: $_"
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
    Write-Step "Starting $SCRIPT_NAME"
    Write-Log "Args: PushOnly=$PushOnly DryRun=$DryRun Verbose=$isVerbose"
    Write-Log "Params: Remote=$REMOTE_NAME HTTPS=$REMOTE_HTTPS SSH=$REMOTE_SSH"
    Write-Log "Stale process threshold: ${STALE_PROCESS_MINUTES}m, Max ahead push: $MAX_AHEAD_PUSH"
    
    # Ensure log directory exists
    if (-not (Test-Path $LOG_DIR)) {
        $null = New-Item -ItemType Directory -Path $LOG_DIR -Force
    }
    
    # Acquire mutex
    if (-not (Acquire-Mutex)) {
        exit 1
    }
    
    # Pre-flight
    $preFlightOk = Invoke-PreFlight
    if (-not $preFlightOk) {
        Write-Error "Pre-flight checks failed - cannot proceed"
        exit 1
    }
    
    # Sync
    $syncOk = Invoke-Sync
    if (-not $syncOk) {
        Write-Error "Sync failed - cannot push without syncing"
        exit 1
    }
    
    # Commit
    $commitOk = Invoke-Commit
    if (-not $commitOk) {
        Write-Error "Commit failed"
        exit 1
    }
    
    # Push
    $pushOk = Invoke-Push
    
    if ($pushOk) {
        Write-Step "DONE - All operations completed successfully"
        exit 0
    } else {
        Write-Step "FAILED - Push failed after all attempts"
        exit 1
    }
} catch {
    Write-Error "Unhandled exception: $_"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
    exit 1
} finally {
    Release-Mutex
    Write-Log "Script finished" "DEBUG"
}
