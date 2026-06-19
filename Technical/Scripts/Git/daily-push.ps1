param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$Branch = "",
    [string]$GitPath = "git",
    [string]$LogPath = (Join-Path $RepoPath "Technical\Scripts\Logs\daily-push.log"),
    [int]$CommitIntervalSeconds = 5,
    [int]$PushIntervalMinutes = 15,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

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
    $output = & $GitPath @Args 2>&1
    $code = $LASTEXITCODE
    if ($output) { $output | ForEach-Object { Write-Log "$($_)" } }
    if ($code -ne 0) { throw "git $($Args -join ' ') failed with code $code" }
}

function Test-HasChanges {
    $status = & $GitPath status --porcelain 2>&1
    return $status -ne ""
}

function Commit-Changes {
    if (-not (Test-HasChanges)) {
        Write-Log "No changes to commit"
        return
    }
    Write-Log "Committing changes..."
    Invoke-Git -Args @('add', '-A')
    $msg = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Invoke-Git -Args @('commit', '-m', $msg)
    Write-Log "Commit completed"
}

function Push-Changes {
    Write-Log "Pushing changes..."
    Invoke-Git -Args @('fetch', '--all', '--prune')
    Invoke-Git -Args @('pull', '--rebase', '--autostash', 'origin', $Branch)
    Invoke-Git -Args @('push', 'origin', $Branch)
    Write-Log "Push completed successfully"
}

Set-Location -LiteralPath $RepoPath

if (-not $Branch) {
    $Branch = & $GitPath rev-parse --abbrev-ref HEAD
    if (-not $Branch -or $Branch -eq 'HEAD') { throw "Could not detect current branch" }
    Write-Log "Auto-detected branch: $Branch"
}

Write-Log "Starting auto-commit/push loop on branch '$Branch' (commit: ${CommitIntervalSeconds}s, push: ${PushIntervalMinutes}m)"

if ($DryRun) {
    Write-Log "DryRun enabled; exiting"
    exit 0
}

$lastPush = [DateTime]::MinValue
$pushInterval = New-TimeSpan -Minutes $PushIntervalMinutes

try {
    while ($true) {
        $now = Get-Date
        
        Commit-Changes
        
        if ($now - $lastPush -ge $pushInterval) {
            Push-Changes
            $lastPush = $now
        }
        
        Start-Sleep -Seconds $CommitIntervalSeconds
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}