param(
    [datetime]$StartDate = [datetime]'2026-06-08',
    [int]$Days = 365,
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\Days')
)

$ErrorActionPreference = 'Stop'

function New-DayContent {
    param([datetime]$Date)

    $dateText = $Date.ToString('yyyy-MM-dd')
    return @"
---
date: $dateText
kind: finance-daily
---

# $dateText

> Заполняй только числа после двоеточий. Скрипт соберёт итог сам.

## Жильё
- Аренда: 0
- Коммуналка: 0
- Ремонт: 0
- Прочее: 0

## Еда
- Продукты: 0
- Кафе: 0
- Доставка: 0
- Прочее: 0

## Комментарий
- Что было: 
"@
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

for ($i = 0; $i -lt $Days; $i++) {
    $date = $StartDate.AddDays($i)
    $fileName = $date.ToString('yyyy-MM-dd') + '.md'
    $filePath = Join-Path $OutputDir $fileName

    if (-not (Test-Path -LiteralPath $filePath)) {
        Set-Content -LiteralPath $filePath -Value (New-DayContent -Date $date) -Encoding utf8
    }
}

Write-Host "Created or preserved $Days daily files in $OutputDir"
