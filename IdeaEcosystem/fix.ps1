$s = [System.IO.File]::ReadAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1')
# Fix the template variable syntax for the Against field in here-string
$old = '${' + '$ci.Aggregate}'
$new = '$(' + '$ci.Aggregate)'
$s = $s.Replace($old, $new)
[System.IO.File]::WriteAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1', $s)
Write-Host "Fixed template variable syntax"
