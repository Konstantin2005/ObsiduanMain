param(
    [Parameter(Mandatory=$false)]
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [Parameter(Mandatory=$false)]
    [string]$KanbanDir = "C:\obsidian\Main\Calendula\План",
    [switch]$DryRun,
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot 'VaultHelpers.ps1')

if ($Date -notmatch '^\d{4}-\d{2}-\d{2}$') {
    throw "Invalid date format: $Date"
}

$year = [int]::Parse($Date.Substring(0, 4))
$month = [int]::Parse($Date.Substring(5, 2))
$monthName = Get-MonthName -Month $month
$filePath = Join-Path $KanbanDir "$year\$year - $monthName.md"

if (-not (Test-Path -LiteralPath $filePath)) {
    throw "File not found: $filePath"
}

$rawContent = Read-Utf8Text -Path $filePath
$lines = @((Split-Lines $rawContent))
$todayTag = "@{$Date}"

$zRange = Get-SectionRange -Lines $lines -Heading "Запланировано"
$sRange = Get-SectionRange -Lines $lines -Heading "Сегодня"
if ($null -eq $zRange -or $null -eq $sRange) {
    throw "Required sections not found in $filePath"
}

$zaplanirovanoStart, $zaplanirovanoEnd = $zRange
$segodnyaStart, $segodnyaEnd = $sRange

$zaplSection = $lines[($zaplanirovanoStart + 1)..($zaplanirovanoEnd - 1)]
$segodnyaSection = $lines[($segodnyaStart + 1)..($segodnyaEnd - 1)]

$tasksToMove = @()
$remainingLines = @()
foreach ($line in $zaplSection) {
    if ($line.Trim() -match ("^- \[[ xX]\] .*" + [regex]::Escape($todayTag) + "$")) {
        $tasksToMove += $line
    } else {
        $remainingLines += $line
    }
}

if ($tasksToMove.Count -eq 0) {
    Write-Host "No tasks with date $Date found in 'Запланировано'"
    exit 0
}

while ($remainingLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($remainingLines[0])) {
    $remainingLines = if ($remainingLines.Count -eq 1) { @() } else { $remainingLines[1..($remainingLines.Count - 1)] }
}

$newZaplSection = ($remainingLines -join "`r`n").TrimEnd()
$tasksBlock = $tasksToMove -join "`r`n"
$hasContent = ($segodnyaSection | Where-Object { $_.Trim() -ne "" }).Count -gt 0
if ($hasContent) {
    $newSegodnyaSection = (($segodnyaSection -join "`r`n").TrimEnd() + "`r`n" + $tasksBlock).TrimEnd()
} else {
    $newSegodnyaSection = $tasksBlock
}

$output = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -eq $zaplanirovanoStart) {
        $output += "## Запланировано"
        $output += ""
        $sectionLines = if ($newZaplSection) { $newZaplSection -split "`r?`n" } else { @() }
        $output += $sectionLines
        if ($sectionLines.Count -gt 0) { $output += "" }
        $i = $zaplanirovanoEnd - 1
    } elseif ($i -eq $segodnyaStart) {
        $output += "## Сегодня"
        $sectionLines = if ($newSegodnyaSection) { $newSegodnyaSection -split "`r?`n" } else { @() }
        $output += $sectionLines
        if ($sectionLines.Count -gt 0) { $output += "" }
        $i = $segodnyaEnd - 1
    } else {
        $output += $lines[$i]
    }
}

$trailingNewline = Get-TrailingNewline $rawContent
$newContent = ($output -join "`r`n").TrimEnd() + $trailingNewline
if (-not $DryRun) {
    Assert-SafeBulkOperation -Operation 'Move-TodayTasks write' -Root $KanbanDir -TargetPaths @($filePath) -DryRun:$DryRun
    Write-Utf8Text -Path $filePath -Content $newContent
}

Write-Host "Moved $($tasksToMove.Count) task(s) from 'Запланировано' to 'Сегодня'"
foreach ($task in $tasksToMove) { Write-Host "  $($task.Trim())" }

if ($PassThru) {
    [pscustomobject]@{
        FilePath = $filePath
        Date = $Date
        MovedCount = $tasksToMove.Count
        DryRun = [bool]$DryRun
        Tasks = @($tasksToMove)
    }
}
