param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$Branch = "main",
    [string]$GitPath = "git",
    [string]$LogPath = (Join-Path $RepoPath "Technical\Scripts\Logs\hourly-git.log"),
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
    param([Parameter(Mandatory = $true)][string[]]$Args)

    $output = & $GitPath @Args 2>&1
    $code = $LASTEXITCODE
    if ($output) {
        $output | ForEach-Object { Write-Log "$($_)" }
    }
    if ($code -ne 0) {
        throw "git $($Args -join ' ') failed with code $code"
    }
    return @($output)
}

Set-Location -LiteralPath $RepoPath
Write-Log "Starting hourly auto-push for branch '$Branch'"

if ($DryRun) {
    Write-Log "DryRun enabled; skipping git commands"
    exit 0
}

$commitTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Invoke-Git -Args @('fetch', '--all', '--prune') | Out-Null
Invoke-Git -Args @('add', '-A') | Out-Null

$changes = @(Invoke-Git -Args @('status', '--porcelain'))
if ($changes.Count -gt 0) {
    Invoke-Git -Args @('commit', '-m', "hourly sync: $commitTimestamp") | Out-Null
    Write-Log "Committed hourly changes: $commitTimestamp"
} else {
    Write-Log "No local changes to commit."
}

Invoke-Git -Args @('pull', '--no-rebase', '--autostash', '-X', 'ours', 'origin', $Branch) | Out-Null
Invoke-Git -Args @('push', 'origin', $Branch) | Out-Null

Write-Log "Hourly auto-push completed successfully."
exit 0
