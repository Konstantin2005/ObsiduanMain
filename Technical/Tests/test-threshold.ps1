. .\Scripts.Tests.ps1
$legacyScripts = @(
    (Join-Path 'C:\obsidian\Main' 'Старое\Calendula-People-Graph\run-hidden.vbs'),
    (Join-Path 'C:\obsidian\Main' 'Старое\Calendula-People-Graph-From-Branch\run-hidden.vbs'),
    (Join-Path 'C:\obsidian\Main' 'Technical\Scripts\Launchers\run-hidden.vbs')
)
foreach ($script in $legacyScripts) {
    (Get-Content $script -Raw) | Should Match 'Technical\\Scripts\\Git\\threshold-git\.ps1'
}