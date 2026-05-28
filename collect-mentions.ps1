<#
.SYNOPSIS
  Collects mentions of people from diary entries and appends them to person files.
.DESCRIPTION
  Scans all diary entries in Calendula/Calendula/ for mentions ([[Name]] or plain text)
  of people from Соц Капитал/. Extracts the full paragraph and appends it to the person's file.
  Skips paragraphs that are just a list of names with no real content.
#>

param([string]$VaultPath = "C:\obsidian\Main")

$diaryRoot = [System.IO.Path]::Combine($VaultPath, "Calendula", "Calendula")
$scPath = [System.IO.Path]::Combine($VaultPath, "Calendula", "Соц Капитал")

if (-not [System.IO.Directory]::Exists($diaryRoot)) {
    Write-Error "Diary path not found: $diaryRoot"
    exit 1
}
if (-not [System.IO.Directory]::Exists($scPath)) {
    Write-Error "Social capital path not found: $scPath"
    exit 1
}

$utf8 = [System.Text.UTF8Encoding]::new($false)

function IsMeaningfulParagraph($text) {
    $stripped = $text -replace '\[\[.*?\]\]', ''
    $stripped = $stripped -replace '[#*>_\-\[\]()]', ''
    $stripped = $stripped.Trim()
    return $stripped.Length -ge 15
}

Write-Output "Diary entries: $diaryRoot"
Write-Output "People files: $scPath"
Write-Output ""

$personFiles = [System.IO.Directory]::GetFiles($scPath, "*.md", [System.IO.SearchOption]::AllDirectories)
Write-Output "Found $($personFiles.Length) person files"

$diaryFiles = [System.IO.Directory]::GetFiles($diaryRoot, "*.md", [System.IO.SearchOption]::AllDirectories) | Where-Object {
    $fName = [System.IO.Path]::GetFileNameWithoutExtension($_)
    $dirName = [System.IO.Directory]::GetParent($_).Name
    $fName -notmatch '^\d{4}$' -and $dirName -match '^[А-Яа-яЁё]'
}
Write-Output "Found $($diaryFiles.Length) diary files"
Write-Output ""

$personMap = @{}
foreach ($pf in $personFiles) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($pf)
    $personMap[$name] = @{ File = $pf; Paragraphs = @() }
}

$personPatterns = @{}
foreach ($name in $personMap.Keys) {
    $escaped = [Regex]::Escape($name)
    $personPatterns[$name] = "\[\[$escaped\]\]|\b$escaped\b"
}

$totalMatches = 0
$skippedNamesOnly = 0

foreach ($df in $diaryFiles) {
    $content = [System.IO.File]::ReadAllText($df, $utf8)
    if ([string]::IsNullOrEmpty($content)) { continue }

    $paragraphs = [Regex]::Split($content, "(\r?\n\s*\r?\n)+")

    foreach ($para in $paragraphs) {
        $trimmed = $para.Trim()
        if ([string]::IsNullOrEmpty($trimmed)) { continue }
        if ($trimmed -match '^#\w+$') { continue }
        if (-not (IsMeaningfulParagraph $trimmed)) { $skippedNamesOnly++; continue }

        foreach ($name in $personMap.Keys) {
            if ($trimmed -match $personPatterns[$name]) {
                $parentDir = [System.IO.Directory]::GetParent($df).Name
                $grandParent = [System.IO.Directory]::GetParent([System.IO.Directory]::GetParent($df)).Name
                $fname = [System.IO.Path]::GetFileName($df)
                $rel = "$grandParent/$parentDir/$fname"
                $personMap[$name].Paragraphs += @{ Text = $trimmed; Source = $rel }
                $totalMatches++
            }
        }
    }
}

Write-Output "Total mentions found: $totalMatches"
Write-Output "Skipped (names only): $skippedNamesOnly"
Write-Output ""

$sectionHeader = "`n---`n## Упоминания в дневниках`n`n"

foreach ($name in $personMap.Keys) {
    $data = $personMap[$name]
    if ($data.Paragraphs.Count -eq 0) { continue }

    $existingContent = [System.IO.File]::ReadAllText($data.File, $utf8)
    $seen = @{}
    $newEntries = @()

    foreach ($p in $data.Paragraphs) {
        $key = $p.Text.GetHashCode()
        if ($seen.ContainsKey($key)) { continue }
        $preview = if ($p.Text.Length -gt 60) { $p.Text.Substring(0, 60) } else { $p.Text }
        if ($existingContent -match [Regex]::Escape($preview)) { continue }
        $seen[$key] = $true
        $newEntries += $p
    }

    if ($newEntries.Count -eq 0) { continue }

    $quoted = $newEntries | ForEach-Object {
        "**$($_.Source)**:`n> $($_.Text -replace "`n", "`n> ")"
    }

    $section = "$sectionHeader$($quoted -join "`n`n")"
    [System.IO.File]::AppendAllText($data.File, $section, $utf8)
    Write-Output "  -> $name ($($newEntries.Count) new)"
}

Write-Output ""
Write-Output "Done!"