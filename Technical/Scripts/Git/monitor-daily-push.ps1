param(
    [string]$LogPath = "C:\obsidian\Main\Technical\Scripts\Logs\daily-push.log",
    [int]$CheckIntervalSeconds = 10,
    [int]$DurationMinutes = 10
)

$ErrorActionPreference = 'Stop'

function Write-MonitorLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [MONITOR] $Message"
}

Write-MonitorLog "Starting monitor for $LogPath"
Write-MonitorLog "Check interval: ${CheckIntervalSeconds}s, Duration: ${DurationMinutes}m"

$endTime = (Get-Date).AddMinutes($DurationMinutes)
$lastCommitTime = $null
$lastPushTime = $null
$commitCount = 0
$pushCount = 0

while ((Get-Date) -lt $endTime) {
    if (Test-Path $LogPath) {
        $lines = Get-Content $LogPath -Tail 20 -ErrorAction SilentlyContinue
        
        foreach ($line in $lines) {
            if ($line -match 'Auto-commit: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
                $time = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                if (-not $lastCommitTime -or $time -gt $lastCommitTime) {
                    $lastCommitTime = $time
                    $commitCount++
                    Write-MonitorLog "COMMIT #$commitCount at $time"
                }
            }
            
            if ($line -match 'Push completed successfully') {
                $pushTime = Get-Date
                if (-not $lastPushTime -or $pushTime -gt $lastPushTime) {
                    $lastPushTime = $pushTime
                    $pushCount++
                    Write-MonitorLog "PUSH #$pushCount at $pushTime"
                }
            }
            
            if ($line -match 'Pushing changes to branch') {
                $pushStart = Get-Date
                Write-MonitorLog "PUSH STARTED at $pushStart"
            }
        }
    }
    
    $status = Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*daily-push*" }
    if ($status) {
        Write-MonitorLog "SCRIPT RUNNING (PID: $($status.Id))"
    } else {
        Write-MonitorLog "SCRIPT NOT RUNNING - RESTARTING..."
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass", "-File", "C:\obsidian\Main\Technical\Scripts\Git\daily-push.ps1", "-CommitIntervalSeconds", "5", "-PushIntervalMinutes", "5"
        Write-MonitorLog "SCRIPT RESTARTED"
    }
    
    Start-Sleep -Seconds $CheckIntervalSeconds
}

Write-MonitorLog "=== MONITOR SUMMARY ==="
Write-MonitorLog "Total commits: $commitCount"
Write-MonitorLog "Total pushes: $pushCount"
Write-MonitorLog "Last commit: $lastCommitTime"
Write-MonitorLog "Last push: $lastPushTime"

if ($lastCommitTime -and $lastPushTime) {
    $commitFreq = (New-TimeSpan -Start $lastCommitTime -End (Get-Date)).TotalMinutes
    $pushFreq = (New-TimeSpan -Start $lastPushTime -End (Get-Date)).TotalMinutes
    Write-MonitorLog "Minutes since last commit: $([math]::Round($commitFreq, 1))"
    Write-MonitorLog "Minutes since last push: $([math]::Round($pushFreq, 1))"
}