<#
.SYNOPSIS
  Collects mentions of people from diary entries and updates person files.
#>

param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [string]$SocialCapitalRoot = (Join-Path $VaultPath "Calendula\Соц Капитал"),
    [switch]$DryRun,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'VaultHelpers.ps1')

if (-not [System.IO.Directory]::Exists($DiaryRoot)) {
    throw "Diary path not found: $DiaryRoot"
}
if (-not [System.IO.Directory]::Exists($SocialCapitalRoot)) {
    throw "Social capital path not found: $SocialCapitalRoot"
}

$tagPattern = @(
    '#Продуктивна_скукота',
    '#Продуктивная_скукота',
    '#Обычный',
    '#Мясорубка',
    '#Ничего_не_делал'
) -join '|'

function Strip-NoiseTags {
    param([string]$Text)
    return (($Text -replace $tagPattern, '')).Trim()
}

function Test-MeaningfulParagraph {
    param([string]$Text)
    $stripped = $Text -replace '\[\[.*?\]\]', ''
    $stripped = $stripped -replace '[#*>_\-\[\]()]', ''
    return $stripped.Trim().Length -ge 15
}

function Get-RelativeDiaryPath {
    param([string]$Path)
    $parent = [System.IO.Directory]::GetParent($Path)
    $grandParent = [System.IO.Directory]::GetParent($parent.FullName)
    $fname = [System.IO.Path]::GetFileName($Path)
    return "$($grandParent.Name)/$($parent.Name)/$fname"
}

$personFiles = [System.IO.Directory]::GetFiles($SocialCapitalRoot, "*.md", [System.IO.SearchOption]::AllDirectories)
$diaryFiles = [System.IO.Directory]::GetFiles($DiaryRoot, "*.md", [System.IO.SearchOption]::AllDirectories) | Where-Object {
    $fName = [System.IO.Path]::GetFileNameWithoutExtension($_)
    $dirName = [System.IO.Directory]::GetParent($_).Name
    $fName -notmatch '^\d{4}$' -and $dirName -match '^[А-Яа-яЁё]'
}

Write-Output "Found $($personFiles.Length) person files"
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
    $content = Read-Utf8Text -Path $df
    if ([string]::IsNullOrEmpty($content)) { continue }

    $paragraphs = [Regex]::Split($content, "(\r?\n\s*\r?\n)+")
    foreach ($para in $paragraphs) {
        $trimmed = $para.Trim()
        if ([string]::IsNullOrEmpty($trimmed)) { continue }
        if ($trimmed -match '^#\w+$') { continue }
        if (-not (Test-MeaningfulParagraph $trimmed)) { $skippedNamesOnly++; continue }

        $cleanText = Strip-NoiseTags $trimmed
        $cleanText = $cleanText.Replace('[[', '').Replace(']]', '')

        foreach ($name in $personMap.Keys) {
            if ($cleanText -match $personPatterns[$name]) {
                $rel = Get-RelativeDiaryPath -Path $df
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
$updatedPeople = @()

foreach ($name in $personMap.Keys) {
    $data = $personMap[$name]
    if ($data.Mentions.Count -eq 0) { continue }

    $content = Read-Utf8Text -Path $data.File
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
        "**$($_.Source)**:`n> $(($_.Text -replace "`n", "`n> ").Replace('[[', '').Replace(']]', ''))"
    }

    $sectionText = "`n---`n$sectionHeader`n`n" + ($formatted -join "`n`n")
    $newContent = $contentBefore + $sectionText
    if (-not $DryRun) {
        Write-Utf8Text -Path $data.File -Content $newContent
    }

    $updatedPeople += [pscustomobject]@{
        Name = $name
        Mentions = $data.Mentions.Count
        File = $data.File
    }
    Write-Output "  -> $name ($($data.Mentions.Count) mentions)"
}

Write-Output "`nDone!"

if ($PassThru) {
    [pscustomobject]@{
        TotalMatches = $totalMatches
        SkippedNamesOnly = $skippedNamesOnly
        UpdatedPeople = $updatedPeople
        DryRun = [bool]$DryRun
    }
}
