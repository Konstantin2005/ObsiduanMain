# core.ps1 — Shared git automation module (v2 with dumb-user protections)
# Sources: vault/auto-commit.ps1, vault/git-worker.ps1
# Unified with 3-layer redundancy: SSH → HTTPS+token → gh CLI

# === SELF-PROTECTION: Bootstrap fallback ===
# If this file is sourced with . (dot-sourcing), these vars survive
# If sourcing fails, each script has an embedded fallback
$script:CORE_LOADED = $true

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
    
    MaxAheadPush      = 50    # Don't push if more than this ahead
    MaxAheadSkip      = 100   # Completely skip push check
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

function Invoke-Git {
    param(
        [string]$RepoPath,
        [string[]]$Arguments,
        [int]$Retries = $script:CONFIG.LockFileRetries,
        [int]$TimeoutSec = 60
    )
    
    $env:GIT_TERMINAL_PROMPT = "0"
    $env:GCM_INTERACTIVE = "never"
    $env:GIT_ASKPASS = "echo"
    
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        $output = try {
            & "git" -C $RepoPath @Arguments 2>&1
            $global:LASTEXITCODE = 0
        } catch {
            $global:LASTEXITCODE = 1
            $_.Exception.Message
        }
        
        $exitCode = $global:LASTEXITCODE
        
        if ($exitCode -eq 0) { return $output }
        
        $outputStr = "$output"
        if ($outputStr -match "index\.lock") {
            Write-Log "Lock file conflict (attempt $attempt/$Retries): $outputStr" "WARN"
            if ($attempt -lt $Retries) {
                Start-Sleep -Milliseconds $script:CONFIG.LockFileDelayMs
                # Kill stale git processes
                Get-Process -Name "git" -ErrorAction SilentlyContinue | Where-Object { $_.StartTime -lt (Get-Date).AddMinutes(-5) } | Stop-Process -Force -ErrorAction SilentlyContinue
                continue
            }
        }
        
        return $output
    }
    
    return $output
}

function Get-GitDir {
    param([string]$RepoPath)
    return "$RepoPath\.git"
}

# === CHANGE DETECTION ===

function Get-ChangeCount {
    param([string]$RepoPath)
    $status = Invoke-Git -RepoPath $RepoPath -Arguments @("status", "--porcelain")
    if (-not $status) { return 0 }
    return @($status | Where-Object { $_ -match '^[ MADRCU?!]' }).Count
}

function Get-ChangeLineCount {
    param([string]$RepoPath)
    $diff = Invoke-Git -RepoPath $RepoPath -Arguments @("diff", "--stat")
    if (-not $diff) { return 0 }
    $match = [regex]::Match($diff, '(\d+) insertions?')
    if ($match.Success) { return [int]$match.Groups[1].Value }
    $match2 = [regex]::Match($diff, '(\d+) deletions?')
    if ($match2.Success) { return [int]$match2.Groups[1].Value }
    # Check for binary files
    if ($diff -match "Bin") { return 1 }
    return 0
}

# === COMMIT ===

function Invoke-Commit {
    param([string]$RepoPath, [string]$Message)
    $args = @("commit", "-m", $Message, "--no-gpg-sign")
    # If no changes staged, add first
    $status = Invoke-Git -RepoPath $RepoPath -Arguments @("status", "--porcelain")
    if ($status) {
        Invoke-Git -RepoPath $RepoPath -Arguments @("add", "-A") | Out-Null
    }
    return Invoke-Git -RepoPath $RepoPath -Arguments $args
}

# === PUSH — 3-LAYER FALLBACK ===

function Get-AheadCount {
    param([string]$RepoPath, [string]$Remote = "origin", [string]$Branch = "main")
    $count = Invoke-Git -RepoPath $RepoPath -Arguments @("rev-list", "--count", "${Remote}/${Branch}..${Branch}")
    if ($count -match '^\d+$') { return [int]$count }
    return -1  # No upstream
}

