param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [string]$ArchiveFileName = "Mini diaries.md",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$archivePath = Join-Path $DiaryRoot $ArchiveFileName

function Get-SplitFiles {
    param([string]$Root)

    [System.IO.Directory]::GetFiles($Root, "*.md", [System.IO.SearchOption]::AllDirectories) |
        Where-Object {
            $text = [System.IO.File]::ReadAllText($_, $utf8)
            $text -match '(?m)^\s*kind:\s*people-split\s*$'
        }
}

function Get-FrontMatter {
    param([string]$Text)

    $match = [Regex]::Match($Text, "^---\r?\n(?<fm>[\s\S]*?)\r?\n---\r?\n?", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $match.Success) {
        return @{ Body = $Text; FrontMatter = "" }
    }

    return @{
        Body = $Text.Substring($match.Length)
        FrontMatter = $match.Groups['fm'].Value
    }
}

function Get-FmValue {
    param(
        [string]$FrontMatter,
        [string]$Key
    )

    $match = [Regex]::Match($FrontMatter, "(?m)^$([Regex]::Escape($Key)):\s*(.+?)\s*$")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return $null
}

function Get-SourceSectionTitle {
    param([string]$FilePath, [string]$SourceValue)

    if (-not [string]::IsNullOrWhiteSpace($SourceValue)) {
        return $SourceValue
    }

    return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
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

$splitFiles = Get-SplitFiles -Root $DiaryRoot | Sort-Object
Write-Host "Found $($splitFiles.Count) split files"

$entries = New-Object System.Collections.Generic.List[string]

foreach ($file in $splitFiles) {
    $text = [System.IO.File]::ReadAllText($file, $utf8)
    $fm = Get-FrontMatter -Text $text
    $body = $fm.Body.Trim()

    $sourceValue = Get-FmValue -FrontMatter $fm.FrontMatter -Key "source"
    $peopleCount = Get-FmValue -FrontMatter $fm.FrontMatter -Key "people_count"
    $threshold = Get-FmValue -FrontMatter $fm.FrontMatter -Key "threshold"
    $primaryPeople = Get-FmValue -FrontMatter $fm.FrontMatter -Key "primary_people"
    $overflowPeople = Get-FmValue -FrontMatter $fm.FrontMatter -Key "overflow_people"
    $title = Get-SourceSectionTitle -FilePath $file -SourceValue $sourceValue
    $dateKey = Get-DateKeyFromName -FileName ([System.IO.Path]::GetFileName($file))

    $entry = New-Object System.Collections.Generic.List[string]
    [void]$entry.Add("## $title")
    [void]$entry.Add("")
    if ($dateKey) { [void]$entry.Add("- date_key: $dateKey") }
    [void]$entry.Add("- mini_source: $([System.IO.Path]::GetFileName($file))")
    if ($sourceValue) { [void]$entry.Add("- source: $sourceValue") }
    if ($peopleCount) { [void]$entry.Add("- people_count: $peopleCount") }
    if ($threshold) { [void]$entry.Add("- threshold: $threshold") }
    if ($primaryPeople) { [void]$entry.Add("- primary_people: $primaryPeople") }
    if ($overflowPeople) { [void]$entry.Add("- overflow_people: $overflowPeople") }
    [void]$entry.Add("")
    if ($body) { [void]$entry.Add($body) }

    [void]$entries.Add(($entry -join "`n").TrimEnd())
}

$archiveText = @(
    "---"
    "kind: people-split-archive"
    "source: consolidated-mini-diaries"
    "---"
    ""
    "# Mini diaries"
    ""
    ($entries -join "`n`n---`n`n")
) -join "`n"

Write-Host "Archive: $archivePath"

if (-not $DryRun) {
    [System.IO.File]::WriteAllText($archivePath, $archiveText, $utf8)
    foreach ($file in $splitFiles) {
        Remove-Item -LiteralPath $file -Force
    }
}

Write-Host "Done"
