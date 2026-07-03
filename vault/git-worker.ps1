<#
.SYNOPSIS
    Unified Git worker: commit, push, and self-monitor.
    Replaces: auto-commit.ps1, daily-push.ps1, monitor-daily-push.ps1, threshold-git.ps1

.MODE
    commit   - One-shot: check changes, commit+push if above threshold. (Task Scheduler)
    watch    - Continuous: commit loop + periodic push. (Long-running background process)
    monitor  - Watchdog: checks watch process is alive, restarts if not. (Task Scheduler on startup)
    setup    - Register (or remove) tasks in Windows Task Scheduler.

.EXAMPLE
    .\vault\git-worker.ps1 -Mode commit
    .\vault\git-worker.ps1 -Mode watch -PushIntervalMinutes 30
    .\vault\git-worker.ps1 -Mode monitor
    .\vault\git-worker.ps1 -Mode setup
    .\vault\git-worker.ps1 -Mode setup -Remove
#>

param(
    [ValidateSet("commit", "watch", "monitor", "setup")]
    [string]$Mode = "commit",

    [string]$RepoPath = "",
    [string]$Branch = "",

    [int]$ThresholdFiles = 0,
    [int]$ThresholdLines = 0,
    [int]$PushIntervalMinutes = 60,
    [int]$WatchIntervalSeconds = 30,
    [int]$MonitorCheckSeconds = 15,

    [switch]$DryRun,
    [switch]$Remove
)

# ====== HIDE TERMINAL WINDOW ======
$Async = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -MemberDefinition $Async -Name "Win32ShowWindow" -Namespace Win32 -PassThru
$Type::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0) | Out-Null

# ====== SILENT GIT ENV ======
$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = "echo"
$env:GCM_INTERACTIVE = "never"

# ====== DUMB-USER BOOTSTRAP ======
# Protection 1: Check git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "FATAL: Git is not installed. Install git from https://git-scm.com/"
    exit 99
}
# Protection 2: Determine paths
$VaultScriptDir = Split-Path -Parent $PSScriptRoot
$VaultRoot = Split-Path -Parent $VaultScriptDir
if (-not $RepoPath) { $RepoPath = Split-Path -Parent $VaultRoot }
$ScriptName = "git-worker.ps1"
$VaultDir = $VaultRoot
$StartTime = Get-Date
# Protection 3: Ensure .git exists (dumb user might delete it)
$gitDir = Join-Path $VaultDir ".git"
if (-not (Test-Path $gitDir)) {
    Write-Host "[BOOTSTRAP] .git missing! Attempting recovery..."
    $remoteUrl = "git@github.com:Konstantin2005/ObsiduanMain.git"
    & git -C $VaultDir init 2>$null
    if ($LASTEXITCODE -eq 0) {
        & git -C $VaultDir remote add origin $remoteUrl 2>$null
        & git -C $VaultDir config user.name "Git Worker Bot" 2>$null
        & git -C $VaultDir config user.email "gitworker@obsidian.vault" 2>$null
        & git -C $VaultDir fetch origin 2>$null
        $remoteMain = & git -C $VaultDir rev-parse origin/main 2>$null
        if ($remoteMain) {
            & git -C $VaultDir reset --hard origin/main 2>$null
            & git -C $VaultDir branch --set-upstream-to=origin/main main 2>$null
        } else {
            & git -C $VaultDir add -A 2>$null
            & git -C $VaultDir commit -m "chore: recovery after .git deletion" 2>$null
            & git -C $VaultDir branch -M main 2>$null
            & git -C $VaultDir config --local branch.main.remote origin 2>$null
            & git -C $VaultDir config --local branch.main.merge refs/heads/main 2>$null
        }
        Write-Host "[BOOTSTRAP] .git recovered"
    } else {
        Write-Host "[BOOTSTRAP] FATAL: Cannot reinitialize git"
        exit 98
    }
}
# Protection 4: Simple mutex
$mutexName = "Global\ObsidianGitWorker-$([System.Environment]::UserName)"
try {
    $script:Mutex = New-Object System.Threading.Mutex($false, $mutexName)
    if (-not $script:Mutex.WaitOne(0)) {
        Write-Host "[BOOTSTRAP] Another git-worker instance is running. Exiting."
        exit 0
    }
} catch {}

