param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$Branch = "main",
    [string]$GitPath = "git",
    [string]$LogPath = (Join-Path $RepoPath "Technical\Scripts\Logs\daily-push.log"),
    [int]$CommitIntervalSeconds = 1,
    [int]$PushIntervalMinutes = 5,
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

$lockFile = Join-Path $RepoPath "Technical\Scripts\Logs\.daily-push.lock"
if (Test-Path $lockFile) {
    $lockPid = Get-Content $lockFile -ErrorAction SilentlyContinue
    if ($lockPid -and (Get-Process -Id $lockPid -ErrorAction SilentlyContinue)) {
        Write-Host "Another instance (PID $lockPid) is already running. Exiting."
        exit 0
    }
}
$PID | Out-File $lockFile -Force

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Split-Path -Parent $LogPath
    if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -LiteralPath $LogPath -Value "[$timestamp] $Message"
}

function Invoke-Git {
    param([Parameter(Mandatory=$true)][string[]]$Args)
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $output = & $GitPath @Args 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP
    if ($output) { 
        $output | ForEach-Object { 
            $line = $_
            if ($line -is [System.Management.Automation.ErrorRecord]) {
                $line = $line.Exception.Message
            }
            if ($line -match '^(From |Already up|Everything up|remote: |Unpacking |Total |Resolving |Compressing |Writing |To https)') {
                Write-Log "[git] $line"
            } else {
                Write-Log "$line"
            }
        } 
    }
    if ($code -ne 0) { throw "git $($Args -join ' ') failed with code $code" }
}

function Test-HasChanges {
    $status = & $GitPath status --porcelain 2>&1
    return $status -ne ""
}

function Commit-Changes {
    try {
        Ensure-OnBranch
        if (-not (Test-HasChanges)) {
            Write-Log "No changes to commit"
            return
        }
        Write-Log "Committing changes..."
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        & $GitPath @('add', '-A') 2>&1 | Out-Null
        $addCode = $LASTEXITCODE
        if ($addCode -ne 0) {
            Write-Log "git add failed with code $addCode, skipping"
            $ErrorActionPreference = $prevEAP
            return
        }
        $msg = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        & $GitPath @('commit', '-m', $msg) 2>&1 | ForEach-Object { Write-Log "$_" }
        $commitCode = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP
        if ($commitCode -eq 0) {
            Write-Log "Commit completed"
        } else {
            Write-Log "Nothing to commit (clean tree)"
        }
    }
    catch {
        Write-Log "Commit-Changes error: $($_.Exception.Message)"
    }
}

function Ensure-OnBranch {
    $currentBranch = & $GitPath rev-parse --abbrev-ref HEAD 2>&1
    if ($currentBranch -ne $Branch) {
        Write-Log "Branch mismatch: on '$currentBranch', expected '$Branch'. Switching..."
        Invoke-Git -Args @('checkout', $Branch)
    }
}

function Push-Changes {
    if (-not $Branch -or $Branch -eq '') {
        Write-Log "ERROR: Branch name is empty, cannot push"
        throw "Branch name is empty"
    }
    Ensure-OnBranch
    Write-Log "Pushing changes to branch '$Branch'..."
    Invoke-Git -Args @('fetch', '--all', '--prune')
    Invoke-Git -Args @('pull', '--rebase', '--autostash', 'origin', $Branch)
    Invoke-Git -Args @('push', 'origin', $Branch)
    Write-Log "Push completed successfully"
}

Set-Location -LiteralPath $RepoPath

$currentBranch = & $GitPath rev-parse --abbrev-ref HEAD
if ($currentBranch -ne $Branch) {
    Write-Log "Switching from '$currentBranch' to '$Branch'..."
    Invoke-Git -Args @('checkout', $Branch)
}

Write-Log "Starting auto-commit/push loop on branch '$Branch' (commit: ${CommitIntervalSeconds}s, push: ${PushIntervalMinutes}m)"

if ($DryRun) {
    Write-Log "DryRun enabled; exiting"
    exit 0
}

$lastPush = [DateTime]::MinValue
$pushInterval = New-TimeSpan -Minutes $PushIntervalMinutes

while ($true) {
    try {
        $now = Get-Date
        
        Commit-Changes
        
        if ($now - $lastPush -ge $pushInterval) {
            Push-Changes
            $lastPush = $now
        }
    }
    catch {
        Write-Log "LOOP ERROR: $($_.Exception.Message)"
    }
    
    Start-Sleep -Seconds $CommitIntervalSeconds
}