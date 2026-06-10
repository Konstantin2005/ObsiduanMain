<#
.SYNOPSIS
  Splits diary notes by people mentions into chunks.
.DESCRIPTION
  Scans markdown diary files, counts unique person wikilinks like [[Danil]],
  and when the count is greater than the main limit, splits the note into
  chunks. The original note keeps up to 4 unique people, and later mini notes
  keep up to 3 unique people each. Mini notes only keep the copied text body,
  without YAML properties.

  Default output file name format:
    07.1-06-26.md
  where the leading number is the source day and the suffix keeps the month-year.
#>

param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [int]$Threshold = 4,
    [int]$MiniChunkLimit = 3,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$MainChunkLimit = $Threshold

function Get-DiaryFiles {
    param([string]$Root)

    [System.IO.Directory]::GetFiles($Root, "*.md", [System.IO.SearchOption]::AllDirectories) |
        Where-Object {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($_)
            if ($name -match '^\d{4}$' -or $name -match '^\d{2}\.\d+-.+$') {
                return $false
            }

            return $true
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

function Get-TopTags {
    param([string]$Text)

    $lines = $Text -split "\r?\n"
    $tags = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($tags.Count -gt 0) {
                break
            }

            continue
        }

        if ($line -match '^#(?!#)\S') {
            [void]$tags.Add($line.TrimEnd())
            continue
        }

        if ($tags.Count -gt 0) {
            break
        }

        break
    }

    return $tags
}

function Get-DatePartsFromSourceFile {
    param([string]$SourceFile)

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile)

    if ($baseName -match '^(\d{4})-(\d{2})-(\d{2})$') {
        $date = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd', $null)
        return [pscustomobject]@{
            Day = $date.ToString('dd')
            MonthYear = $date.ToString('MM-yy')
        }
    }

    if ($baseName -match '^(\d{1,2})(?:\.\d+)?-(\d{1,2})-(\d{2,4})$') {
        $day = '{0:00}' -f [int]$matches[1]
        $month = '{0:00}' -f [int]$matches[2]
        $yearText = $matches[3]
        $yearSuffix = if ($yearText.Length -eq 2) { $yearText } else { $yearText.Substring($yearText.Length - 2, 2) }

        return [pscustomobject]@{
            Day = $day
            MonthYear = "$month-$yearSuffix"
        }
    }

    return [pscustomobject]@{
        Day = $baseName
        MonthYear = $baseName
    }
}

function Get-BlockMentions {
    param([string]$Block)

    $names = New-Object System.Collections.Generic.HashSet[string]
    foreach ($match in [Regex]::Matches($Block, '\[\[([^\]]+)\]\]')) {
        [void]$names.Add($match.Groups[1].Value.Trim())
    }

    return $names
}

function Get-SplitFileName {
    param(
        [string]$SourceFile,
        [int]$ChunkIndex
    )

    $dateParts = Get-DatePartsFromSourceFile -SourceFile $SourceFile
    return ('{0}.{1}-{2}.md' -f $dateParts.Day, $ChunkIndex, $dateParts.MonthYear)
}

if (-not [System.IO.Directory]::Exists($DiaryRoot)) {
    throw "Diary path not found: $DiaryRoot"
}

$files = Get-DiaryFiles -Root $DiaryRoot
Write-Host "Found $($files.Count) diary files"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file, $utf8)
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    $topTags = Get-TopTags -Text $content
    $people = Get-PersonMentions -Text $content
    if ($people.Count -le $MainChunkLimit) { continue }

    $blocks = Split-IntoBlocks -Text $content
    if ($blocks.Count -eq 0) { continue }

    $chunks = New-Object System.Collections.Generic.List[object]
    $currentBlocks = New-Object System.Collections.Generic.List[string]
    $currentNames = New-Object System.Collections.Generic.HashSet[string]
    $currentLimit = $MainChunkLimit

    foreach ($block in $blocks) {
        $blockNames = Get-BlockMentions -Block $block
        $newNames = @($blockNames | Where-Object { -not $currentNames.Contains($_) })
        $wouldExceed = (($currentNames.Count + $newNames.Count) -gt $currentLimit)

        if ($wouldExceed -and $currentBlocks.Count -gt 0) {
            [void]$chunks.Add([pscustomobject]@{
                Blocks = @($currentBlocks)
                PeopleCount = $currentNames.Count
            })

            $currentBlocks = New-Object System.Collections.Generic.List[string]
            $currentNames = New-Object System.Collections.Generic.HashSet[string]
            $currentLimit = $MiniChunkLimit
        }

        [void]$currentBlocks.Add($block)
        foreach ($name in $blockNames) {
            [void]$currentNames.Add($name)
        }
    }

    if ($currentBlocks.Count -gt 0) {
        [void]$chunks.Add([pscustomobject]@{
            Blocks = @($currentBlocks)
            PeopleCount = $currentNames.Count
        })
    }

    if ($chunks.Count -le 1) {
        continue
    }

    $updatedOriginal = $chunks[0].Blocks -join "`n`n"

    Write-Host ""
    Write-Host "File: $file"
    Write-Host "Chunks: $($chunks.Count)"

    if ($DryRun) {
        Write-Host "Dry run: no files written"
        continue
    }

    [System.IO.File]::WriteAllText($file, $updatedOriginal, $utf8)

    for ($chunkIndex = 1; $chunkIndex -lt $chunks.Count; $chunkIndex++) {
        $chunk = $chunks[$chunkIndex]
        $splitFileName = Get-SplitFileName -SourceFile $file -ChunkIndex $chunkIndex
        $splitPath = Join-Path ([System.IO.Directory]::GetParent($file).FullName) $splitFileName
        $splitSections = @()
        if ($topTags.Count -gt 0) {
            $splitSections += ($topTags -join "`n")
        }
        $splitSections += ($chunk.Blocks -join "`n`n")
        $splitContent = $splitSections -join "`n`n"

        [System.IO.File]::WriteAllText($splitPath, $splitContent, $utf8)
        Write-Host "  -> $splitPath"
    }
}

Write-Host ""
Write-Host "Done"
