param(
    [string]$RepoPath = "C:\obsidian\Main"
)

Set-Location $RepoPath

$logPath = Join-Path $RepoPath "hourly-git.log"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

Write-Log "Starting hourly sync..."

$syncScript = Join-Path $RepoPath "sync_leetcode.ps1"
if (Test-Path $syncScript) {
    Write-Log "Running sync_leetcode.ps1..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $syncScript 2>&1 | Out-Null
    Write-Log "sync_leetcode.ps1 finished"
}

$mentionsScript = Join-Path $RepoPath "collect-mentions.ps1"
if (Test-Path $mentionsScript) {
    Write-Log "Running collect-mentions.ps1..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $mentionsScript 2>&1 | Out-Null
    Write-Log "collect-mentions.ps1 finished"
}

$changes = git status --porcelain
if (-not $changes) {
    Write-Log "No changes found. Nothing to commit."
    exit 0
}

$date = Get-Date -Format "yyyy-MM-dd HH:mm"
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

Write-Log "Committed: $date"
exit 0
