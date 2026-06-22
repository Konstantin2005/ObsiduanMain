$s = [System.IO.File]::ReadAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1')

# Replace 'Aggregate' with 'Against' in template lines (ci.Aggregate -> ci.Aggregate)  
# The data uses 'Against' as field name but template references 'Aggregate'
$old = [char]0x0041 + [char]0x0067 + [char]0x0067 + [char]0x0072 + [char]0x0065 + [char]0x0067 + [char]0x0061 + [char]0x0074 + [char]0x0065  # Aggregate
$new = [char]0x0041 + [char]0x0067 + [char]0x0061 + [char]0x0069 + [char]0x006E + [char]0x0073 + [char]0x0074  # Against

$s = $s.Replace('ci.' + $old, 'ci.' + $new)
[System.IO.File]::WriteAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1', $s)
Write-Host "Fixed"
