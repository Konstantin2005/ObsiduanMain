param(
    [int]$Year = 2026,
    [switch]$DryRun
)

<#
.SYNOPSIS
    Moves diary notes from Calendula/Calendula/YYYY/ to their category folders.

.DESCRIPTION
    This script moves filled (non-empty) daily notes into the corresponding
    graph folders, preserving the year/month/day directory structure:

    Личное (Personal)  -> Вечно зеленные действия/
    Соц (Social)       -> CRM/
    Мысли (Thoughts)   -> Маслины/

.PARAMETER Year
    Year to process (default: 2026)

.PARAMETER DryRun
    If set, only shows what would be moved without actually moving
#>

$BaseDir = "C:\obsidian\Main\Calendula"
$SourceYear = Join-Path $BaseDir "Calendula\$Year"

$Categories = @(
    @{ Name = "Личное"; Filter = "*Личное*";  Dest = Join-Path $BaseDir "Вечно зеленные действия\$Year" }
    @{ Name = "Соц";    Filter = "*Соц*";     Dest = Join-Path $BaseDir "CRM\$Year" }
    @{ Name = "Мысли";  Filter = "*Мысли*";   Dest = Join-Path $BaseDir "Маслины\$Year" }
)

if (-not (Test-Path $SourceYear)) {
    Write-Host "ERROR: Source not found: $SourceYear" -ForegroundColor Red
    exit 1
}

$totalMoved = 0
$totalSkipped = 0

foreach ($cat in $Categories) {
    Write-Host ("")
    Write-Host ("=== " + $cat.Name + " -> " + (Split-Path $cat.Dest -Leaf) + " ===") -ForegroundColor Cyan

    $files = Get-ChildItem -Path $SourceYear -Recurse -File | Where-Object {
        $_.Name -like $cat.Filter
    }

    $filled = $files | Where-Object { $_.Length -gt 0 }
    $empty  = $files | Where-Object { $_.Length -eq 0 }

    Write-Host ("  Total: " + $files.Count + " | Filled: " + $filled.Count + " | Empty (skip): " + $empty.Count)

    if ($DryRun) {
        foreach ($f in $filled) {
            $relPath = $f.FullName.Substring($SourceYear.Length + 1)
            Write-Host ("  [DRY] " + $relPath) -ForegroundColor Gray
        }
        continue
    }

    $moved = 0
    $errors = 0

    foreach ($f in $filled) {
        $relPath = $f.FullName.Substring($SourceYear.Length + 1)
        $destPath = Join-Path $cat.Dest $relPath
        $destDir = Split-Path $destPath -Parent

        if (-not (Test-Path $destDir)) {
            try {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            } catch {
                Write-Host ("  [ERR] Cannot create dir: " + $destDir) -ForegroundColor Red
                $errors++
                continue
            }
        }

        try {
            Move-Item -LiteralPath $f.FullName -Destination $destPath -Force
            Write-Host ("  [OK] " + $relPath) -ForegroundColor Green
            $moved++
        } catch {
            Write-Host ("  [ERR] " + $relPath + " : " + $_.Exception.Message) -ForegroundColor Red
            $errors++
        }
    }

    if ($errors -eq 0) {
        Write-Host ("  Result: " + $moved + " moved, " + $errors + " errors") -ForegroundColor Green
    } else {
        Write-Host ("  Result: " + $moved + " moved, " + $errors + " errors") -ForegroundColor Yellow
    }
    $totalMoved += $moved
    $totalSkipped += $empty.Count
}

Write-Host ("")
Write-Host ("========================================") -ForegroundColor Yellow
if ($DryRun) {
    Write-Host (" DRY-RUN COMPLETE (no files moved)") -ForegroundColor Gray
} else {
    Write-Host (" ALL DONE!") -ForegroundColor Yellow
}
Write-Host (" Total moved: " + $totalMoved) -ForegroundColor Green
Write-Host (" Total skipped (empty): " + $totalSkipped) -ForegroundColor Gray
Write-Host ("========================================") -ForegroundColor Yellow
