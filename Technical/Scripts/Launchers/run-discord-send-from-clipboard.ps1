param(
    [string]$WebhookUrl,
    [string]$Title = "Obsidian note",
    [string]$Footer = ""
)

$scriptPath = "C:\obsidian\Main\Technical\Scripts\Discord\Send-FileToDiscord.ps1"

if ([string]::IsNullOrWhiteSpace($WebhookUrl)) {
    throw "Pass -WebhookUrl."
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -WebhookUrl $WebhookUrl -FromClipboard -Title $Title -Footer $Footer
