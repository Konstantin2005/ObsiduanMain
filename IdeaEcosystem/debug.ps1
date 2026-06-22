$s = [System.IO.File]::ReadAllText('C:\obsidian\Main\IdeaEcosystem\generate.ps1')
$idx = $s.IndexOf('ci.Aggregate')
if ($idx -ge 0) {
    Write-Host "Found ci.Aggregate at index: $idx"
    Write-Host "Context: $($s.Substring($idx-10, 40))"
} else {
    Write-Host "ci.Aggregate NOT found"
}
