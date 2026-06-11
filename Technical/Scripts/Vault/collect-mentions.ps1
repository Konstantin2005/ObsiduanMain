<#
.SYNOPSIS
  Collects mentions of people from diary entries and updates person files.
#>

param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$DiaryRoot = (Join-Path $VaultPath "Calendula\Calendula"),
    [string]$SocialCapitalRoot = (Join-Path $VaultPath "Calendula\Соц Капитал"),
    [ValidateRange(1, 128)]
    [int]$ThrottleLimit = [Environment]::ProcessorCount,
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

$scanDiaryWorker = {
    param(
        [string[]]$DiaryBatch,
        [string[]]$PersonNames,
        [hashtable]$PersonPatterns,
        [string]$TagPattern
    )

    function Strip-NoiseTags {
        param([string]$Text)
        return (($Text -replace $TagPattern, '')).Trim()
    }

    function Test-MeaningfulParagraph {
        param([string]$Text)
        $stripped = $Text -replace '\[\[.*?\]\]', ''
        $stripped = $stripped -replace '[#*>_\-\[\]()]', ''
        return $stripped.Trim().Length -ge 15
    }

    function Get-RelativeDiaryPathLocal {
        param([string]$Path)
        $parent = [System.IO.Directory]::GetParent($Path)
        $grandParent = [System.IO.Directory]::GetParent($parent.FullName)
        $fname = [System.IO.Path]::GetFileName($Path)
        return "$($grandParent.Name)/$($parent.Name)/$fname"
    }

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $batchResults = New-Object System.Collections.Generic.List[object]

    foreach ($df in $DiaryBatch) {
        $content = [System.IO.File]::ReadAllText($df, $utf8)
        if ([string]::IsNullOrEmpty($content)) { continue }

        $paragraphs = [Regex]::Split($content, "(\r?\n\s*\r?\n)+")
        $mentions = New-Object System.Collections.Generic.List[object]
        $totalMatches = 0
        $skippedNamesOnly = 0

        foreach ($para in $paragraphs) {
            $trimmed = $para.Trim()
            if ([string]::IsNullOrEmpty($trimmed)) { continue }
            if ($trimmed -match '^#\w+$') { continue }
            if (-not (Test-MeaningfulParagraph $trimmed)) { $skippedNamesOnly++; continue }

            $cleanText = Strip-NoiseTags $trimmed
            $cleanText = $cleanText.Replace('[[', '').Replace(']]', '')

            foreach ($name in $PersonNames) {
                if ($cleanText -match $PersonPatterns[$name]) {
                    $rel = Get-RelativeDiaryPathLocal -Path $df
                    [void]$mentions.Add([pscustomobject]@{
                        Name = $name
                        Source = $rel
                        Text = $cleanText
                    })
                    $totalMatches++
                }
            }
        }

        [void]$batchResults.Add([pscustomobject]@{
            DiaryFile = $df
            Mentions = $mentions
            TotalMatches = $totalMatches
            SkippedNamesOnly = $skippedNamesOnly
        })
    }

    return $batchResults
}

function Invoke-DiaryScan {
    param(
        [string[]]$DiaryFiles,
        [string[]]$PersonNames,
        [hashtable]$PersonPatterns,
        [string]$TagPattern,
        [int]$ThrottleLimit
    )

    if ($ThrottleLimit -le 1 -or $DiaryFiles.Count -le 1) {
        return & $scanDiaryWorker -DiaryBatch $DiaryFiles -PersonNames $PersonNames -PersonPatterns $PersonPatterns -TagPattern $TagPattern
    }

    $batchSize = 64
    $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit)
    $pool.ApartmentState = [System.Threading.ApartmentState]::MTA
    $pool.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $pool.Open()

    $jobs = New-Object System.Collections.Generic.List[object]
    try {
        for ($i = 0; $i -lt $DiaryFiles.Count; $i += $batchSize) {
            $end = [Math]::Min($i + $batchSize - 1, $DiaryFiles.Count - 1)
            $batch = $DiaryFiles[$i..$end]
            $ps = [PowerShell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript($scanDiaryWorker.ToString()).AddArgument($batch).AddArgument($PersonNames).AddArgument($PersonPatterns).AddArgument($TagPattern)
            [void]$jobs.Add([pscustomobject]@{
                PowerShell = $ps
                Handle = $ps.BeginInvoke()
            })
        }

        $results = New-Object System.Collections.Generic.List[object]
        foreach ($job in $jobs) {
            $batchResults = $job.PowerShell.EndInvoke($job.Handle)
            foreach ($item in $batchResults) {
                [void]$results.Add($item)
            }
        }

        return $results
    }
    finally {
        foreach ($job in $jobs) {
            if ($null -ne $job.PowerShell) {
                $job.PowerShell.Dispose()
            }
        }

        $pool.Close()
        $pool.Dispose()
    }
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
foreach ($name in ($personMap.Keys | Sort-Object)) {
    $escaped = [Regex]::Escape($name)
    $personPatterns[$name] = "\[\[$escaped\]\]|\b$escaped\b"
}

$scanResults = Invoke-DiaryScan -DiaryFiles $diaryFiles -PersonNames ($personMap.Keys | Sort-Object) -PersonPatterns $personPatterns -TagPattern $tagPattern -ThrottleLimit $ThrottleLimit

$totalMatches = ($scanResults | Measure-Object -Property TotalMatches -Sum).Sum
if ($null -eq $totalMatches) { $totalMatches = 0 }
$skippedNamesOnly = ($scanResults | Measure-Object -Property SkippedNamesOnly -Sum).Sum
if ($null -eq $skippedNamesOnly) { $skippedNamesOnly = 0 }

foreach ($scan in $scanResults) {
    foreach ($mention in $scan.Mentions) {
        $key = "$($mention.Source)|$($mention.Text)"
        if (-not $personMap[$mention.Name].Mentions.ContainsKey($key)) {
            $personMap[$mention.Name].Mentions[$key] = @{
                Text = $mention.Text
                Source = $mention.Source
            }
        }
    }
}

Write-Output "Total mentions found: $totalMatches"
Write-Output "Skipped (names only): $skippedNamesOnly`n"

$sectionHeader = "## Упоминания в дневниках"
$updatedPeople = @()

foreach ($name in ($personMap.Keys | Sort-Object)) {
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
        Assert-SafeBulkOperation -Operation 'collect-mentions person write' -Root $VaultPath -TargetPaths @($data.File) -DryRun:$DryRun
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
