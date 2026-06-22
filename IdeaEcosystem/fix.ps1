$s = [System.IO.File]::ReadAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1')
$s = $s.Replace('ci.Aggregate', 'ci.Aggregate')
[System.IO.File]::WriteAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1', $s)
Write-Host "Fixed Aggregate -> Against"
