param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$WebhookUrl,

    [string]$Title = "File export",

    [string]$Footer = "",

    [int]$ChunkSize = 2000,

    [int]$DelayMs = 350
)

$ErrorActionPreference = 'Stop'

function Get-Chunks {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$MaxLength
    )

    $chunks = New-Object System.Collections.Generic.List[string]
    $lines = $Text -split "`r?`n"
    $current = ""

    foreach ($line in $lines) {
        $candidate = if ($current.Length -eq 0) { $line } else { $current + "`n" + $line }

        if ($candidate.Length -le $MaxLength) {
            $current = $candidate
            continue
        }

        if ($current.Length -gt 0) {
            $chunks.Add($current)
            $current = ""
        }

        if ($line.Length -le $MaxLength) {
            $current = $line
            continue
        }

        $offset = 0
        while ($offset -lt $line.Length) {
            $take = [Math]::Min($MaxLength, $line.Length - $offset)
            $chunks.Add($line.Substring($offset, $take))
            $offset += $take
        }
    }

    if ($current.Length -gt 0) {
        $chunks.Add($current)
    }

    return $chunks
}

if (-not (Test-Path -LiteralPath $FilePath)) {
    throw "File not found: $FilePath"
}

$text = [System.IO.File]::ReadAllText($FilePath, [System.Text.UTF8Encoding]::new($false))
if ([string]::IsNullOrWhiteSpace($text)) {
    throw "File is empty: $FilePath"
}

$basePrefix = "**$Title**"
if ($Footer) {
    $basePrefix += "`n$Footer"
}

$available = $ChunkSize - $basePrefix.Length - 20
if ($available -lt 200) {
    throw "ChunkSize is too small after overhead. Increase ChunkSize."
}

$chunks = Get-Chunks -Text $text -MaxLength $available
$total = $chunks.Count

for ($i = 0; $i -lt $total; $i++) {
    $header = "**$Title** [$($i + 1)/$total]"
    $body = $chunks[$i]
    $message = $header + "`n" + $body
    if ($Footer) {
        $message += "`n$Footer"
    }

    if ($message.Length -gt $ChunkSize) {
        throw "Generated message exceeds Discord limit: $($message.Length) characters"
    }

    $payload = @{
        content = $message
    } | ConvertTo-Json -Compress

    Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $payload | Out-Null

    if ($DelayMs -gt 0 -and $i -lt ($total - 1)) {
        Start-Sleep -Milliseconds $DelayMs
    }
}
