param(
    [Parameter(Mandatory=$false)]
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [Parameter(Mandatory=$false)]
    [string]$KanbanDir = "C:\obsidian\Main\Calendula\План",
    [switch]$DryRun,
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

function Get-MonthName {
    param([int]$Month)
    switch ($Month) {
        1 { "Январь" }
        2 { "Февраль" }
        3 { "Март" }
        4 { "Апрель" }
        5 { "Май" }
        6 { "Июнь" }
        7 { "Июль" }
        8 { "Август" }
        9 { "Сентябрь" }
        10 { "Октябрь" }
        11 { "Ноябрь" }
        12 { "Декабрь" }
    }
}

function Get-SectionRange {
    param([string[]]$Lines, [string]$Heading)
    $start = $null
    $end = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^## $([regex]::Escape($Heading))$") { $start = $i; continue }
        if ($start -ne $null -and $end -eq $null -and $Lines[$i] -match "^## " -and $i -gt $start) { $end = $i; break }
    }
    if ($start -eq $null) { return $null }
    if ($end -eq $null) { $end = $Lines.Count }
    return ,@($start, $end)
}

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

$rawContent = Get-Content -LiteralPath $filePath -Raw -Encoding UTF8
$lines = $rawContent -split "`r?`n"
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

$trailingNewline = if ($rawContent.EndsWith("`r`n")) { "`r`n" } elseif ($rawContent.EndsWith("`n")) { "`n" } else { "" }
$newContent = ($output -join "`r`n").TrimEnd() + $trailingNewline
if (-not $DryRun) {
    [System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.UTF8Encoding]::new($false))
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