# ====== SETUP ======

$VaultLogDir = Join-Path (Join-Path $VaultDir "vault") "log"
$ScriptLogDir = Join-Path $VaultLogDir "script"
$HistoryLog = Join-Path $VaultLogDir "script-history.md"
$ActivityLog = Join-Path $VaultLogDir "activity.md"
$ScriptLog = Join-Path $ScriptLogDir "$ScriptName.log"
$LockDir = Join-Path $VaultDir "Technical\Scripts\Logs"
$WatchLockFile = Join-Path $LockDir ".git-worker.watch.lock"
$MonitorLockFile = Join-Path $LockDir ".git-worker.monitor.lock"
$WatchPidFile = Join-Path $LockDir ".git-worker.watch.pid"

foreach ($dir in @($VaultLogDir, $ScriptLogDir, $LockDir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$GitPath = "git"
Set-Location $RepoPath

# ====== LOGGING ======

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -LiteralPath $ScriptLog -Value $line

    if ($Mode -eq "commit") {
        $branch = Get-CurrentBranch
        $dur = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)
        $histLine = "| $timestamp | $ScriptName($Mode) | $branch | 0 | ${dur}s | $Message |"
        Add-Content $HistoryLog $histLine
    }

    if (Test-Path $ActivityLog) {
        Add-Content $ActivityLog "- [$ScriptName($Mode)] $Message"
    }
}

function Write-ErrorLog {
    param([string]$Message)
    Write-Log -Message $Message -Level "ERROR"
}

function Write-Exit {
    param([int]$ExitCode = 0, [string]$Message = "Done")
    if ($ExitCode -eq 0) {
        Write-Log $Message
    } else {
        Write-ErrorLog $Message
    }
    $lockFiles = @($WatchLockFile, $MonitorLockFile)
    foreach ($lf in $lockFiles) {
        if (Test-Path $lf) {
            $lockPid = Get-Content $lf -ErrorAction SilentlyContinue
            if ($lockPid -eq $PID) {
                Remove-Item $lf -Force -ErrorAction SilentlyContinue
            }
        }
    }
    exit $ExitCode
}

# ====== GIT HELPERS ======

function Get-CurrentBranch {
    $b = & $GitPath rev-parse --abbrev-ref HEAD 2>$null
    if (-not $b) { $b = "unknown" }
    return $b
}

function Invoke-Git {
    param(
        [Parameter(Mandatory=$true)][string[]]$Args,
        [int]$MaxRetries = 3,
        [int]$RetryDelayMs = 2000
    )
    $lastError = $null
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        $output = & $GitPath @Args 2>&1
        $code = $LASTEXITCODE
        $textOutput = @()
        if ($output) {
            $output | ForEach-Object {
                $line = $_
                if ($line -is [System.Management.Automation.ErrorRecord]) {
                    $line = $line.Exception.Message
                }
                $textOutput += $line
            }
        }
        # ???????? ?????????????? ?????? ???? lock-???????????? ??? ??????????????
        if ($code -eq 0 -or ($textOutput -join ' ') -notmatch 'index\.lock|Unable to create') {
            return @{ Output = $textOutput; ExitCode = $code }
        }
        $lastError = @{ Output = $textOutput; ExitCode = $code }
        if ($attempt -lt $MaxRetries) {
            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }
    return $lastError
}

function Test-HasChanges {
    $r = Invoke-Git -Args @('status', '--porcelain')
    return ($r.Output -join '') -ne ''
}

function Get-ChangeStats {
    $files = (& $GitPath diff --name-only 2>$null) -split "`n" | Where-Object { $_ -ne '' }
    $fileCount = @($files).Count
    $lineCount = 0
    $numstat = & $GitPath diff --numstat 2>$null
    foreach ($line in $numstat) {
        $parts = $line -split "`t"
        if ($parts.Count -ge 2) {
            $added = 0; $removed = 0
            [int]::TryParse($parts[0], [ref]$added) | Out-Null
            [int]::TryParse($parts[1], [ref]$removed) | Out-Null
            $lineCount += $added + $removed
        }
    }
    return @{ Files = $fileCount; Lines = $lineCount }
}

