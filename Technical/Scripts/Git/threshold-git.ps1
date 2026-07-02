param(
    [string]$RepoPath = "C:\obsidian\Main"
)

Set-Location $RepoPath

$logPath = Join-Path $RepoPath "Technical\Scripts\Logs\threshold-git.log"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Split-Path -Parent $logPath
    if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

Write-Log "Starting threshold commit loop..."

git fetch --all --prune | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Log "git fetch failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

$status = git status --porcelain
if ($LASTEXITCODE -ne 0) {
    Write-Log "git status --porcelain failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

$changes = $status
if (-not $changes) {
    Write-Log "No changes found. Nothing to do."
    exit 0
}

$date = Get-Date -Format "yyyy-MM-dd"

git add -A
if ($LASTEXITCODE -ne 0) {
    Write-Log "git add -A failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

git commit -m $date
if ($LASTEXITCODE -ne 0) {
    Write-Log "git commit failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

git push
if ($LASTEXITCODE -ne 0) {
    Write-Log "git push failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Log "Success. Commit: $date. Push completed."
exit 0