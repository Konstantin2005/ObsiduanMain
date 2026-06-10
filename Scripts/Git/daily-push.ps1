param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$Branch = "main",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$logPath = Join-Path $RepoPath "Scripts\Logs\daily-push.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $logPath -Value "[$timestamp] $Message"
}

function Invoke-Git {
    param([Parameter(Mandatory=$true)][string[]]$Args)
    $output = & git @Args 2>&1
    $code = $LASTEXITCODE
    if ($output) { $output | ForEach-Object { Write-Log "$($_)" } }
    if ($code -ne 0) { throw "git $($Args -join ' ') failed with code $code" }
}

Set-Location -LiteralPath $RepoPath
Write-Log "Starting daily push for branch '$Branch'"

if ($DryRun) {
    Write-Log "DryRun enabled; skipping git commands"
    exit 0
}

Invoke-Git -Args @('fetch', '--all', '--prune')
Invoke-Git -Args @('pull', '--no-rebase', '--autostash', '-X', 'ours', 'origin', $Branch)
Invoke-Git -Args @('push', 'origin', $Branch)

Write-Log "Push completed successfully."
exit 0
