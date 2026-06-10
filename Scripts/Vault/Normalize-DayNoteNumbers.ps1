param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$archivePath = Join-Path $DiaryRoot "Mini diaries.md"

function Get-NoteMeta {
    param([string]$Path)

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $directory = [System.IO.Path]::GetDirectoryName($Path)

    if ($baseName -match '^(?<prefix>\d{1,2})\.(?<day>\d{1,2})-(?<month>\d{1,2})-(?<year>\d{2,4})$') {
        $yearText = $matches.year
        $year = if ($yearText.Length -eq 2) { 2000 + [int]$yearText } else { [int]$yearText }

        return [pscustomobject]@{
            Path = $Path
            Directory = $directory
            BaseName = $baseName
            IsNumbered = $true
            Prefix = [int]$matches.prefix
            DayText = $matches.day
            MonthText = $matches.month
            YearText = $yearText
            DateKey = ('{0:0000}-{1:00}-{2:00}' -f $year, [int]$matches.month, [int]$matches.day)
        }
    }

    if ($baseName -match '^(?<day>\d{1,2})-(?<month>\d{1,2})-(?<year>\d{2,4})$') {
        $yearText = $matches.year
        $year = if ($yearText.Length -eq 2) { 2000 + [int]$yearText } else { [int]$yearText }

        return [pscustomobject]@{
            Path = $Path
            Directory = $directory
            BaseName = $baseName
            IsNumbered = $false
            Prefix = $null
            DayText = $matches.day
            MonthText = $matches.month
            YearText = $yearText
            DateKey = ('{0:0000}-{1:00}-{2:00}' -f $year, [int]$matches.month, [int]$matches.day)
        }
    }

    return $null
}

function Get-RelativePath {
    param(
        [string]$From,
        [string]$To
    )

    $fromFull = [System.IO.Path]::GetFullPath($From)
    if (-not $fromFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $fromFull += [System.IO.Path]::DirectorySeparatorChar
    }

    $toFull = [System.IO.Path]::GetFullPath($To)
    if ($toFull.StartsWith($fromFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $toFull.Substring($fromFull.Length).Replace('\', '/')
    }

    return $toFull.Replace('\', '/')
}

if (-not [System.IO.Directory]::Exists($DiaryRoot)) {
    throw "Diary path not found: $DiaryRoot"
}

$allNotes = Get-ChildItem -LiteralPath $DiaryRoot -Recurse -File -Filter "*.md" |
    ForEach-Object { Get-NoteMeta -Path $_.FullName } |
    Where-Object { $_ -ne $null }

$groups = $allNotes |
    Where-Object { $_.IsNumbered } |
    Group-Object -Property { "$($_.Directory)|$($_.DateKey)" }

$renamePlan = New-Object System.Collections.Generic.List[object]

foreach ($group in $groups) {
    $groupNotes = @($group.Group)
    $mainExists = @($allNotes | Where-Object {
        (-not $_.IsNumbered) -and $_.Directory -eq $groupNotes[0].Directory -and $_.DateKey -eq $groupNotes[0].DateKey
    })

    $startIndex = if ($mainExists.Count -gt 0) { 2 } else { 1 }
    $ordered = @($groupNotes | Sort-Object Prefix, BaseName)

    for ($i = 0; $i -lt $ordered.Count; $i++) {
        $note = $ordered[$i]
        $newPrefix = $startIndex + $i
        $newBaseName = ('{0:00}.{1}-{2}-{3}.md' -f $newPrefix, $note.DayText, $note.MonthText, $note.YearText)

        if ($newBaseName -eq ($note.BaseName + ".md")) {
            continue
        }

        [void]$renamePlan.Add([pscustomobject]@{
            OldPath = $note.Path
            NewPath = [System.IO.Path]::Combine($note.Directory, $newBaseName)
            OldRelative = Get-RelativePath -From $DiaryRoot -To $note.Path
            NewRelative = Get-RelativePath -From $DiaryRoot -To ([System.IO.Path]::Combine($note.Directory, $newBaseName))
            OldBaseName = $note.BaseName + ".md"
            NewBaseName = $newBaseName
        })
    }
}

Write-Host "Planned renames: $($renamePlan.Count)"
foreach ($item in $renamePlan) {
    Write-Host "$($item.OldRelative) -> $($item.NewRelative)"
}

if ($DryRun -or $renamePlan.Count -eq 0) {
    Write-Host "Done"
    return
}

foreach ($item in $renamePlan) {
    [System.IO.File]::Move($item.OldPath, $item.NewPath)
}

$markdownFiles = Get-ChildItem -LiteralPath $DiaryRoot -Recurse -File -Filter "*.md" |
    Where-Object { $_.FullName -ne $archivePath }

foreach ($file in $markdownFiles) {
    $original = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    $updated = $original

    foreach ($item in $renamePlan) {
        $updated = $updated.Replace($item.OldRelative, $item.NewRelative)
        $updated = $updated.Replace($item.OldBaseName, $item.NewBaseName)
    }

    if ($updated -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8)
    }
}

Write-Host "Done"
