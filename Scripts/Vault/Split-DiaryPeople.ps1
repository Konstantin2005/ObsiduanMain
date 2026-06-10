<#
.SYNOPSIS
  Splits diary notes by people mentions when the daily count exceeds a threshold.
.DESCRIPTION
  Scans markdown diary files, counts unique person wikilinks like [[Danil]],
  and when the count is greater than the threshold, creates a new note with the
  whole block where the threshold is exceeded and every block after it.

  Default output file name format:
    03.03-06-26.md
  where the leading number is the amount of unique people mentions in that note.
#>

param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [int]$Threshold = 4,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Get-DiaryFiles {
    param([string]$Root)

    [System.IO.Directory]::GetFiles($Root, "*.md", [System.IO.SearchOption]::AllDirectories) |
        Where-Object {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($_)
            $name -notmatch '^\d{4}$'
        }
}

function Get-PersonMentions {
    param([string]$Text)

    $matches = [Regex]::Matches($Text, '\[\[([^\]]+)\]\]')
    $names = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in $matches) {
        [void]$names.Add($m.Groups[1].Value.Trim())
    }
    return $names
}

function Split-IntoBlocks {
    param([string]$Text)

    [Regex]::Split($Text, "(\r?\n\s*\r?\n)+") |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Get-BlockMentions {
    param(
        [string]$Block
    )

    $names = New-Object System.Collections.Generic.HashSet[string]
    foreach ($match in [Regex]::Matches($Block, '\[\[([^\]]+)\]\]')) {
        [void]$names.Add($match.Groups[1].Value.Trim())
    }

    return $names
}

function Get-SplitFileName {
    param(
        [string]$SourceFile,
        [int]$PeopleCount
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile)
    $datePart = $baseName

    if ($baseName -match '(\d{4}-\d{2}-\d{2})') {
        $date = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd', $null)
        $datePart = $date.ToString('dd-MM-yy')
    }
    elseif ($baseName -match '(\d{1,2})-(\d{1,2})-(\d{2,4})') {
        $day = [int]$matches[1]
        $month = [int]$matches[2]
        $yearText = $matches[3]
        $year = if ($yearText.Length -eq 2) { 2000 + [int]$yearText } else { [int]$yearText }
        $datePart = ('{0:00}-{1:00}-{2:00}' -f $day, $month, ($year % 100))
    }

    return ('{0:D2}.{1}.md' -f $PeopleCount, $datePart)
}

if (-not [System.IO.Directory]::Exists($DiaryRoot)) {
    throw "Diary path not found: $DiaryRoot"
}

$files = Get-DiaryFiles -Root $DiaryRoot
Write-Host "Found $($files.Count) diary files"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file, $utf8)
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    $people = Get-PersonMentions -Text $content
    if ($people.Count -le $Threshold) { continue }

    $blocks = Split-IntoBlocks -Text $content
    $splitStartIndex = $null
    $seenNames = New-Object System.Collections.Generic.HashSet[string]

    for ($i = 0; $i -lt $blocks.Count; $i++) {
        $blockNames = Get-BlockMentions -Block $blocks[$i]
        foreach ($name in $blockNames) {
            [void]$seenNames.Add($name)
        }

        if ($seenNames.Count -gt $Threshold) {
            $splitStartIndex = $i
            break
        }
    }

    if ($null -eq $splitStartIndex) {
        continue
    }

    $originalBlocks = @()
    if ($splitStartIndex -gt 0) {
        $originalBlocks = $blocks[0..($splitStartIndex - 1)]
    }

    $splitBlocks = $blocks[$splitStartIndex..($blocks.Count - 1)]

    $splitFileName = Get-SplitFileName -SourceFile $file -PeopleCount $people.Count
    $splitPath = Join-Path ([System.IO.Directory]::GetParent($file).FullName) $splitFileName

    $splitContent = @(
        "---"
        "source: $([System.IO.Path]::GetFileName($file))"
        "people_count: $($people.Count)"
        "threshold: $Threshold"
        "---"
        ""
        ($splitBlocks -join "`n`n")
    ) -join "`n"

    $updatedOriginal = $originalBlocks -join "`n`n"

    Write-Host ""
    Write-Host "File: $file"
    Write-Host "People: $($people.Count) -> split file: $splitPath"

    if ($DryRun) {
        Write-Host "Dry run: no files written"
        continue
    }

    [System.IO.File]::WriteAllText($splitPath, $splitContent, $utf8)
    [System.IO.File]::WriteAllText($file, $updatedOriginal, $utf8)
}

Write-Host ""
Write-Host "Done"
