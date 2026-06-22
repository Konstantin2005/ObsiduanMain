$source = Get-Content "C:\obsidian\Main\IdeaEcosystem\generate.ps1" -Raw -Encoding UTF8
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText("C:\obsidian\Main\IdeaEcosystem\generate.ps1", $source, $utf8Bom)
Write-Host "BOM added successfully"
