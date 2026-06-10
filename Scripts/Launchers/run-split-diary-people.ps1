param(
    [switch]$DryRun
)

$scriptPath = "C:\obsidian\Main\Scripts\Vault\Split-DiaryPeople.ps1"

if ($DryRun) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -DryRun
} else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
}
