<#
.SYNOPSIS
    Creates a git tag snapshot every 6 hours. Self-logging.
    Runs via Windows Task Scheduler.
.EXAMPLE
    .\vault\snapshot.ps1
    .\vault\snapshot.ps1 -RetentionDays 90
#>

param(
    [int]$RetentionDays = 90
)

$StartTime = Get-Date
$VaultRoot = Split-Path -Parent $PSScriptRoot
$Branch = & git -C $VaultRoot rev-parse --abbrev-ref HEAD 2>$null
if (-not $Branch) { $Branch = "unknown" }

# Log system
$LogDir = Join-Path (Join-Path $VaultRoot "vault\log") "script"
$HistoryLog = Join-Path (Join-Path $VaultRoot "vault\log") "script-history.md"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
if (-not (Test-Path $HistoryLog)) {
    "# Script History`n`n| Date | Script | Branch | Exit | Duration | Output |" | Set-Content $HistoryLog
}
$ScriptName = "snapshot.ps1"
$ScriptLog = Join-Path $LogDir $ScriptName
$Output = ""

function Write-Log {
    param([int]$ExitCode)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $dur = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)
    $line = "| $ts | $ScriptName | $Branch | $ExitCode | ${dur}s | $Output |"
    Add-Content $HistoryLog $line
    "[$ts] branch=$Branch exit=$ExitCode duration=${dur}s" | Add-Content $ScriptLog
    exit $ExitCode
}

Set-Location $VaultRoot
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$TagName = "snapshot-$Timestamp"

# Create tag
git tag -a $TagName -m "Snapshot $Timestamp" 2>&1
if ($LASTEXITCODE -eq 0) {
    git push origin $TagName 2>&1
    $Output = "Created: $TagName"
    Write-Host "[snapshot] $Output"
}
else {
    $Output = "Failed to create tag"
    Write-Host "[snapshot] $Output"
    Write-Log 1
}

# Prune old snapshots (older than retention days)
$Cutoff = (Get-Date).AddDays(-$RetentionDays)
$OldTags = & git tag -l "snapshot-*" --sort=-creatordate 2>$null
foreach ($tag in $OldTags) {
    $tagDateStr = $tag -replace "snapshot-", ""
    $tagDateStr = $tagDateStr.Substring(0, 10)
    try {
        $tagDate = [DateTime]::ParseExact($tagDateStr, "yyyy-MM-dd", $null)
        if ($tagDate -lt $Cutoff) {
            git tag -d $tag 2>&1
            git push origin --delete $tag 2>&1
            Write-Host "[snapshot] Pruned: $tag"
        }
    }
    catch {
        Write-Host "[snapshot] Skipping (parse error): $tag"
    }
}

Write-Log 0