function Ensure-Branch {
    if (-not $Branch) { return }
    $current = Get-CurrentBranch
    if ($current -ne $Branch) {
        Write-Log "Switching branch: $current -> $Branch"
        $r = Invoke-Git -Args @('checkout', $Branch)
        if ($r.ExitCode -ne 0) {
            Write-ErrorLog "Failed to switch to branch ${Branch}: $($r.Output -join '; ')"
        }
    }
}

# ====== CORE OPERATIONS ======

function Invoke-Commit {
    try {
        Ensure-Branch
        if (-not (Test-HasChanges)) {
            Write-Log "No changes to commit (clean tree)"
            return $false
        }

        if ($ThresholdFiles -gt 0 -or $ThresholdLines -gt 0) {
            $stats = Get-ChangeStats
            if ($stats.Files -lt $ThresholdFiles -and $stats.Lines -lt $ThresholdLines) {
                Write-Log "Threshold not met: $($stats.Files) files, $($stats.Lines) lines (need $ThresholdFiles files or $ThresholdLines lines)"
                return $false
            }
            Write-Log "Changes: $($stats.Files) files, $($stats.Lines) lines (threshold OK)"
        }

        if ($DryRun) {
            Write-Log "[DRY-RUN] Would commit changes"
            return $false
        }

        $r = Invoke-Git -Args @('add', '-A')
        if ($r.ExitCode -ne 0) {
            Write-ErrorLog "git add failed: $($r.Output -join '; ')"
            return $false
        }

        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $msg = "Auto-commit: $date"
        $r = Invoke-Git -Args @('commit', '-m', $msg, '--no-gpg-sign')
        foreach ($line in $r.Output) {
            Write-Log "[git] $line"
        }

        if ($r.ExitCode -eq 0) {
            Write-Log "Commit completed: $msg"
            return $true
        } else {
            Write-Log "Nothing to commit (clean tree after add)"
            return $false
        }
    } catch {
        Write-ErrorLog "Invoke-Commit error: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-Push {
    try {
        $branch = Get-CurrentBranch
        if (-not $branch -or $branch -eq 'unknown') {
            Write-ErrorLog "Cannot push: unknown branch"
            return $false
        }

        if ($DryRun) {
            Write-Log "[DRY-RUN] Would push to origin/$branch"
            return $true
        }

        # Check how many commits ahead (avoid long push with 1000+ commits)
        $ahead = & $GitPath rev-list --count "origin/$branch..HEAD" 2>$null
        if (-not $ahead -or $ahead -eq 0) {
            Write-Log "Already up to date with origin/$branch"
            return $true
        }

        if ($ahead -gt 100) {
            Write-Log "$ahead commits ahead ??? skipping push (too many, push manually or use --force)"
            return $false
        }

        Write-Log "Pushing $ahead commit(s) to origin/$branch ..."

        # Simple push ??? fetch + pull + rebase ???????????????? ???????????? ?????????????? ?????? ???????????? ?????? ????????-?????????????????????????????????? ??????????????????
        $r = Invoke-Git -Args @('push', 'origin', $branch)
        foreach ($line in $r.Output) {
            Write-Log "[git] $line"
        }
        if ($r.ExitCode -eq 0) {
            Write-Log "Push completed successfully"
            return $true
        } else {
            Write-ErrorLog "push failed with code $($r.ExitCode): $($r.Output -join '; ')"
            return $false
        }
    } catch {
        Write-ErrorLog "Invoke-Push error: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-CommitAndPush {
    $committed = Invoke-Commit
    if ($committed) {
        Start-Sleep -Seconds 2
        Invoke-Push | Out-Null
    }
    return $committed
}

# ====== MODE: COMMIT (one-shot) ======

function Mode-Commit {
    Write-Log "Mode: commit (one-shot)"

    if (-not (Test-HasChanges)) {
        Write-Log "Nothing to commit. Exiting."
        return
    }

    $stats = Get-ChangeStats
    Write-Log "Found $($stats.Files) files changed ($($stats.Lines) lines)"

    if ($ThresholdFiles -gt 0 -or $ThresholdLines -gt 0) {
        if ($stats.Files -lt $ThresholdFiles -and $stats.Lines -lt $ThresholdLines) {
            Write-Log "Below threshold ($ThresholdFiles files / $ThresholdLines lines). Skipping commit."
            return
        }
    }

    Invoke-CommitAndPush
    Write-Log "Commit mode finished"
}

# ====== MODE: WATCH (continuous) ======

function Mode-Watch {
    Write-Log "Mode: watch (continuous)"
    Write-Log "Commit interval: ${WatchIntervalSeconds}s, Push interval: ${PushIntervalMinutes}m"

    $PID | Out-File $WatchPidFile -Force

    $lastPush = [DateTime]::MinValue
    $pushInterval = New-TimeSpan -Minutes $PushIntervalMinutes
    $firstRun = $true

    while ($true) {
        try {
            $now = Get-Date
            Invoke-Commit | Out-Null

            $shouldPush = $false
            if ($firstRun -and (Test-HasChanges)) {
                $shouldPush = $true
            } elseif ($now - $lastPush -ge $pushInterval) {
                $shouldPush = $true
            }

            if ($shouldPush) {
                if (Invoke-Push) {
                    $lastPush = $now
                }
                $firstRun = $false
            }
        } catch {
            Write-ErrorLog "Watch loop error: $($_.Exception.Message)"
        }

        Start-Sleep -Seconds $WatchIntervalSeconds
    }
}

# ====== MODE: MONITOR (watchdog) ======

function Start-WatchProcess {
    $watchScript = Join-Path $PSScriptRoot "git-worker.ps1"
    $psExe = "powershell"
    if (Get-Command pwsh -ErrorAction SilentlyContinue) { $psExe = "pwsh" }

    $fullArgs = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-File", "`"$watchScript`"",
        "-Mode", "watch",
        "-RepoPath", "`"$RepoPath`"",
        "-PushIntervalMinutes", $PushIntervalMinutes.ToString(),
        "-WatchIntervalSeconds", $WatchIntervalSeconds.ToString(),
        "-ThresholdFiles", $ThresholdFiles.ToString(),
        "-ThresholdLines", $ThresholdLines.ToString()
    )

    if (-not $DryRun) {
        Start-Process -FilePath $psExe -ArgumentList $fullArgs -WindowStyle Hidden
        Start-Sleep -Seconds 3

        $newProcs = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like "*git-worker*watch*" }
        if ($newProcs) {
            $newProcs[0].ProcessId | Out-File $WatchPidFile -Force
            Write-Log "Watch started with PID $($newProcs[0].ProcessId)"
        } else {
            Write-ErrorLog "Failed to start watch process"
        }
    } else {
        Write-Log "[DRY-RUN] Would start: $psExe $fullArgs"
    }
}

function Test-WatchAlive {
    if (Test-Path $WatchPidFile) {
        $watchPid = Get-Content $WatchPidFile -ErrorAction SilentlyContinue
        if ($watchPid) {
            $proc = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $watchPid" -ErrorAction SilentlyContinue
            if ($proc -and $proc.CommandLine -like "*git-worker*watch*") {
                return $true
            }
        }
    }

    $watchProcs = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*git-worker*watch*" }
    if ($watchProcs) {
        $watchProcs[0].ProcessId | Out-File $WatchPidFile -Force
        return $true
    }

    return $false
}

function Mode-Monitor {
    Write-Log "Mode: monitor (watchdog)"
    Write-Log "Check interval: ${MonitorCheckSeconds}s"

    while ($true) {
        try {
            $alive = Test-WatchAlive
            if ($alive) {
                Write-Log "Watch process is alive"
            } else {
                Write-Log "Watch process NOT FOUND - restarting..." -Level "WARN"
                Start-WatchProcess
            }
        } catch {
            Write-ErrorLog "Monitor loop error: $($_.Exception.Message)"
        }

        Start-Sleep -Seconds $MonitorCheckSeconds
    }
}

# ====== MODE: SETUP (Task Scheduler) ======

function Mode-Setup {
    $taskPath = "\Vault"
    $psExe = "powershell"
    if (Get-Command pwsh -ErrorAction SilentlyContinue) { $psExe = "pwsh" }
    $psArgs = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File'
    $scriptPath = "`"$(Join-Path $PSScriptRoot 'git-worker.ps1')`""

    if ($Remove) {
        Write-Log "Removing all vault git tasks..."
        schtasks /DELETE /TN "$taskPath\VaultGitCommit" /F 2>$null
        schtasks /DELETE /TN "$taskPath\VaultGitWatch" /F 2>$null
        schtasks /DELETE /TN "$taskPath\VaultGitMonitor" /F 2>$null
        schtasks /DELETE /TN "$taskPath\VaultSnapshot" /F 2>$null
        Write-Log "All vault tasks removed."
        return
    }

    Write-Log "Registering vault git tasks in Task Scheduler..."

    $cmd = "$psExe $psArgs $scriptPath -Mode commit -ThresholdFiles $ThresholdFiles -ThresholdLines $ThresholdLines"
    schtasks /CREATE /TN "$taskPath\VaultGitCommit" /SC DAILY /MO 1 /ST 00:00 /RI 60 /DU 24:00 /TR "$cmd" /RL HIGHEST /IT /F
    if ($LASTEXITCODE -eq 0) {
        Write-Log "  Created: VaultGitCommit (every 60 min, hidden window)"
    } else {
        Write-ErrorLog "  Failed to create VaultGitCommit (run as Admin?)"
    }

    $cmd = "$psExe $psArgs $scriptPath -Mode watch -PushIntervalMinutes $PushIntervalMinutes -WatchIntervalSeconds $WatchIntervalSeconds -ThresholdFiles $ThresholdFiles -ThresholdLines $ThresholdLines"
    schtasks /CREATE /TN "$taskPath\VaultGitWatch" /SC ONSTART /DELAY 0001:00 /TR "$cmd" /RL HIGHEST /IT /F
    if ($LASTEXITCODE -eq 0) {
        Write-Log "  Created: VaultGitWatch (on startup, hidden window)"
    } else {
        Write-ErrorLog "  Failed to create VaultGitWatch (run as Admin?)"
    }

    $cmd = "$psExe $psArgs $scriptPath -Mode monitor -MonitorCheckSeconds $MonitorCheckSeconds"
    schtasks /CREATE /TN "$taskPath\VaultGitMonitor" /SC ONSTART /DELAY 0002:00 /TR "$cmd" /RL HIGHEST /IT /F
    if ($LASTEXITCODE -eq 0) {
        Write-Log "  Created: VaultGitMonitor (on startup, hidden window)"
    } else {
        Write-ErrorLog "  Failed to create VaultGitMonitor (run as Admin?)"
    }

    Write-Log "All tasks registered under $taskPath"
    Write-Log "Verify: schtasks /QUERY /TN '$taskPath\'"
}

# ====== LOCK SYSTEM ======

if ($Mode -eq 'watch') {
    $LockFile = $WatchLockFile
} elseif ($Mode -eq 'monitor') {
    $LockFile = $MonitorLockFile
}
if ($Mode -in @('watch', 'monitor')) {
    if (Test-Path $LockFile) {
        $lockPid = Get-Content $LockFile -ErrorAction SilentlyContinue
        if ($lockPid) {
            $proc = Get-Process -Id $lockPid -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Log "Another git-worker ($Mode) is already running (PID $lockPid). Exiting."
                exit 0
            }
        }
    }
    $PID | Out-File $LockFile -Force
}

# ====== ENTRY POINT ======

try {
    switch ($Mode) {
        "commit"  { Mode-Commit }
        "watch"   { Mode-Watch }
        "monitor" { Mode-Monitor }
        "setup"   { Mode-Setup }
    }
} catch {
    Write-ErrorLog "Unhandled error: $($_.Exception.Message)"
    Write-Exit -ExitCode 1 -Message "Fatal error: $($_.Exception.Message)"
} finally {
    $lockFiles = @($WatchLockFile, $MonitorLockFile)
    foreach ($lf in $lockFiles) {
        if (Test-Path $lf) {
            $lockPid = Get-Content $lf -ErrorAction SilentlyContinue
            if ($lockPid -eq $PID) {
                Remove-Item $lf -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Exit -ExitCode 0 -Message "Mode '$Mode' completed"
