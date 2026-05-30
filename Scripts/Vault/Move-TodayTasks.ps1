param(
    [Parameter(Mandatory=$false)]
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [Parameter(Mandatory=$false)]
    [string]$KanbanDir = "C:\obsidian\Main\Calendula\План"
)

$ErrorActionPreference = "Stop"

$year = [int]::Parse($Date.Substring(0, 4))
$month = [int]::Parse($Date.Substring(5, 2))

$monthName = switch ($month) {
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

$filePath = Resolve-Path "$KanbanDir\$year\$year - $monthName.md" -ErrorAction SilentlyContinue
if (-not $filePath) {
    Write-Host "File not found: $KanbanDir\$year\$year - $monthName.md"
    exit 1
}

$lines = Get-Content $filePath -Encoding UTF8
$todayTag = "@{$Date}"

# Find sections by tracking heading positions
$zaplanirovanoStart = $null
$zaplanirovanoEnd = $null
$segodnyaStart = $null
$segodnyaEnd = $null

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Запланировано$") { $zaplanirovanoStart = $i; continue }
    if ($lines[$i] -match "^## Сегодня$") { $segodnyaStart = $i; continue }
    if ($lines[$i] -match "^## " -and $zaplanirovanoStart -ne $null -and $zaplanirovanoEnd -eq $null -and $i -gt $zaplanirovanoStart) { $zaplanirovanoEnd = $i }
    if ($lines[$i] -match "^## " -and $segodnyaStart -ne $null -and $segodnyaEnd -eq $null -and $i -gt $segodnyaStart) { $segodnyaEnd = $i }
}

if ($zaplanirovanoStart -eq $null) {
    Write-Host "Section 'Запланировано' not found in $filePath"
    exit 0
}
if ($segodnyaStart -eq $null) {
    Write-Host "Section 'Сегодня' not found in $filePath"
    exit 0
}
if ($zaplanirovanoEnd -eq $null) { $zaplanirovanoEnd = $lines.Count }
if ($segodnyaEnd -eq $null) { $segodnyaEnd = $lines.Count }

# Get lines in Запланировано section (after heading, before next heading)
$zaplSection = $lines[($zaplanirovanoStart + 1)..($zaplanirovanoEnd - 1)]
$segodnyaSection = $lines[($segodnyaStart + 1)..($segodnyaEnd - 1)]

# Find task lines with today's date
$tasksToMove = @()
$remainingLines = @()
foreach ($line in $zaplSection) {
    if ($line.Trim() -match "^- \[.?\] .*" + [regex]::Escape($todayTag)) {
        $tasksToMove += $line
    } else {
        $remainingLines += $line
    }
}

if ($tasksToMove.Count -eq 0) {
    Write-Host "No tasks with date $Date found in 'Запланировано'"
    exit 0
}

# Strip leading empty lines from remaining section (we add our own blank line after heading)
while ($remainingLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($remainingLines[0])) {
    $remainingLines = $remainingLines[1..$($remainingLines.Count - 1)]
}
$newZaplSection = ($remainingLines -join "`r`n").TrimEnd()

# Build new Сегодня section content
$tasksBlock = $tasksToMove -join "`r`n"
$hasContent = ($segodnyaSection | Where-Object { $_.Trim() -ne "" }).Count -gt 0
if ($hasContent) {
    $newSegodnyaSection = (($segodnyaSection -join "`r`n").TrimEnd() + "`r`n" + $tasksBlock).TrimEnd()
} else {
    $newSegodnyaSection = $tasksBlock
}

# Build the output
$output = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -eq $zaplanirovanoStart) {
        $output += "## Запланировано"
        $output += ""
        $sectionLines = ($newZaplSection.TrimEnd() -split "`r`n")
        $output += $sectionLines
        if ($sectionLines.Count -gt 0 -and $sectionLines[-1] -ne "") { $output += "" }
        $i = $zaplanirovanoEnd - 1
    } elseif ($i -eq $segodnyaStart) {
        $output += "## Сегодня"
        $sectionLines = ($newSegodnyaSection.TrimEnd() -split "`r`n")
        $output += $sectionLines
        if ($sectionLines.Count -gt 0 -and $sectionLines[-1] -ne "") { $output += "" }
        $i = $segodnyaEnd - 1
    } else {
        $output += $lines[$i]
    }
}

# Preserve trailing newline
$rawContent = Get-Content $filePath -Raw -Encoding UTF8
$trailingNewline = ""
if ($rawContent.EndsWith("`r`n")) { $trailingNewline = "`r`n" }
elseif ($rawContent.EndsWith("`n")) { $trailingNewline = "`n" }

$newContent = ($output -join "`r`n").TrimEnd() + $trailingNewline
[System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "Moved $($tasksToMove.Count) task(s) from 'Запланировано' to 'Сегодня'"
foreach ($task in $tasksToMove) {
    Write-Host "  $($task.Trim())"
}
