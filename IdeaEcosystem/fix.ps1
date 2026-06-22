$s = [System.IO.File]::ReadAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1')

# Build 'Aggregate' and 'Against' character by character
$aggBytes = [byte[]](0x41, 0x67, 0x67, 0x72, 0x65, 0x67, 0x61, 0x74, 0x65)  # Aggregate
$agnBytes = [byte[]](0x41, 0x67, 0x61, 0x69, 0x6E, 0x73, 0x74)              # Against

$agg = [System.Text.Encoding]::UTF8.GetString($aggBytes)
$agn = [System.Text.Encoding]::UTF8.GetString($agnBytes)

$s = $s.Replace('ci.' + $agg, 'ci.' + $agn)
[System.IO.File]::WriteAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1', $s)
Write-Host "Fixed Aggregate -> Against"
