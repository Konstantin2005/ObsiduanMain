param(
    [switch]$DryRun,
    [int]$IntervalSeconds = 15
)

$ErrorActionPreference = 'Continue'
$scriptPath = "C:\obsidian\Main\Technical\Scripts\Vault\Normalize-DayNoteNumbers.ps1"

Write-Host "Running $scriptPath every $IntervalSeconds seconds..."

while ($true) {
    try {
        if ($DryRun) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -DryRun
        } else {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
        }
    } catch {
        Write-Host $_.Exception.Message
    }

    Start-Sleep -Seconds $IntervalSeconds
}
