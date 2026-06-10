param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [int]$Threshold = 4,
    [string]$ArchiveFileName = "Mini diaries.md",
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

function Get-ArchivePath {
    param([string]$Root, [string]$Name)
    return Join-Path $Root $Name
}

function Get-DateKeyFromName {
    param([string]$FileName)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($FileName)

    if ($name -match '^\d{2}\.(.+)$') {
        $name = $matches[1]
    }

    if ($name -match '^(\d{4})-(\d{2})-(\d{2})$') {
        return "$($matches[1])-$($matches[2])-$($matches[3])"
    }

    if ($name -match '^(\d{1,2})-(\d{1,2})-(\d{2,4})$') {
        $day = [int]$matches[1]
        $month = [int]$matches[2]
        $yearText = $matches[3]
        $year = if ($yearText.Length -eq 2) { 2000 + [int]$yearText } else { [int]$yearText }
        return ('{0:0000}-{1:00}-{2:00}' -f $year, $month, $day)
    }

    return $null
}

function Get-SourceKey {
    param([string]$FilePath)
    return [System.IO.Path]::GetFileName($FilePath)
}

function Test-ArchiveHasDateKey {
    param(
        [string]$ArchiveText,
        [string]$DateKey
    )

    $escaped = [Regex]::Escape($DateKey)
    return $ArchiveText -match "(?m)^date_key:\s+$escaped\s*$"
}

function New-ArchiveEntry {
    param(
        [string]$DateKey,
        [string]$DailySource,
        [string]$MiniSource,
        [int]$PeopleCount,
        [System.Collections.Generic.HashSet[string]]$PrimaryPeople,
        [System.Collections.Generic.HashSet[string]]$OverflowPeople,
        [System.Collections.Generic.List[string]]$OverflowBlocks
    )

    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add("## $DateKey")
    [void]$lines.Add("")
    [void]$lines.Add("- date_key: $DateKey")
    [void]$lines.Add("- source: $DailySource")
    [void]$lines.Add("- mini_source: $MiniSource")
    [void]$lines.Add("- people_count: $PeopleCount")
    [void]$lines.Add("- primary_people: $([string]::Join(', ', $PrimaryPeople))")
    [void]$lines.Add("- overflow_people: $([string]::Join(', ', $OverflowPeople))")
    [void]$lines.Add("")

    foreach ($block in $OverflowBlocks) {
        [void]$lines.Add($block)
        [void]$lines.Add("")
    }

    return ($lines -join "`n").TrimEnd()
}

if (-not [System.IO.Directory]::Exists($DiaryRoot)) {
    throw "Diary path not found: $DiaryRoot"
}

$archivePath = Get-ArchivePath -Root $DiaryRoot -Name $ArchiveFileName
$archiveText = if ([System.IO.File]::Exists($archivePath)) {
    [System.IO.File]::ReadAllText($archivePath, $utf8)
} else {
    ""
}

$needsArchiveInit = -not [System.IO.File]::Exists($archivePath)
$files = Get-DiaryFiles -Root $DiaryRoot
Write-Host "Found $($files.Count) diary files"

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file, $utf8)
    if ([string]::IsNullOrWhiteSpace($content)) { continue }
    if ($content -match '(?m)^\s*kind:\s*people-split(?:-archive)?\s*$') { continue }

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

    $overflowBlocks = New-Object System.Collections.Generic.List[string]
    foreach ($block in (Split-IntoBlocks -Text $content)) {
        if (Test-BlockHasAnyPerson -Block $block -PersonNames $overflowPeople) {
            [void]$overflowBlocks.Add($block)
        }
    }

    $dailySource = Get-SourceKey -FilePath $file
    $dateKey = Get-DateKeyFromName -FileName $dailySource
    if ([string]::IsNullOrWhiteSpace($dateKey)) {
        continue
    }

    if (Test-ArchiveHasDateKey -ArchiveText $archiveText -DateKey $dateKey) {
        Write-Host ""
        Write-Host "File: $file"
        Write-Host "People: $($orderedPeople.Count) -> already in archive, skipped"
        continue
    }

    $entryText = New-ArchiveEntry `
        -DateKey $dateKey `
        -DailySource $dailySource `
        -MiniSource ([System.IO.Path]::GetFileNameWithoutExtension($file)) `
        -PeopleCount $orderedPeople.Count `
        -PrimaryPeople $primaryPeople `
        -OverflowPeople $overflowPeople `
        -OverflowBlocks $overflowBlocks

    Write-Host ""
    Write-Host "File: $file"
    Write-Host "People: $($orderedPeople.Count) -> archive: $archivePath"
    Write-Host "Mode: append overflow only, keep original intact"

    if ($DryRun) {
        Write-Host "Dry run: no files written"
        continue
    }

    if ($needsArchiveInit) {
        $header = @(
            "---"
            "kind: people-split-archive"
            "source: generated-from-daily-notes"
            "---"
            ""
            "# Mini diaries"
            ""
        ) -join "`n"
        [System.IO.File]::WriteAllText($archivePath, $header, $utf8)
        $needsArchiveInit = $false
        $archiveText = $header
    }

    [System.IO.File]::AppendAllText($archivePath, "`n`n$entryText`n", $utf8)
    $archiveText += "`n`n$entryText`n"
}

Write-Host ""
Write-Host "Done"
