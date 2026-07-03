# self-healer.ps1 - Diagnoses and repairs common git automation failures
param([string]$Scope = "all", [switch]$Force)

try {
    $t = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindow -Namespace Win32 -PassThru
    $t::ShowWindow((Get-Process -Id $pid).MainWindowHandle, 0) | Out-Null
} catch {}

. (Join-Path $PSScriptRoot "core.ps1")
Write-Log "=== SELF-HEALER STARTED (scope: ${Scope}) ===" "HEAL"
$repairs = @()

function Repair-StaleLocks {
    $repos = @($script:CONFIG.RepoPath, $script:CONFIG.RepoPath2)
    foreach ($repo in $repos) {
        $lockResult = Test-LockFile -RepoPath $repo
        if ($lockResult.Status -eq "STALE") {
            if (Repair-LockFile -RepoPath $repo) { $script:repairs += "Removed stale lock: ${repo}" }
        }
    }
}

function Repair-StuckRebase {
    $repos = @($script:CONFIG.RepoPath, $script:CONFIG.RepoPath2)
    foreach ($repo in $repos) {
        $rebaseResult = Test-Rebase -RepoPath $repo
        if ($rebaseResult.Status -eq "STALE") {
            if (Repair-Rebase -RepoPath $repo) { $script:repairs += "Removed stuck rebase: ${repo}" }
        }
    }
}

function Repair-Credentials {
    $credResult = Test-Credential
    if ($credResult.Status -ne "OK" -or $Force) {
        if (Repair-Credential) { $script:repairs += "Fixed credential store" }
    }
}

function Repair-Remotes {
    $repos = @(
        @{ Path = $script:CONFIG.RepoPath; Remote = "origin"; Name = "vault" },
        @{ Path = $script:CONFIG.RepoPath2; Remote = "origin"; Name = "parent" }
    )
    foreach ($repo in $repos) {
        if (Repair-SshRemote -RepoPath $repo.Path -Remote $repo.Remote) {
            $script:repairs += "Switched $($repo.Name) remote to SSH"
        }
    }
}

function Repair-StaleProcesses {
    $stale = Get-Process -Name "git" -ErrorAction SilentlyContinue | Where-Object { $_.StartTime -lt (Get-Date).AddMinutes(-10) -and $_.Id -ne $pid }
    foreach ($proc in $stale) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            $script:repairs += "Killed stale git process (PID $($proc.Id))"
        } catch { Write-Log "Could not kill PID $($proc.Id): $_" "WARN" }
    }
}

