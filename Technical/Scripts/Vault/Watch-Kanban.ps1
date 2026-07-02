param(
    [string]$KanbanDir = "C:\obsidian\Main\Calendula\План",
    [string]$SortScript = "C:\obsidian\Main\Technical\Scripts\Vault\Sort-BoardTasks.ps1",
    [int]$PollSeconds = 5,
    [int]$CooldownSeconds = 30
)

$ErrorActionPreference = "Continue"
$lastWriteCache = @{}
$lastRun = [DateTime]::MinValue

# Build initial write-time cache for all .md files
Get-ChildItem $KanbanDir -Recurse -Filter "*.md" | ForEach-Object {
    $lastWriteCache[$_.FullName] = $_.LastWriteTimeUtc
}

Write-Host "Watching $KanbanDir (poll every ${PollSeconds}s, cooldown ${CooldownSeconds}s)..."

while ($true) {
    Start-Sleep -Seconds $PollSeconds
    [System.GC]::Collect()

    try {
        $hasChanges = $false
        Get-ChildItem $KanbanDir -Recurse -Filter "*.md" | ForEach-Object {
            $path = $_.FullName
            $currentWrite = $_.LastWriteTimeUtc
            $cachedWrite = $null
            if ($lastWriteCache.ContainsKey($path)) { $cachedWrite = $lastWriteCache[$path] }
            if ($cachedWrite -eq $null -or $currentWrite -ne $cachedWrite) {
                $lastWriteCache[$path] = $currentWrite
                $hasChanges = $true
            }
        }

        if (-not $hasChanges) { continue }

        $now = [DateTime]::UtcNow
        if (($now - $lastRun).TotalSeconds -lt $CooldownSeconds) { continue }
        $lastRun = $now

        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SortScript 2>&1 | Out-Null
    } catch {
        # silent
    }
}