function Invoke-Push {
    param(
        [string]$RepoPath,
        [string]$Remote = "origin",
        [string]$Branch = "main",
        [bool]$Force = $false
    )
    
    # ---- Check ahead count ----
    $ahead = Get-AheadCount -RepoPath $RepoPath -Remote $Remote -Branch $Branch
    if ($ahead -gt $script:CONFIG.MaxAheadSkip) {
        Write-Log "Push SKIPPED: $ahead commits ahead (>$($script:CONFIG.MaxAheadSkip) max)" "SKIP"
        return $null
    }
    
    if ($ahead -gt $script:CONFIG.MaxAheadPush) {
        Write-Log "Push DEFERRED: $ahead commits ahead (>$($script:CONFIG.MaxAheadPush)), will retry later" "DEFER"
        return $null
    }
    
    # ---- Layer 1: SSH ----
    # Ensure SSH remote
    $currentRemote = Invoke-Git -RepoPath $RepoPath -Arguments @("remote", "get-url", $Remote)
    if ($currentRemote -match "^https://") {
        $sshUrl = $currentRemote -replace '^https://github\.com/', 'git@github.com:'
        Invoke-Git -RepoPath $RepoPath -Arguments @("remote", "set-url", $Remote, $sshUrl) | Out-Null
    }
    
    $pushArgs = @("push", $Remote, $Branch)
    if ($Force) { $pushArgs += "--force" }
    
    Write-Log "Pushing to $Remote/$Branch via SSH..." "PUSH"
    $result = Invoke-Git -RepoPath $RepoPath -Arguments $pushArgs -TimeoutSec $script:CONFIG.PushTimeoutSec
    
    if ($global:LASTEXITCODE -eq 0) {
        Write-Log "Push SUCCESS ($Remote/$Branch)" "PUSH"
        return $result
    }
    
    # ---- Layer 2: HTTPS + GCM ----
    Write-Log "SSH failed, trying HTTPS..." "WARN"
    $httpsUrl = $currentRemote -replace '^git@github\.com:', 'https://github.com/'
    Invoke-Git -RepoPath $RepoPath -Arguments @("remote", "set-url", $Remote, $httpsUrl) | Out-Null
    
    $result2 = Invoke-Git -RepoPath $RepoPath -Arguments $pushArgs -TimeoutSec $script:CONFIG.PushTimeoutSec
    if ($global:LASTEXITCODE -eq 0) {
        Write-Log "Push SUCCESS via HTTPS" "PUSH"
        return $result2
    }
    
    # ---- Layer 3: gh CLI ----
    Write-Log "HTTPS failed, trying gh CLI..." "WARN"
    $result3 = try {
        $env:GIT_TERMINAL_PROMPT = "0"
        $env:GH_TOKEN = $(gh auth token 2>$null)
        & "gh" "push" "--repo" $currentRemote 2>&1
        $global:LASTEXITCODE = 0
    } catch {
        $global:LASTEXITCODE = 1
        $_.Exception.Message
    }
    
    if ($global:LASTEXITCODE -eq 0) {
        Write-Log "Push SUCCESS via gh CLI" "PUSH"
        return $result3
    }
    
    # ---- All layers failed ----
    Write-Log "All push methods FAILED for $RepoPath" "ERROR"
    return $result
}

# === HEALTH CHECKS ===

function Test-GitRepo {
    param([string]$RepoPath)
    $gitDir = Get-GitDir -RepoPath $RepoPath
    if (-not (Test-Path $gitDir)) {
        return @{ Status = "FAIL"; Message = ".git not found at $gitDir" }
    }
    
    $result = Invoke-Git -RepoPath $RepoPath -Arguments @("rev-parse", "--git-dir")
    if ($global:LASTEXITCODE -ne 0) {
        return @{ Status = "FAIL"; Message = "Not a valid git repo: $result" }
    }
    
    return @{ Status = "OK" }
}

function Test-Remote {
    param([string]$RepoPath, [string]$Remote = "origin")
    $result = Invoke-Git -RepoPath $RepoPath -Arguments @("remote", "-v")
    if (-not ($result -match $Remote)) {
        return @{ Status = "FAIL"; Message = "Remote '$Remote' not configured" }
    }
    return @{ Status = "OK" }
}

function Test-LockFile {
    param([string]$RepoPath)
    $lockFile = "$(Get-GitDir -RepoPath $RepoPath)\index.lock"
    if (Test-Path $lockFile) {
        $age = (Get-Date) - (Get-Item $lockFile).CreationTime
        if ($age.TotalMinutes -gt 5) {
            return @{ Status = "STALE"; Message = "Stale lock file ($($age.TotalMinutes.ToString('F1')) min old)" }
        }
        return @{ Status = "LOCKED"; Message = "Lock file present ($($age.TotalMinutes.ToString('F1')) min old)" }
    }
    return @{ Status = "OK" }
}

