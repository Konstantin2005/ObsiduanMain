param(
    [string]$BasePath = "C:\obsidian",
    [string]$LogsDir = "C:\obsidian\Main\Technical\Scripts\Logs",
    [string]$MonitorLogPath = "C:\obsidian\Main\Technical\Scripts\Logs\monitor.log",
    [int]$CheckIntervalSeconds = 15,
    [int]$DurationMinutes = 1440  # 24 hours default
)

$ErrorActionPreference = 'Continue'

# === LOGGING ===

function Write-MonitorLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [MONITOR] $Message"
    Write-Host $line
    try {
        $logDir = Split-Path -Parent $MonitorLogPath
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Add-Content -LiteralPath $MonitorLogPath -Value $line -Encoding UTF8
    } catch {}
}

# === REPOSITORY DISCOVERY ===

function Get-ObsidianRepos {
    param([string]$RootPath)
    
    $repos = @()
    $visited = @{}
    
    Write-MonitorLog "Scanning for git repositories under: $RootPath"
    
    # Find all .git directories (not files — skip submodules)
    $gitDirs = Get-ChildItem -Path $RootPath -Recurse -Depth 5 -Directory -Force -ErrorAction SilentlyContinue `
        | Where-Object { $_.Name -eq '.git' -and $_.PSIsContainer -and -not $visited.ContainsKey($_.Parent.FullName) }
    
    foreach ($gitDir in $gitDirs) {
        $repoPath = $gitDir.Parent.FullName
        if ($visited.ContainsKey($repoPath)) { continue }
        $visited[$repoPath] = $true
        
        # Skip .git directories themselves
        if ($repoPath -match '\\.git$') { continue }
        
        # Determine branch
        $branch = & "git" -C $repoPath rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch -or $branch -eq 'HEAD') { $branch = 'main' }
        
        # Determine remote URL
        $remoteUrl = & "git" -C $repoPath remote get-url origin 2>$null
        if (-not $remoteUrl) { $remoteUrl = "(no remote)" }
        
        # Repo name: relative path from BasePath
        $repoName = if ($repoPath -eq $RootPath) {
            (Split-Path -Leaf $RootPath)
        } else {
            $relative = $repoPath.Substring($RootPath.Length).TrimStart('\').Replace('\', '-')
            if (-not $relative) { (Split-Path -Leaf $RootPath) } else { "$(Split-Path -Leaf $RootPath)-$relative" }
        }
        
        # Check if it has changes (active repo)
        $hasChanges = & "git" -C $repoPath status --porcelain 2>$null
        $changeCount = if ($hasChanges) { @($hasChanges).Count } else { 0 }
        
        $repos += @{
            Path        = $repoPath
            Name        = $repoName
            Branch      = $branch
            RemoteUrl   = $remoteUrl
            ChangeCount = $changeCount
            Active      = $changeCount -gt 0 -or $true  # Always monitor
        }
        
        Write-MonitorLog "  Found repo: $repoName | $repoPath | branch: $branch | changes: $changeCount"
    }
    
    if ($repos.Count -eq 0) {
        Write-MonitorLog "WARNING: No git repositories found under $RootPath"
    }
    
    return $repos
}

# === DAILY-PUSH INSTANCE MANAGEMENT ===

$script:Instances = @{}  # repoName -> @{ Process, LogPath, LastCommit, LastPush, CommitCount, PushCount, StartTime }

function Start-DailyPushInstance {
    param($Repo)
    
    $repoName = $Repo.Name
    $logFile = Join-Path $LogsDir "daily-push-$repoName.log"
    $dailyPushScript = "C:\obsidian\Main\Technical\Scripts\Git\daily-push.ps1"
    
    if (-not (Test-Path $dailyPushScript)) {
        Write-MonitorLog "ERROR: daily-push.ps1 not found at $dailyPushScript"
        return $null
    }
    
    # Ensure log directory exists
    $logDir = Split-Path -Parent $logFile
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    
    # Start daily-push.ps1 for this repo
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$dailyPushScript`" -RepoPath `"$($Repo.Path)`" -Branch `"$($Repo.Branch)`" -RepoName `"$repoName`" -LogPath `"$logFile`" -CommitIntervalSeconds 1 -PushIntervalMinutes 5"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        $script:Instances[$repoName] = @{
            Process     = $process
            LogPath     = $logFile
            LastCommit  = $null
            LastPush    = $null
            CommitCount = 0
            PushCount   = 0
            StartTime   = Get-Date
            Repo        = $Repo
        }
        Write-MonitorLog "Started daily-push for '$repoName' (PID: $($process.Id))"
        return $process
    }
    catch {
        Write-MonitorLog "ERROR: Failed to start daily-push for '$repoName': $_"
        return $null
    }
}

function Stop-DailyPushInstance {
    param([string]$RepoName)
    
    if ($script:Instances.ContainsKey($RepoName)) {
        $instance = $script:Instances[$RepoName]
        $process = $instance.Process
        if ($process -and !$process.HasExited) {
            try {
                $process.Kill()
                $process.WaitForExit(3000)
                Write-MonitorLog "Stopped daily-push for '$RepoName'"
            }
            catch {
                Write-MonitorLog "WARNING: Could not kill process for '$RepoName': $_"
            }
        }
        $script:Instances.Remove($RepoName)
    }
}

function Get-LiveRepoStatus {
    param($Repo)
    
    $changes = & "git" -C $Repo.Path status --porcelain 2>$null
    $changeCount = if ($changes) { @($changes).Count } else { 0 }
    
    $ahead = & "git" -C $Repo.Path rev-list --count "origin/$($Repo.Branch)..$($Repo.Branch)" 2>$null
    if (-not ($ahead -match '^\d+$')) { $ahead = 0 }
    
    $lastCommitMsg = & "git" -C $Repo.Path log --oneline -1 2>$null
    $lastCommitTime = & "git" -C $Repo.Path log -1 --format=%ci 2>$null
    
    return @{
        ChangeCount = $changeCount
        AheadCount  = [int]$ahead
        LastCommit  = $lastCommitMsg
        LastTime    = $lastCommitTime
    }
}

function Update-InstanceFromLog {
    param([string]$RepoName)
    
    if (-not $script:Instances.ContainsKey($RepoName)) { return }
    
    $instance = $script:Instances[$RepoName]
    $logPath = $instance.LogPath
    
    if (-not (Test-Path $logPath)) { return }
    
    try {
        $lines = Get-Content $logPath -Tail 30 -ErrorAction SilentlyContinue
        $lastGoodLine = $null
        
        foreach ($line in $lines) {
            if ($line -match 'Auto-commit:\s*(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
                $timeStr = $matches[1]
                $time = [DateTime]::ParseExact($timeStr, "yyyy-MM-dd HH:mm:ss", $null)
                if (-not $instance.LastCommit -or $time -gt $instance.LastCommit) {
                    $instance.LastCommit = $time
                    $instance.CommitCount++
                    Write-MonitorLog "COMMIT [$RepoName] #$($instance.CommitCount) at $timeStr"
                }
                $lastGoodLine = $line
            }
            
            if ($line -match 'Push completed successfully') {
                $pushTime = Get-Date
                if (-not $instance.LastPush -or $pushTime -gt $instance.LastPush) {
                    $instance.LastPush = $pushTime
                    $instance.PushCount++
                    Write-MonitorLog "PUSH  [$RepoName] #$($instance.PushCount) at $($pushTime.ToString('yyyy-MM-dd HH:mm:ss'))"
                }
                $lastGoodLine = $line
            }
            
            if ($line -match 'LOOP ERROR:') {
                Write-MonitorLog "ERROR [$RepoName] $line"
            }
        }
    }
    catch {
        # Silently continue on log read errors
    }
}

# === MAIN MONITOR LOOP ===

Write-MonitorLog "========================================"
Write-MonitorLog "OBSIDIAN GIT MONITOR STARTED"
Write-MonitorLog "Base path: $BasePath"
Write-MonitorLog "Check interval: ${CheckIntervalSeconds}s"
Write-MonitorLog "Duration: ${DurationMinutes}m"
Write-MonitorLog "========================================"

# Discover all repos
$repos = Get-ObsidianRepos -RootPath $BasePath

if ($repos.Count -eq 0) {
    Write-MonitorLog "FATAL: No repositories to monitor. Exiting."
    exit 1
}

Write-MonitorLog "Found $($repos.Count) repositories to monitor"
Write-MonitorLog ""

# Start daily-push for each active repo
foreach ($repo in $repos) {
    Start-DailyPushInstance -Repo $repo
    Start-Sleep -Milliseconds 500
}

$endTime = (Get-Date).AddMinutes($DurationMinutes)

while ((Get-Date) -lt $endTime) {
    $overallStatus = "OK"
    $statusParts = @()
    
    foreach ($repo in $repos) {
        $repoName = $repo.Name
        
        # Check if instance is still running
        $instanceRunning = $false
        if ($script:Instances.ContainsKey($repoName)) {
            $proc = $script:Instances[$repoName].Process
            $instanceRunning = $proc -and !$proc.HasExited
        }
        
        # Restart if dead
        if (-not $instanceRunning) {
            Write-MonitorLog "RESTART [$repoName] Process died, restarting..."
            $script:Instances.Remove($repoName)
            Start-DailyPushInstance -Repo $repo
            $overallStatus = "WARN"
        }
        
        # Update status from log
        Update-InstanceFromLog -RepoName $repoName
        
        # Get live repo status
        $liveStatus = Get-LiveRepoStatus -Repo $repo
        
        # Build status string
        $changes = $liveStatus.ChangeCount
        $ahead = $liveStatus.AheadCount
        $statusParts += "$repoName($changes ch, $ahead ahead)"
    }
    
    # Print periodic status (every ~2 minutes at 15s interval = every 8 iterations)
    $iteration = [math]::Floor(((Get-Date) - $endTime + [TimeSpan]::FromMinutes($DurationMinutes)).TotalSeconds / $CheckIntervalSeconds)
    if ($iteration % 8 -eq 0) {
        Write-MonitorLog "STATUS: [$($statusParts -join ' | ')]"
        
        # Check if any instance has made progress
        $totalCommits = ($script:Instances.Values | ForEach-Object { $_.CommitCount } | Measure-Object -Sum).Sum
        $totalPushes = ($script:Instances.Values | ForEach-Object { $_.PushCount } | Measure-Object -Sum).Sum
        Write-MonitorLog "TOTALS: Commits=$totalCommits | Pushes=$totalPushes"
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
}

# === MONITOR SUMMARY ===

Write-MonitorLog ""
Write-MonitorLog "========================================"
Write-MonitorLog "MONITOR SUMMARY"
Write-MonitorLog "========================================"

$allOk = $true
foreach ($repo in $repos) {
    $repoName = $repo.Name
    $instance = $script:Instances[$repoName]
    
    if ($instance) {
        $running = $instance.Process -and !$instance.Process.HasExited
        $uptime = if ($instance.StartTime) { 
            [math]::Round(((Get-Date) - $instance.StartTime).TotalMinutes, 1)
        } else { 0 }
        
        Write-MonitorLog "Repo:    $repoName"
        Write-MonitorLog "  Path:     $($repo.Path)"
        Write-MonitorLog "  Branch:   $($repo.Branch)"
        Write-MonitorLog "  Running:  $(if($running){'YES'}else{'NO'})"
        Write-MonitorLog "  Uptime:   ${uptime}m"
        Write-MonitorLog "  Commits:  $($instance.CommitCount)"
        Write-MonitorLog "  Pushes:   $($instance.PushCount)"
        Write-MonitorLog "  Last Cmt: $($instance.LastCommit)"
        Write-MonitorLog "  Last Push: $($instance.LastPush)"
        
        if (-not $running -or $instance.CommitCount -eq 0 -and $instance.PushCount -eq 0) {
            $allOk = $false
        }
    } else {
        Write-MonitorLog "Repo:    $repoName — NO INSTANCE"
        $allOk = $false
    }
}

Write-MonitorLog ""
Write-MonitorLog "Overall status: $(if($allOk){'ALL OK'}else{'ISSUES DETECTED'})"
Write-MonitorLog "Monitor finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-MonitorLog "========================================"

if (-not $allOk) { exit 1 }
exit 0