function Repair-TaskScheduler {
    $tasks = @(
        @{ Name = "AutoCommitNotes"; Script = "C:\obsidian\Main\vault\auto-commit.ps1"; Schedule = "HOURLY" },
        @{ Name = "GitWorker"; Script = "C:\obsidian\Main\vault\git-worker.ps1"; Schedule = "HOURLY" },
        @{ Name = "HealthMonitor"; Script = "C:\obsidian\Main\Technical\Scripts\system\health-monitor.ps1"; Schedule = "MINUTE" }
    )
    foreach ($task in $tasks) {
        $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($task.Script)`""
        & schtasks /QUERY /TN $task.Name 2>$null | Out-Null
        $existing = ($LASTEXITCODE -eq 0)
        if (-not $existing -or $Force) {
            Write-Log "Re/creating task: $($task.Name)" "HEAL"
            & schtasks /DELETE /TN $task.Name /F 2>&1 | Out-Null
            if ($task.Schedule -eq "HOURLY") {
                $r = & schtasks /CREATE /SC HOURLY /TN $task.Name /TR "$cmd" /RL HIGHEST /F 2>&1
            } else {
                $r = & schtasks /CREATE /SC MINUTE /MO 5 /TN $task.Name /TR "$cmd" /RL HIGHEST /F 2>&1
            }
            if ($LASTEXITCODE -eq 0) {
                $script:repairs += "Task $($task.Name) registered"
            } else {
                Write-Log "Failed to register task $($task.Name): $r" "ERROR"
            }
        }
    }
}

function Repair-PushConfig {
    $repos = @(
        @{ Path = $script:CONFIG.RepoPath; Branch = "main"; Remote = "origin" },
        @{ Path = $script:CONFIG.RepoPath2; Branch = "master"; Remote = "origin" }
    )
    foreach ($repo in $repos) {
        $remote = Invoke-Git -RepoPath $repo.Path -Arguments @("config", "--local", "branch.$($repo.Branch).remote") 2>$null
        $merge = Invoke-Git -RepoPath $repo.Path -Arguments @("config", "--local", "branch.$($repo.Branch).merge") 2>$null
        if (-not $remote) {
            Invoke-Git -RepoPath $repo.Path -Arguments @("config", "--local", "branch.$($repo.Branch).remote", $repo.Remote) | Out-Null
            $script:repairs += "Restored branch.$($repo.Branch).remote=$($repo.Remote)"
        }
        if (-not $merge) {
            Invoke-Git -RepoPath $repo.Path -Arguments @("config", "--local", "branch.$($repo.Branch).merge", "refs/heads/$($repo.Branch)") | Out-Null
            $script:repairs += "Restored branch.$($repo.Branch).merge=refs/heads/$($repo.Branch)"
        }
    }
}

function Repair-Garbage {
    $repos = @($script:CONFIG.RepoPath, $script:CONFIG.RepoPath2)
    foreach ($repo in $repos) {
        # Remove stale gc.pid files from .git root
        Get-ChildItem "$repo\.git" -Filter "*.pid" -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            $script:repairs += "Removed stale PID: $($_.Name)"
        }
        # Scan all items in .git/objects for garbage (chaos, garbage, trash, tmp)
        Get-ChildItem "$repo\.git\objects" -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "chaos|garbage|trash|tmp" -or $_.Name -eq "garbage"
        } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $script:repairs += "Removed garbage from .git/objects: $($_.Name)"
        }
        # Also check .git root for non-standard files (COMMIT_EDITMSG is fine, but garbage is not)
        Get-ChildItem "$repo\.git" -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "chaos|garbage|trash|attack" -and $_.Name -ne "config"
        } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $script:repairs += "Removed garbage from .git: $($_.Name)"
        }
    }
}

function Repair-GitGC {
    $repos = @($script:CONFIG.RepoPath, $script:CONFIG.RepoPath2)
    foreach ($repo in $repos) {
        $total = (Get-ChildItem "$repo\.git" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeMB = $total / 1MB
        if ($sizeMB -gt 500) {
            Write-Log "Large .git: $(('{0:N0}MB' -f $sizeMB)) - running gc..." "HEAL"
            Invoke-Git -RepoPath $repo -Arguments @("gc", "--auto") | Out-Null
            $newTotal = (Get-ChildItem "$repo\.git" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $freed = $sizeMB - ($newTotal / 1MB)
            $script:repairs += "GC on ${repo}: freed $(('{0:N0}MB' -f $freed))"
        }
    }
}

$scopes = @{
    "all"         = @("Repair-StaleLocks", "Repair-StuckRebase", "Repair-Credentials", "Repair-Remotes", "Repair-StaleProcesses", "Repair-PushConfig", "Repair-Garbage", "Repair-TaskScheduler", "Repair-GitGC")
    "vault"       = @("Repair-StaleLocks", "Repair-StuckRebase", "Repair-Remotes", "Repair-PushConfig")
    "parent"      = @("Repair-StaleLocks", "Repair-StuckRebase", "Repair-Remotes", "Repair-PushConfig")
    "credentials" = @("Repair-Credentials", "Repair-Remotes")
    "tasks"       = @("Repair-TaskScheduler")
    "garbage"     = @("Repair-Garbage")
}

$toRun = $scopes[$Scope]
if (-not $toRun) { $toRun = $scopes["all"] }

foreach ($func in $toRun) {
    try { & $func } catch { Write-Log "Error in ${func}: $_" "ERROR" }
}

Write-Log "=== SELF-HEALER COMPLETE ===" "HEAL"
if ($repairs.Count -eq 0) {
    Write-Log "No repairs needed - all systems OK" "HEAL"
} else {
    Write-Log "Repairs performed:" "HEAL"
    foreach ($r in $repairs) { Write-Log "  OK $r" "HEAL" }
}
exit 0
