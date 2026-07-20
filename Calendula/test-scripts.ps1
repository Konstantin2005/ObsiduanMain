# Test both scripts for 1 hour
$startTime = Get-Date
$endTime = $startTime.AddHours(1)
$interval = 5  # minutes between runs

Write-Host "=== Starting 1-hour monitoring test ==="
Write-Host "Start time: $startTime"
Write-Host "End time: $endTime"
Write-Host "Interval: $interval minutes"
Write-Host ""

while ((Get-Date) -lt $endTime) {
    $currentTime = Get-Date
    Write-Host "[$currentTime] Running git-monitor.ps1..."
    powershell -ExecutionPolicy Bypass -File "C:\obsidian\Main\Calendula\git-monitor.ps1" 2>&1 | Select-Object -First 10
    
    Write-Host "[$currentTime] Running git-automation-monitor.ps1..."
    powershell -ExecutionPolicy Bypass -File "C:\obsidian\Main\Calendula\git-automation-monitor.ps1" 2>&1 | Select-Object -First 10
    
    Write-Host ""
    Start-Sleep -Seconds ($interval * 60)
}

Write-Host "=== 1-hour test completed ==="
Write-Host "End time: $(Get-Date)"