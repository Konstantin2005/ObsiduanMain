$base = "C:\obsidian\Main\Calendula\Вечно зеленные действия\Действия"

Write-Host "=== ORGANIZED ACTION FOLDERS ===" -ForegroundColor Green

# Rename Development -> Restoration (recovery/tech)
Rename-Item -Path "$base\Развитие" -NewName "Востанавливаюсь" -Force
Write-Host "✓ Development -> Востанавливаюсь" -ForegroundColor Green

# Final folder summary
Write-Host ""
Write-Host "=== FINAL STRUCTURE ===" -ForegroundColor Yellow

$folders = Get-ChildItem $base -Directory
foreach ($f in $folders) {
    $files = Get-ChildItem $f.FullName -File
    Write-Host ("  📂 " + $f.Name + ": " + $files.Count + " files") -ForegroundColor Cyan
    # Show first 5 files to verify
    $files | Select-Object -First 5 | ForEach-Object { Write-Host ("      📄 " + $_.Name) -ForegroundColor Gray }
    if ($files.Count -gt 5) {
        Write-Host ("      ... and " + ($files.Count - 5) + " more files") -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "=== DONE ===" -ForegroundColor Green