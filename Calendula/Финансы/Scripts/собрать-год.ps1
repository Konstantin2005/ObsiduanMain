param(
    [string]$SourceDir = (Join-Path $PSScriptRoot '..\Days'),
    [string]$OutputFile = (Join-Path $PSScriptRoot '..\Summaries\finance-year.md')
)

$ErrorActionPreference = 'Stop'

function Parse-DayFile {
    param([string]$Path)

    $date = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $lines = Get-Content -LiteralPath $Path
    $section = $null
    $housing = 0.0
    $food = 0.0

    foreach ($line in $lines) {
        if ($line -match '^##\s*Жил[ьеё]') {
            $section = 'housing'
            continue
        }
        if ($line -match '^##\s*Еда') {
            $section = 'food'
            continue
        }
        if ($line -match '^##\s*') {
            $section = $null
            continue
        }

        if ($line -match '^\s*-\s*[^:]+:\s*([0-9]+(?:[.,][0-9]+)?)\s*$') {
            $value = [double]::Parse($Matches[1].Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
            if ($section -eq 'housing') { $housing += $value }
            elseif ($section -eq 'food') { $food += $value }
        }
    }

    [pscustomobject]@{
        Date = $date
        Housing = [math]::Round($housing, 2)
        Food = [math]::Round($food, 2)
        Total = [math]::Round($housing + $food, 2)
    }
}

New-Item -ItemType Directory -Path (Split-Path -Parent $OutputFile) -Force | Out-Null

$files = Get-ChildItem -LiteralPath $SourceDir -Filter '*.md' -File | Sort-Object Name
$rows = foreach ($file in $files) { Parse-DayFile -Path $file.FullName }

$yearHousing = ($rows | Measure-Object Housing -Sum).Sum
$yearFood = ($rows | Measure-Object Food -Sum).Sum
$yearTotal = ($rows | Measure-Object Total -Sum).Sum

$monthRows = $rows | Group-Object { $_.Date.Substring(0, 7) } | ForEach-Object {
    $items = $_.Group
    [pscustomobject]@{
        Month = $_.Name
        Housing = [math]::Round(($items | Measure-Object Housing -Sum).Sum, 2)
        Food = [math]::Round(($items | Measure-Object Food -Sum).Sum, 2)
        Total = [math]::Round(($items | Measure-Object Total -Sum).Sum, 2)
    }
}

$lines = @()
$lines += '# Годовой финансовый отчёт'
$lines += ''
$lines += "- Источник: ``$SourceDir``"
$lines += "- Файлов обработано: $($rows.Count)"
$lines += ("- Жильё за год: {0:N2} ₽" -f $yearHousing)
$lines += ("- Еда за год: {0:N2} ₽" -f $yearFood)
$lines += ("- Всего за год: {0:N2} ₽" -f $yearTotal)
$lines += ''
$lines += '## По месяцам'
$lines += ''
$lines += '| Месяц | Жильё | Еда | Всего |'
$lines += '|---|---:|---:|---:|'
foreach ($m in $monthRows) {
    $lines += ('| {0} | {1:N2} ₽ | {2:N2} ₽ | {3:N2} ₽ |' -f $m.Month, $m.Housing, $m.Food, $m.Total)
}

$lines += ''
$lines += '## По дням'
$lines += ''
$lines += '| Дата | Жильё | Еда | Всего |'
$lines += '|---|---:|---:|---:|'
foreach ($row in $rows) {
    $lines += ('| {0} | {1:N2} ₽ | {2:N2} ₽ | {3:N2} ₽ |' -f $row.Date, $row.Housing, $row.Food, $row.Total)
}

$lines | Set-Content -LiteralPath $OutputFile -Encoding utf8
Write-Host "Saved summary to $OutputFile"
