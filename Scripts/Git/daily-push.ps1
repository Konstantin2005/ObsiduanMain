param(
    [string]$RepoPath = "C:\obsidian\Main"
)

Set-Location $RepoPath

$logPath = Join-Path $RepoPath "Scripts\Logs\daily-push.log"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

Write-Log "Starting daily push..."

git fetch --all --prune 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Log "git fetch failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

git pull --no-rebase --autostash -X ours origin main 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Log "git pull failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

git push
if ($LASTEXITCODE -ne 0) {
    Write-Log "git push failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Log "Push completed successfully."
exit 0
