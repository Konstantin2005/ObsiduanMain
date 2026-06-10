param(
    [string]$RepoPath = "C:\obsidian\Main",
    [string]$SplitScript = "C:\obsidian\Main\Scripts\Vault\Split-DiaryPeople.ps1",
    [int]$IntervalSeconds = 60
)

$ErrorActionPreference = "Continue"
Set-Location $RepoPath

$logPath = Join-Path $RepoPath "Scripts\Logs\split-diary-people.log"
$pidPath = Join-Path $RepoPath "Scripts\Logs\split-diary-people.pid"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $logPath -Value "[$timestamp] $Message"
}

Set-Content -LiteralPath $pidPath -Value $PID -Encoding ascii
Write-Log "Loop started. PID=$PID interval=${IntervalSeconds}s"

try {
    while ($true) {
        $started = Get-Date

        try {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SplitScript 2>&1 | ForEach-Object {
                Write-Log "$_"
            }
            Write-Log "Split run completed successfully."
        } catch {
            Write-Log "Split run failed: $($_.Exception.Message)"
        }

        $elapsed = (Get-Date) - $started
        $sleepSeconds = [Math]::Max(1, $IntervalSeconds - [int][Math]::Ceiling($elapsed.TotalSeconds))
        Start-Sleep -Seconds $sleepSeconds
    }
} finally {
    Write-Log "Loop stopped."
}