function Test-Rebase {
    param([string]$RepoPath)
    $rebaseDir = "$(Get-GitDir -RepoPath $RepoPath)\rebase-merge"
    if (Test-Path $rebaseDir) {
        return @{ Status = "STALE"; Message = "Stuck rebase at $rebaseDir" }
    }
    return @{ Status = "OK" }
}

function Test-Credential {
    $helper = git config --global credential.helper 2>$null
    if ($helper -eq "manager") {
        $store = git config --global credential.credentialStore 2>$null
        if (-not $store) {
            return @{ Status = "WARN"; Message = "credential.helper=manager but no credentialStore set (may fail from Task Scheduler)" }
        }
    }
    # Detect broken/exiting credential helpers
    if ($helper -match "exit 1" -or $helper -match "f\(\)" -or $helper -eq "") {
        return @{ Status = "FAIL"; Message = "credential.helper is broken or empty ($helper)" }
    }
    return @{ Status = "OK" }
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
    # Handle both rebase-merge and rebase-apply
    $rebaseDirs = @("$gitDir\rebase-merge", "$gitDir\rebase-apply")
    foreach ($rd in $rebaseDirs) {
        if (Test-Path $rd) {
            Remove-Item -LiteralPath $rd -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $rd)) {
                Write-Log "Repaired: removed stuck rebase ($rd)" "HEAL"
                $repaired = $true
            }
        }
    }
    return $repaired
}

function Repair-Credential {
    try {
        # Fix broken helper first
        $helper = git config --global credential.helper 2>$null
        if ($helper -match "exit 1" -or $helper -match "f\(\)" -or $helper -eq "") {
            git config --global credential.helper "manager" 2>$null
            Write-Log "Repaired: restored credential.helper from broken to manager" "HEAL"
        }
        # Ensure plaintext store is configured
        git config --global credential.credentialStore "plaintext" 2>$null
        Write-Log "Repaired: set credential.credentialStore=plaintext" "HEAL"
        
        # Try to store existing token
        $token = gh auth token 2>$null
        if ($token) {
            $hostname = "github.com"
            $cred = "protocol=https`nhost=$hostname`nusername=token`npassword=$token"
            $cred | git credential-store store 2>$null
            Write-Log "Stored gh token in plaintext store" "HEAL"
        }
        return $true
    } catch {
        Write-Log "Failed to repair credential: $_" "ERROR"
        return $false
    }
}

function Repair-SshRemote {
    param([string]$RepoPath, [string]$Remote = "origin")
    $currentUrl = Invoke-Git -RepoPath $RepoPath -Arguments @("remote", "get-url", $Remote) 2>$null
    if ($currentUrl -match "^https://") {
        $sshUrl = $currentUrl -replace '^https://github\.com/', 'git@github.com:'
        Invoke-Git -RepoPath $RepoPath -Arguments @("remote", "set-url", $Remote, $sshUrl) | Out-Null
        Write-Log "Repaired: switched remote to SSH" "HEAL"
        return $true
    }
    return $false
}

function Test-All {
    param([string]$RepoPath)
    $results = @{}
    
    $results.Repo = Test-GitRepo -RepoPath $RepoPath
    $results.Remote = Test-Remote -RepoPath $RepoPath
    $results.Lock = Test-LockFile -RepoPath $RepoPath
    $results.Rebase = Test-Rebase -RepoPath $RepoPath
    $results.Cred = Test-Credential
    
    $allOk = ($results.Values | Where-Object { $_.Status -ne "OK" }).Count -eq 0
    $results.AllOk = $allOk
    
    return $results
}

# === DUMB-USER PROTECTIONS ===

function Test-GitInstalled {
    # Check if git is available
    $gitPath = Get-Command "git" -ErrorAction SilentlyContinue
    if (-not $gitPath) {
        return @{ Status = "FAIL"; Message = "Git is not installed or not in PATH" }
    }
    $version = & git --version 2>$null
    if (-not $version) {
        return @{ Status = "FAIL"; Message = "Git binary found but fails to run" }
    }
    return @{ Status = "OK"; Version = $version }
}

