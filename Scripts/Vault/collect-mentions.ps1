<#
.SYNOPSIS
  Collects mentions of people from diary entries and updates person files.
.DESCRIPTION
  Scans diary entries for mentions ([[Name]] or plain text) of people from
  Соц Капитал/. Maintains a single ## Упоминания в дневниках section in each
  person file, replacing it entirely on every run with all deduplicated mentions.
  Strips specified noise tags from quoted text.
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

$tagPattern = @(
    '#Продуктивна_скукота',
    '#Продуктивная_скукота',
    '#Обычный',
    '#Мясорубка',
    '#Ничего_не_делал'
) -join '|'

function StripNoiseTags($text) {
    $result = $text -replace $tagPattern, ''
    return $result.Trim()
}

function IsMeaningfulParagraph($text) {
    $stripped = $text -replace '\[\[.*?\]\]', ''
    $stripped = $stripped -replace '[#*>_\-\[\]()]', ''
    return $stripped.Trim().Length -ge 15
}

$personFiles = [System.IO.Directory]::GetFiles($scPath, "*.md", [System.IO.SearchOption]::AllDirectories)
Write-Output "Found $($personFiles.Length) person files"

$diaryFiles = [System.IO.Directory]::GetFiles($diaryRoot, "*.md", [System.IO.SearchOption]::AllDirectories) | Where-Object {
    $fName = [System.IO.Path]::GetFileNameWithoutExtension($_)
    $dirName = [System.IO.Directory]::GetParent($_).Name
    $fName -notmatch '^\d{4}$' -and $dirName -match '^[А-Яа-яЁё]'
}
Write-Output "Found $($diaryFiles.Length) diary files`n"

$personMap = @{}
foreach ($pf in $personFiles) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($pf)
    $personMap[$name] = @{ File = $pf; Mentions = @{} }
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

        $cleanText = StripNoiseTags($trimmed)

        foreach ($name in $personMap.Keys) {
            if ($cleanText -match $personPatterns[$name]) {
                $parentDir = [System.IO.Directory]::GetParent($df).Name
                $grandParent = [System.IO.Directory]::GetParent([System.IO.Directory]::GetParent($df)).Name
                $fname = [System.IO.Path]::GetFileName($df)
                $rel = "$grandParent/$parentDir/$fname"
                $key = "$rel|$cleanText"
                if (-not $personMap[$name].Mentions.ContainsKey($key)) {
                    $personMap[$name].Mentions[$key] = @{ Text = $cleanText; Source = $rel }
                }
                $totalMatches++
            }
        }
    }
}

Write-Output "Total mentions found: $totalMatches"
Write-Output "Skipped (names only): $skippedNamesOnly`n"

$sectionHeader = "## Упоминания в дневниках"

foreach ($name in $personMap.Keys) {
    $data = $personMap[$name]
    if ($data.Mentions.Count -eq 0) { continue }

    $content = [System.IO.File]::ReadAllText($data.File, $utf8)

    $idx = $content.IndexOf($sectionHeader)
    if ($idx -ge 0) {
        $contentBefore = $content.Substring(0, $idx).TrimEnd()
        $contentBefore = $contentBefore -replace '(?:\r?\n---)*$', ''
        $contentBefore = $contentBefore.TrimEnd()
    } else {
        $contentBefore = $content.TrimEnd()
    }

    $formatted = $data.Mentions.Values | Sort-Object {
        if ($_.Source -match '(\d{4}-\d{2}-\d{2})') { $matches[1] } else { $_.Source }
    } | ForEach-Object {
        "**$($_.Source)**:`n> $($_.Text -replace "`n", "`n> ")"
    }

    $sectionText = "`n---`n$sectionHeader`n`n" + ($formatted -join "`n`n")

    [System.IO.File]::WriteAllText($data.File, $contentBefore + $sectionText, $utf8)
    Write-Output "  -> $name ($($data.Mentions.Count) mentions)"
}

Write-Output "`nDone!"
