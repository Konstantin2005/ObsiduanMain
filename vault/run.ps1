#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script runner with automatic logging for the vault.
.DESCRIPTION
    Runs any script and logs: timestamp, script name, branch, exit code, duration, output.
    Logs to vault/log/script-history.md and vault/log/script/<name>.log
.PARAMETER ScriptPath
    Path to the script to run.
.PARAMETER Args
    Arguments to pass to the script.
.EXAMPLE
    .\vault\run.ps1 .\Technical\Scripts\Git\daily-push.ps1
    .\vault\run.ps1 .\Zetl\generate_projects.py --output ./docs
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$VaultRoot = Split-Path -Parent $PSScriptRoot
$LogDir = Join-Path (Join-Path $PSScriptRoot "log") "script"
$HistoryLog = Join-Path (Join-Path $PSScriptRoot "log") "script-history.md"
$ScriptName = Split-Path $ScriptPath -Leaf
$ScriptLog = Join-Path $LogDir "$ScriptName.log"

# Ensure log dir exists
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# Get current git info
$Branch = & git -C $VaultRoot rev-parse --abbrev-ref HEAD 2>$null
if (-not $Branch) { $Branch = "unknown" }

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$StartTime = Get-Date

# Ensure history file exists
if (-not (Test-Path $HistoryLog)) {
    @"
# Script History

| Date | Script | Branch | Exit | Duration | Output |
|------|--------|--------|------|----------|--------|
"@ | Set-Content $HistoryLog
}

Write-Host "=== Running $ScriptName on $Branch ===" -ForegroundColor Cyan

# Run the script
$Output = ""
try {
    $Output = & $ScriptPath @Args 2>&1
    $ExitCode = $LASTEXITCODE
    if ($null -eq $ExitCode) { $ExitCode = 0 }
}
catch {
    $Output = $_.Exception.Message
    $ExitCode = 1
}

$Duration = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)

# Truncate output for log (first 3 lines + last line)
$OutputLines = $Output -split "`n" | Where-Object { $_ -ne "" }
if ($OutputLines.Count -gt 5) {
    $ShortOutput = ($OutputLines[0..2] -join "; ") + "; ...; " + $OutputLines[-1]
}
else {
    $ShortOutput = $OutputLines -join "; "
}
if ($ShortOutput.Length -gt 200) { $ShortOutput = $ShortOutput.Substring(0, 200) + "..." }

# Log to history
$LogLine = "| $Timestamp | $ScriptName | $Branch | $ExitCode | ${Duration}s | $ShortOutput |"
Add-Content $HistoryLog $LogLine

# Log to per-script file
"[$Timestamp] branch=$Branch exit=$ExitCode duration=${Duration}s args=($Args)" | Add-Content $ScriptLog
$Output | ForEach-Object { "  $_" } | Add-Content $ScriptLog
"" | Add-Content $ScriptLog

# Also log to vault activity log
$ActivityLog = Join-Path (Join-Path $PSScriptRoot "log") "activity.md"
if (Test-Path $ActivityLog) {
    $ActivityLine = "- [$ScriptName] $ShortOutput (exit: $ExitCode, ${Duration}s)"
    Add-Content $ActivityLog $ActivityLine
}

$StatusColor = if ($ExitCode -eq 0) { "Green" } else { "Red" }
Write-Host "=== $ScriptName finished: exit=$ExitCode duration=${Duration}s ===" -ForegroundColor $StatusColor

exit $ExitCode