function Test-GitIntegrity {
    param([string]$RepoPath)
    $gitDir = Get-GitDir -RepoPath $RepoPath
    if (-not (Test-Path $gitDir)) {
        return @{ Status = "FAIL"; Message = ".git directory does not exist" }
    }
    if (-not (Test-Path "$gitDir\HEAD")) {
        return @{ Status = "FAIL"; Message = ".git/HEAD is missing" }
    }
    # Verify git can read the repo
    $result = & git -C $RepoPath rev-parse --git-dir 2>$null
    if (-not $result) {
        return @{ Status = "FAIL"; Message = "git rev-parse failed — repo is corrupt" }
    }
    return @{ Status = "OK" }
}

function Repair-DeletedGit {
    param([string]$RepoPath, [string]$RemoteUrl = "", [string]$Branch = "main")
    
    $gitDir = Get-GitDir -RepoPath $RepoPath
    $logPrefix = "Repair-DeletedGit($RepoPath)"
    
    # If .git exists and is valid, nothing to do
    $check = Test-GitIntegrity -RepoPath $RepoPath
    if ($check.Status -eq "OK") { return $false }
    
    Write-Log "$logPrefix: .git missing or corrupt — reinitializing" "HEAL"
    
    # Try git init
    $initResult = & git -C $RepoPath init 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "$logPrefix: git init failed: $initResult" "ERROR"
        return $false
    }
    Write-Log "$logPrefix: git init successful" "HEAL"
    
    # Configure user
    & git -C $RepoPath config user.name "Auto-commit Bot" 2>$null
    & git -C $RepoPath config user.email "bot@obsidian.vault" 2>$null
    
    # Set up remote if URL provided
    if ($RemoteUrl) {
        & git -C $RepoPath remote add origin $RemoteUrl 2>$null
        Write-Log "$logPrefix: remote origin -> $RemoteUrl" "HEAL"
    }
    
    # Create initial commit if there are files
    $files = Get-ChildItem $RepoPath -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notlike "*\.git\*" }
    $hasContent = & git -C $RepoPath status --porcelain 2>$null
    if ($hasContent) {
        & git -C $RepoPath add -A 2>$null
        & git -C $RepoPath commit -m "chore: initial commit after .git recovery" 2>$null
        Write-Log "$logPrefix: created initial commit with existing files" "HEAL"
    }
    
    # Set upstream
    & git -C $RepoPath config --local branch.$Branch.remote origin 2>$null
    & git -C $RepoPath config --local branch.$Branch.merge "refs/heads/$Branch" 2>$null
    
    # Try to fetch from remote to restore history
    if ($RemoteUrl) {
        & git -C $RepoPath fetch origin 2>$null
        $remoteMain = & git -C $RepoPath rev-parse origin/$Branch 2>$null
        if ($remoteMain) {
            & git -C $RepoPath branch --set-upstream-to=origin/$Branch $Branch 2>$null
            # Reset to remote (discard local init commit in favor of remote)
            & git -C $RepoPath reset --hard origin/$Branch 2>$null
            Write-Log "$logPrefix: reset to origin/$Branch (restored remote history)" "HEAL"
        }
    }
    
    Write-Log "$logPrefix: .git fully recovered" "HEAL"
    return $true
}

function Test-CorrectDirectory {
    param([string]$ExpectedPath)
    $current = (Get-Location).Path
    if ($current -ne $ExpectedPath) {
        return @{ Status = "FAIL"; Message = "Running from '$current' instead of '$ExpectedPath'"; Current = $current; Expected = $ExpectedPath }
    }
    return @{ Status = "OK" }
}

function Get-ProcessMutex {
    param([string]$MutexName)
    try {
        $mutex = New-Object System.Threading.Mutex($false, $MutexName)
        $hasHandle = $mutex.WaitOne(0)
        if (-not $hasHandle) {
            return $null
        }
        return $mutex
    } catch {
        return $null  # Can't acquire mutex? Run anyway (fallback)
    }
}

function Remove-ProcessMutex {
    param($Mutex)
    if ($Mutex) {
        try {
            $Mutex.ReleaseMutex()
            $Mutex.Dispose()
        } catch {}
    }
}

function Get-GitVersion {
    $v = & git --version 2>$null
    if ($v -match "(\d+\.\d+\.\d+)") {
        return $Matches[1]
    }
    return "0.0.0"
}

# Auto-run: if this file is executed directly (not dot-sourced), show bootstrap info
if ($MyInvocation.InvocationName -eq ".\core.ps1" -or $MyInvocation.InvocationName -eq "core.ps1") {
    Write-Host "core.ps1 — Shared git automation module"
    Write-Host "Do not run directly. Use: . .\core.ps1"
}
