param(
    [Parameter(Mandatory=$false)]
    [string]$KanbanDir = "C:\obsidian\Main\Calendula\План",
    [switch]$DryRun,
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot 'VaultHelpers.ps1')

if (-not (Test-Path -LiteralPath $KanbanDir)) {
    throw "Kanban path not found: $KanbanDir"
}

$monthNames = @{
    "Январь" = 1; "Февраль" = 2; "Март" = 3; "Апрель" = 4
    "Май" = 5; "Июнь" = 6; "Июль" = 7; "Август" = 8
    "Сентябрь" = 9; "Октябрь" = 10; "Ноябрь" = 11; "Декабрь" = 12
}
$numToName = @{}
foreach ($kv in $monthNames.GetEnumerator()) { $numToName[$kv.Value] = $kv.Key }

$fileRegex = '^(\d{4}) - (\w+)\.md$'
$dateRegex = '@\{(\d{4})-(\d{2})-(\d{2})\}'

$moves = @{}  # source_path -> @{task=..., targetYear=..., targetMonth=...}

$yearDirs = Get-ChildItem -LiteralPath $KanbanDir -Directory | Sort-Object Name

foreach ($yearDir in $yearDirs) {
    $files = Get-ChildItem -LiteralPath $yearDir.FullName -Filter "*.md"
    foreach ($file in $files) {
        if ($file.Name -notmatch $fileRegex) { continue }
        $fileYear = [int]$Matches[1]
        $fileMonthName = $Matches[2]
        if (-not $monthNames.ContainsKey($fileMonthName)) { continue }
        $fileMonth = $monthNames[$fileMonthName]

        $lines = Get-Content -LiteralPath $file.FullName -Encoding UTF8
        $modified = $false
        $newLines = @()
        $fileMoves = @()

        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match $dateRegex) {
                $taskYear = [int]$Matches[1]
                $taskMonth = [int]$Matches[2]
                if ($taskYear -ne $fileYear -or $taskMonth -ne $fileMonth) {
                    $fileMoves += @{ task = $line; targetYear = $taskYear; targetMonth = $taskMonth }
                    $modified = $true
                    continue
                }
            }
            $newLines += $line
        }

        if ($modified) {
            $newContent = ($newLines -join "`r`n").TrimEnd() + "`r`n"
            if (-not $DryRun) {
                Write-Utf8Text -Path $file.FullName -Content $newContent
            }
            $moves[$file.FullName] = $fileMoves
        }
    }
}

if ($moves.Count -eq 0) {
    Write-Host "All tasks are in their correct month boards."
    if ($PassThru) {
        [pscustomobject]@{
            TotalMoved = 0
            MoveDetails = @()
            DryRun = [bool]$DryRun
        }
    }
    exit 0
}

$total = 0
$incoming = @{}
$moveDetails = @()

foreach ($sourcePath in $moves.Keys) {
    foreach ($move in $moves[$sourcePath]) {
        $targetDir = Join-Path $KanbanDir "$($move.targetYear)"
        if (-not (Test-Path -LiteralPath $targetDir)) { continue }
        $targetName = "$($move.targetYear) - $($numToName[$move.targetMonth]).md"
        $targetPath = Join-Path $targetDir $targetName
        if (-not (Test-Path -LiteralPath $targetPath)) { continue }

        if (-not $incoming.ContainsKey($targetPath)) { $incoming[$targetPath] = @() }
        $incoming[$targetPath] += $move.task
        $total++
        $moveDetails += @{ source = $sourcePath; target = $targetPath; task = $move.task.Trim() }
    }
}

function Strip-Blank {
    param($arr)
    while ($arr.Count -gt 0 -and [string]::IsNullOrWhiteSpace($arr[0])) {
        if ($arr.Count -eq 1) { return @() }
        $arr = $arr[1..($arr.Count - 1)]
    }
    while ($arr.Count -gt 0 -and [string]::IsNullOrWhiteSpace($arr[-1])) {
        if ($arr.Count -eq 1) { return @() }
        $arr = $arr[0..($arr.Count - 2)]
    }
    return $arr
}

foreach ($targetPath in $incoming.Keys) {
    $tasks = $incoming[$targetPath] | Sort-Object -Unique
    $content = Get-Content -LiteralPath $targetPath -Encoding UTF8
    $newContent = @()
    $appended = $false

    $i = 0
    while ($i -lt $content.Count) {
        $line = $content[$i]
        if ($line -match "^## Запланировано$") {
            $newContent += $line
            $newContent += ""

            $j = $i + 1
            $sectionLines = @()
            while ($j -lt $content.Count -and $content[$j] -notmatch "^## ") {
                $sectionLines += $content[$j]
                $j++
            }

            $cleanLines = Strip-Blank $sectionLines
            if ($cleanLines.Count -gt 0) {
                $newContent += $cleanLines
                $newContent += ""
            }
            $newContent += $tasks
            $newContent += ""

            $appended = $true
            $i = $j
        } else {
            $newContent += $line
            $i++
        }
    }

    if (-not $appended) {
        $newContent += ""
        $newContent += "## Запланировано"
        $newContent += ""
        $newContent += $tasks
        $newContent += ""
    }

    $out = ($newContent -join "`r`n").TrimEnd() + "`r`n"
    if (-not $DryRun) {
        Write-Utf8Text -Path $targetPath -Content $out
    }
}

Write-Host "Moved $total task(s) to their correct month boards:"
foreach ($md in $moveDetails) {
    $srcName = [System.IO.Path]::GetFileNameWithoutExtension($md.source)
    $tgtName = [System.IO.Path]::GetFileNameWithoutExtension($md.target)
    Write-Host "  $($md.task)"
    Write-Host "    $srcName -> $tgtName"
}

if ($PassThru) {
    [pscustomobject]@{
        TotalMoved = $total
        MoveDetails = $moveDetails
        DryRun = [bool]$DryRun
    }
}
