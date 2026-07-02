# core.ps1 — Shared git automation module (v3 with dumb-user protections)
# Sources: vault/auto-commit.ps1, vault/git-worker.ps1
# Unified with 3-layer redundancy: SSH → HTTPS+token → gh CLI

# === CONFIGURATION ===
$script:CONFIG = @{
    RepoPath    = "C:\obsidian\Main"
    RepoPath2   = "C:\obsidian"
    GitDir      = "C:\obsidian\Main\.git"
    GitDir2     = "C:\obsidian\.git"
    RemoteName  = "origin"
    Branch      = "main"
    Branch2     = "master"
    RemoteSSH   = "git@github.com:Konstantin2005/ObsiduanMain.git"
    RemoteHTTPS = "https://github.com/Konstantin2005/ObsiduanMain.git"
    Remote2SSH  = "git@github.com:Konstantin2005/BecapOvsiduan.git"
    
    LogDir      = "C:\obsidian\Main\Technical\Scripts\Logs"
    SystemDir   = "C:\obsidian\Main\Technical\Scripts\system"
    
    MaxAheadPush      = 50
    MaxAheadSkip      = 100
    LockFileRetries   = 3
    LockFileDelayMs   = 2000
    PushTimeoutSec    = 120
    
    MutexName   = "ObsidianVaultAutoCommit"
}

# === LOGGING ===
$script:LOG_FILE = "$($script:CONFIG.LogDir)\system.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    $null = try { Add-Content -Path $script:LOG_FILE -Value $line -Encoding UTF8 -ErrorAction Stop } catch {}
}

# === GIT HELPERS ===
function Get-GitDir {
    param([string]$RepoPath)
    return Join-Path $RepoPath ".git"
}

function Test-GitRepo {
    param([string]$RepoPath)
    return Test-Path "$RepoPath\.git\HEAD"
}

function Get-AheadCount {
    param([string]$RepoPath, [string]$Branch)
    return (git -C $RepoPath rev-list --count origin/$Branch..HEAD 2>$null)
}

function Invoke-Git {
    param([string]$RepoPath, [string]$Arguments)
    return (git -C $RepoPath @Arguments 2>$null)
}

function Invoke-Push {
    param([string]$RepoPath, [string]$Branch)
    git -C $RepoPath push origin $Branch 2>$null
    return $LASTEXITCODE -eq 0
}

# === HEALTH CHECKS ===
function Test-LockFile {
    param([string]$RepoPath)
    $lockFile = "$(Get-GitDir -RepoPath $RepoPath)\index.lock"
    if (Test-Path $lockFile) {
        $age = (Get-Date) - (Get-Item $lockFile).CreationTime
        if ($age.TotalMinutes -gt 10) {
            return @{ Status = "STALE"; Message = "Lock file present ($([math]::Round($age.TotalMinutes, 1)) min old)" }
        }
        return @{ Status = "OK"; Message = "Lock file present but fresh" }
    }
    return @{ Status = "OK"; Message = "no lock" }
}

function Test-Rebase {
    param([string]$RepoPath)
    $gitDir = Get-GitDir -RepoPath $RepoPath
    if (Test-Path "$gitDir\rebase-merge" -or Test-Path "$gitDir\rebase-apply") {
        return @{ Status = "STALE"; Message = "stuck rebase" }
    }
    return @{ Status = "OK"; Message = "no rebase" }
}

function Test-Credential {
    $helper = git config --global credential.helper 2>$null
    if ($helper -eq "manager") {
        $store = git config --global credential.credentialStore 2>$null
        if (-not $store) {
            return @{ Status = "WARN"; Message = "credential.helper=manager but no credentialStore set" }
        }
    }
    if ($helper -match "exit 1" -or $helper -eq "" -or $helper -match "f\(\)") {
        return @{ Status = "FAIL"; Message = "credential.helper is broken ($helper)" }
    }
    return @{ Status = "OK" }
}

function Test-Remote {
    param([string]$RepoPath)
    $url = git -C $RepoPath remote get-url origin 2>$null
    if ($url -like "git@*") {
        return @{ Status = "OK"; Message = $url }
    }
    return @{ Status = "FAIL"; Message = "Remote is not SSH: $url" }
}

function Test-All {
    param([string]$RepoPath)
    $results = @{}
    $results.Repo = Test-GitRepo -RepoPath $RepoPath
    $results.Remote = Test-Remote -RepoPath $RepoPath
    $results.Lock = Test-LockFile -RepoPath $RepoPath
    $results.Rebase = Test-Rebase -RepoPath $RepoPath
    $results.Cred = Test-Credential
    $allOk = ($results.Values | Where-Object { $_.Status -ne "OK" -and $_.Status -ne "WARN" }).Count -eq 0
    $results.AllOk = $allOk
    return $results
}

# === SELF-HEALING ===
function Repair-LockFile {
    param([string]$RepoPath)
    $lockFile = "$(Get-GitDir -RepoPath $RepoPath)\index.lock"
    if (Test-Path $lockFile) {
        Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $lockFile)) {
            Write-Log "Repaired: removed stale lock file" "HEAL"
            return $true
        }
    }
    return $false
}

