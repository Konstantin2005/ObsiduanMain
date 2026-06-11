param(
    [string]$RepoPath = "C:\obsidian\Main",
    [int]$IntervalSeconds = 15
)

Set-Location $RepoPath

$logPath = Join-Path $RepoPath "Technical\Scripts\Logs\threshold-git.log"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

Write-Log "Starting threshold commit loop with ${IntervalSeconds}s interval..."

while ($true) {
    $status = git status --porcelain
    if ($LASTEXITCODE -ne 0) {
        Write-Log "git status --porcelain failed with code $LASTEXITCODE"
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    if (-not $status) {
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    git add -A
    if ($LASTEXITCODE -ne 0) {
        Write-Log "git add -A failed with code $LASTEXITCODE"
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    git commit -m $date
    if ($LASTEXITCODE -ne 0) {
        Write-Log "git commit failed with code $LASTEXITCODE"
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    Write-Log "Success. Commit: $date."

    Start-Sleep -Seconds $IntervalSeconds
}
