$s = [System.IO.File]::ReadAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1')
$old = '$ci.Aggregate'
$new = '$ci.Aggregate'
$s = $s.Replace($old, $new)
[System.IO.File]::WriteAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1', $s)
Write-Host "Fixed"
