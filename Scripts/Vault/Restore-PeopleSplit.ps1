param(
    [string]$VaultPath = "C:\obsidian\Main",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$root = Join-Path $VaultPath "Calendula\Calendula"

function Get-AllMarkdownFiles {
    param([string]$RootPath)

    [System.IO.Directory]::GetFiles($RootPath, "*.md", [System.IO.SearchOption]::AllDirectories)
}

function Test-IsPeopleSplit {
    param([string]$Text)

    return $Text -match '(?m)^kind:\s*people-split\s*$'
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

function Get-BodyBlocks {
    param([string]$Text)

    $body = $Text
    $frontmatter = [Regex]::Match($body, "^---\r?\n[\s\S]*?\r?\n---\r?\n?")
    if ($frontmatter.Success) {
        $body = $body.Substring($frontmatter.Length)
    }

    return [Regex]::Split($body, "(\r?\n\s*\r?\n)+") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() }
}

function Get-UniqueLinks {
    param([string]$Text)

    return [Regex]::Matches($Text, '\[\[([^\]]+)\]\]') |
        ForEach-Object { $_.Groups[1].Value.Trim() } |
        Select-Object -Unique
}

if (-not [System.IO.Directory]::Exists($root)) {
    throw "Diary path not found: $root"
}

$allFiles = Get-AllMarkdownFiles -RootPath $root
$splitFiles = @()

foreach ($file in $allFiles) {
    $text = [System.IO.File]::ReadAllText($file, $utf8)
    if (Test-IsPeopleSplit -Text $text) {
        $splitFiles += [pscustomobject]@{
            Path = $file
            Text = $text
        }
    }
}

$summary = @()

foreach ($split in $splitFiles) {
    $splitDir = [System.IO.Path]::GetDirectoryName($split.Path)
    $splitBase = [System.IO.Path]::GetFileName($split.Path)
    $splitDateKey = Get-DateKeyFromName -FileName $splitBase

    $origCandidates = foreach ($file in $allFiles) {
        if ([System.IO.Path]::GetDirectoryName($file) -ne $splitDir) { continue }
        if ($file -eq $split.Path) { continue }

        $candidateText = [System.IO.File]::ReadAllText($file, $utf8)
        if (Test-IsPeopleSplit -Text $candidateText) { continue }

        $candidateDateKey = Get-DateKeyFromName -FileName ([System.IO.Path]::GetFileName($file))
        if ($candidateDateKey -ne $splitDateKey) { continue }

        [pscustomobject]@{
            Path = $file
            Text = $candidateText
        }
    }

    $original = $origCandidates | Select-Object -First 1
    if (-not $original) {
        $summary += "NO_ORIGINAL `"$($split.Path)`""
        continue
    }

    $originalLinks = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($name in (Get-UniqueLinks -Text $original.Text)) {
        [void]$originalLinks.Add($name)
    }

    $missingBlocks = New-Object System.Collections.Generic.List[string]
    foreach ($block in (Get-BodyBlocks -Text $split.Text)) {
        $blockLinks = @(Get-UniqueLinks -Text $block)
        if ($blockLinks.Count -eq 0) { continue }

        $needsRestore = $false
        foreach ($link in $blockLinks) {
            if (-not $originalLinks.Contains($link)) {
                $needsRestore = $true
                break
            }
        }

        if ($needsRestore) {
            [void]$missingBlocks.Add($block)
        }
    }

    if ($missingBlocks.Count -eq 0) {
        $summary += "OK `"$($original.Path)`""
        continue
    }

    $appendText = "`r`n`r`n---`r`n`r`n" + ($missingBlocks -join "`r`n`r`n")

    if (-not $DryRun) {
        $newText = $original.Text
        if (-not $newText.EndsWith("`r`n")) {
            $newText += "`r`n"
        }
        $newText += $appendText
        [System.IO.File]::WriteAllText($original.Path, $newText, $utf8)
    }

    $summary += "RESTORED `"$($original.Path)`" blocks=$($missingBlocks.Count)"
}

$summary | ForEach-Object { Write-Host $_ }
Write-Host "Done"
