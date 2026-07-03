# health-monitor.ps1 - Runs every 5 minutes via Task Scheduler

param([switch]$ReportOnly)

# Hide window
try {
    $t = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindow -Namespace Win32 -PassThru
    $t::ShowWindow((Get-Process -Id $pid).MainWindowHandle, 0) | Out-Null
} catch {}

. (Join-Path $PSScriptRoot "core.ps1")

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$repos = @(
    @{ Path = $script:CONFIG.RepoPath; Name = "vault"; Branch = "main" },
    @{ Path = $script:CONFIG.RepoPath2; Name = "parent"; Branch = "master" }
)

$globalHealth = @{ Status = "OK"; Issues = @() }

foreach ($repo in $repos) {
    $path = $repo.Path
    $name = $repo.Name
    $branch = $repo.Branch
    
    Write-Log "Health check: $name ($path)" "MONITOR"
    
    if (-not (Test-Path "$path\.git")) {
        Write-Log "CRITICAL: ${name} - .git not found!" "MONITOR"
        $globalHealth.Status = "CRITICAL"
        $globalHealth.Issues += "${name}: .git not found"
        continue
    }
    
    $checks = Test-All -RepoPath $path
    
    foreach ($check in $checks.Keys) {
        if ($check -eq "AllOk") { continue }
        $result = $checks[$check]
        if ($result.Status -ne "OK") {
            $issueKey = "${name}/${check}: $($result.Message)"
            Write-Log "$issueKey" "MONITOR"
            $globalHealth.Issues += $issueKey
            if ($result.Status -eq "FAIL") { $globalHealth.Status = "ERROR" }
            if ($result.Status -eq "STALE") { 
                $globalHealth.Status = "WARN"
                if (-not $ReportOnly) {
                    Write-Log "Triggering self-heal for ${name}/${check}..." "MONITOR"
                    switch ($check) {
                        "Lock" { Repair-LockFile -RepoPath $path | Out-Null }
                        "Rebase" { Repair-Rebase -RepoPath $path | Out-Null }
                    }
                }
            }
        }
    }
    
    # Check ahead count and push if needed
    $ahead = Get-AheadCount -RepoPath $path -Branch $branch
    if ($ahead -gt 0 -and $ahead -le $script:CONFIG.MaxAheadPush) {
        Write-Log "${name} is ${ahead} ahead - can push" "MONITOR"
        if (-not $ReportOnly) {
            $pushResult = Invoke-Push -RepoPath $path -Branch $branch
            if ($pushResult) { Write-Log "${name} push initiated" "MONITOR" }
        }
    } elseif ($ahead -gt $script:CONFIG.MaxAheadPush) {
        Write-Log "${name} is ${ahead} ahead - skip push" "MONITOR"
    }
}

# Write health status file
$healthFile = Join-Path $script:CONFIG.SystemDir "health-status.json"
$healthData = @{
    Timestamp = $timestamp
    Status = $globalHealth.Status
    Issues = $globalHealth.Issues
} | ConvertTo-Json
Set-Content -Path $healthFile -Value $healthData -Encoding UTF8

Write-Log "Health monitor complete. Status: $($globalHealth.Status)" "MONITOR"

if ($globalHealth.Status -eq "CRITICAL") { exit 2 }
if ($globalHealth.Status -eq "ERROR") { exit 1 }
exit 0