function Repair-Rebase {
    param([string]$RepoPath)
    $repaired = $false
    $gitDir = Get-GitDir -RepoPath $RepoPath
    $rebaseDirs = @("rebase-merge", "rebase-apply")
    foreach ($rd in $rebaseDirs) {
        $d = Join-Path $gitDir $rd
         {
            Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $d)) {
                Write-Log "Repaired: removed stuck rebase ($rd)" "HEAL"
                $repaired = $true
            }
        }
    }
    return $repaired
}

function Repair-Credential {
    try {
        $helper = git config --global credential.helper 2>$null
        if ($helper -match "exit 1" -or $helper -match "f\(\)" -or $helper -eq "") {
            git config --global credential.helper "manager" 2>$null
            Write-Log "Repaired: restored credential.helper to manager" "HEAL"
        }
        git config --global credential.credentialStore "plaintext" 2>$null
        Write-Log "Repaired: set credential.credentialStore=plaintext" "HEAL"
        $token = gh auth token 2>$null
        if ($token) {
            $cred = "protocol=https`nhost=github.com`nusername=token`npassword=$token"
            $cred | git credential-store store 2>$null
            Write-Log "Stored gh token in plaintext store" "HEAL"
        }
        return $true
    } catch { Write-Log "Failed to repair credential: $_" "ERROR"; return $false }
}

function Repair-SshRemote {
    param([string]$RepoPath, [string]$Remote = "origin")
    $currentUrl = git -C $RepoPath remote get-url $Remote 2>$null
    if ($currentUrl -match "^https://") {
        $sshUrl = $currentUrl -replace '^https://github\.com/', 'git@github.com:'
        git -C $RepoPath remote set-url $Remote $sshUrl 2>$null
        Write-Log "Repaired: switched remote to SSH" "HEAL"
        return $true
    }
    return $false
}

function Repair-TaskScheduler {
    $tasks = @(
        @{ Name = "AutoCommitNotes"; Script = "C:\obsidian\Main\vault\auto-commit.ps1"; Minutes = 60 },
        @{ Name = "GitWorker"; Script = "C:\obsidian\Main\vault\git-worker.ps1"; Minutes = 60 },
        @{ Name = "HealthMonitor"; Script = "C:\obsidian\Main\Technical\Scripts\system\health-monitor.ps1"; Minutes = 5 }
    )
    foreach ($task in $tasks) {
        & schtasks /QUERY /TN $task.Name 2>$null | Out-Null
        $exists = ($LASTEXITCODE -eq 0)
        if (-not $exists) {
            $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($task.Script)`""
            if ($task.Minutes -eq 5) {
                & schtasks /CREATE /SC MINUTE /MO 5 /TN $task.Name /TR "$cmd" /RL HIGHEST /F 2>$null
            } else {
                & schtasks /CREATE /SC HOURLY /TN $task.Name /TR "$cmd" /RL HIGHEST /F 2>$null
            }
            if ($LASTEXITCODE -eq 0) {
                $script:repairs += "Task $($task.Name) registered"
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
        $remote = git -C $repo.Path config --local branch.$($repo.Branch).remote 2>$null
        if (-not $remote) {
            git -C $repo.Path config --local branch.$($repo.Branch).remote $repo.Remote 2>$null
            $script:repairs += "Restored branch.$($repo.Branch).remote=$($repo.Remote)"
        }
        $merge = git -C $repo.Path config --local branch.$($repo.Branch).merge 2>$null
        if (-not $merge) {
            git -C $repo.Path config --local branch.$($repo.Branch).merge "refs/heads/$($repo.Branch)" 2>$null
            $script:repairs += "Restored branch.$($repo.Branch).merge=refs/heads/$($repo.Branch)"
        }
    }
}

function Repair-Garbage {
    $repos = @($script:CONFIG.RepoPath, $script:CONFIG.RepoPath2)
    foreach ($repo in $repos) {
        Get-ChildItem "$repo\.git\*.pid" -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            $script:repairs += "Removed stale PID: $($_.Name)"
        }
        Get-ChildItem "$repo\.git\objects" -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "chaos|garbage|trash|tmp"
        } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $script:repairs += "Removed garbage from .git/objects: $($_.Name)"
        }
    }
}

function Repair-DeletedGit {
    param([string]$RepoPath, [string]$RemoteUrl, [string]$Branch)
    $gitDir = Join-Path $RepoPath ".git"
    if (Test-Path $gitDir) { return $false }
    Write-Log "Repaired: reinitialized .git for $RepoPath" "HEAL"
    & git -C $RepoPath init 2>$null
    & git -C $RepoPath remote add origin $RemoteUrl 2>$null
    & git -C $RepoPath config user.name "Recovery Bot" 2>$null
    & git -C $RepoPath config user.email "recovery@obsidian.vault" 2>$null
    & git -C $RepoPath fetch origin 2>$null
    $remoteRef = & git -C $RepoPath rev-parse origin/$Branch 2>$null
    if ($remoteRef) {
        & git -C $RepoPath reset --hard origin/$Branch 2>$null
        & git -C $RepoPath branch --set-upstream-to=origin/$Branch $Branch 2>$null
    } else {
        & git -C $RepoPath add -A 2>$null
        & git -C $RepoPath commit -m "chore: recovery after .git deletion" 2>$null
        & git -C $RepoPath branch -M $Branch 2>$null
        & git -C $RepoPath config --local branch.$Branch.remote origin 2>$null
        & git -C $RepoPath config --local branch.$Branch.merge "refs/heads/$Branch" 2>$null
    }
    return $true
}

