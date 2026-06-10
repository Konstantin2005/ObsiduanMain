function Get-MonthName {
    param([Parameter(Mandatory = $true)][int]$Month)

    switch ($Month) {
        1 { "Январь" }
        2 { "Февраль" }
        3 { "Март" }
        4 { "Апрель" }
        5 { "Май" }
        6 { "Июнь" }
        7 { "Июль" }
        8 { "Август" }
        9 { "Сентябрь" }
        10 { "Октябрь" }
        11 { "Ноябрь" }
        12 { "Декабрь" }
        default { throw "Invalid month: $Month" }
    }
}

function Read-Utf8Text {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

function Write-Utf8Text {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content,
        [switch]$Bom
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $encoding = if ($Bom) {
        [System.Text.UTF8Encoding]::new($true)
    } else {
        [System.Text.UTF8Encoding]::new($false)
    }

    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Split-Lines {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text -or $Text.Length -eq 0) {
        return @()
    }

    return $Text -split "`r?`n"
}

function Get-TrailingNewline {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) { return "" }
    if ($Text.EndsWith("`r`n")) { return "`r`n" }
    if ($Text.EndsWith("`n")) { return "`n" }
    return ""
}

function Get-SectionRange {
    param(
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Heading
    )

    $start = $null
    $end = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^## $([regex]::Escape($Heading))$") {
            $start = $i
            continue
        }
        if ($start -ne $null -and $end -eq $null -and $Lines[$i] -match "^## " -and $i -gt $start) {
            $end = $i
            break
        }
    }

    if ($start -eq $null) { return $null }
    if ($end -eq $null) { $end = $Lines.Count }
    return ,@($start, $end)
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string]$To
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
