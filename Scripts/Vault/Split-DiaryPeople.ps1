<#
.SYNOPSIS
  Splits diary notes by people mentions when the daily count exceeds a threshold.
.DESCRIPTION
  Scans markdown diary files, counts unique person wikilinks like [[Danil]],
  and when the count is greater than the threshold, creates a new note with the
  people-related blocks moved into it.

  Default output file name format:
    03.3-06-2026.md
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

function Get-PersonOrder {
    param([string]$Text)

    $matches = [Regex]::Matches($Text, '\[\[([^\]]+)\]\]')
    $seen = New-Object System.Collections.Generic.HashSet[string]
    $ordered = New-Object System.Collections.Generic.List[string]
    foreach ($m in $matches) {
        $name = $m.Groups[1].Value.Trim()
        if ($seen.Add($name)) {
            [void]$ordered.Add($name)
        }
    }
    return $ordered
}

function Split-IntoBlocks {
    param([string]$Text)

    [Regex]::Split($Text, "(\r?\n\s*\r?\n)+") |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Test-BlockHasAnyPerson {
    param(
        [string]$Block,
        [System.Collections.Generic.HashSet[string]]$PersonNames
    )

    foreach ($name in $PersonNames) {
        $escaped = [Regex]::Escape($name)
        if ($Block -match "\[\[$escaped\]\]") {
            return $true
        }
    }

    return $false
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
        $datePart = $date.ToString('d-MM-yy')
    }
    elseif ($baseName -match '(\d{1,2})-(\d{1,2})-(\d{2,4})') {
        $day = [int]$matches[1]
        $month = [int]$matches[2]
        $yearText = $matches[3]
        $year = if ($yearText.Length -eq 2) { [int]$yearText } else { [int]$yearText % 100 }
        $datePart = ('{0}-{1:00}-{2:00}' -f $day, $month, $year)
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
    if ($content -match '(?m)^\s*kind:\s*people-split\s*$') { continue }

    $orderedPeople = Get-PersonOrder -Text $content
    if ($orderedPeople.Count -le $Threshold) { continue }

    $primaryPeople = New-Object System.Collections.Generic.HashSet[string]
    $overflowPeople = New-Object System.Collections.Generic.HashSet[string]

    for ($i = 0; $i -lt $orderedPeople.Count; $i++) {
        if ($i -lt $Threshold) {
            [void]$primaryPeople.Add($orderedPeople[$i])
        } else {
            [void]$overflowPeople.Add($orderedPeople[$i])
        }
    }

    $blocks = Split-IntoBlocks -Text $content
    $overflowBlocks = New-Object System.Collections.Generic.List[string]
    $keepBlocks = New-Object System.Collections.Generic.List[string]

    foreach ($block in $blocks) {
        if (Test-BlockHasAnyPerson -Block $block -PersonNames $overflowPeople) {
            [void]$overflowBlocks.Add($block)
        } else {
            [void]$keepBlocks.Add($block)
        }
    }

    $splitFileName = Get-SplitFileName -SourceFile $file -PeopleCount $orderedPeople.Count
    $splitPath = Join-Path ([System.IO.Directory]::GetParent($file).FullName) $splitFileName

    $splitContent = @(
        "---"
        "kind: people-split"
        "source: $([System.IO.Path]::GetFileName($file))"
        "people_count: $($orderedPeople.Count)"
        "primary_people: $([string]::Join(', ', $primaryPeople))"
        "overflow_people: $([string]::Join(', ', $overflowPeople))"
        "threshold: $Threshold"
        "---"
        ""
        "# People split"
        ""
        ($overflowBlocks -join "`n`n")
    ) -join "`n"

    $updatedOriginal = $keepBlocks -join "`n`n"

    Write-Host ""
    Write-Host "File: $file"
    Write-Host "People: $($orderedPeople.Count) -> split file: $splitPath"

    if ($DryRun) {
        Write-Host "Dry run: no files written"
        continue
    }

    [System.IO.File]::WriteAllText($splitPath, $splitContent, $utf8)
    [System.IO.File]::WriteAllText($file, $updatedOriginal, $utf8)
}

Write-Host ""
Write-Host "Done"
