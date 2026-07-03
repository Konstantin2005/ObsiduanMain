$baseDir = "C:\obsidian\Main\Calendula\Вечно зеленные действия\Deystviya"

Write-Host "=== ORGANIZING ACTION FOLDERS ===" -ForegroundColor Green

# Create all target folders
$targetFolders = @("Vostavlyausya", "Delayu", "Issledovanie", "Razvitie", "Sozertanie")
foreach ($folder in $targetFolders) {
    $path = "$baseDir\$folder"
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "  [+] Created folder: $folder" -ForegroundColor Gray
    }
}

# Move files according to task description
# Neronki.md -> Issledovanie/
$srcNeronki = "$baseDir\Razvitie\Neronki.md"
$dstNeronki = "$baseDir\Issledovanie\Neronki.md"
if (Test-Path $srcNeronki) {
    Move-Item $srcNeronki $dstNeronki -Force
    Write-Host "  [OK] Neronki.md -> Issledovanie/" -ForegroundColor Green
}

# Burakratia.md -> Delayu/
$srcBura = "$baseDir\Razvitie\Burakratia.md"
$dstBura = "$baseDir\Delayu\Burakratia.md"
if (Test-Path $srcBura) {
    Move-Item $srcBura $dstBura -Force
    Write-Host "  [OK] Burakratia.md -> Delayu/" -ForegroundColor Green
}

# Speed writing.md -> Vostavlyausya/
$srcSpeedWrite = "$baseDir\Razvitie\Speed writing.md"
$dstSpeedWrite = "$baseDir\Vostavlyausya\Speed writing.md"
if (Test-Path $srcSpeedWrite) {
    Move-Item $srcSpeedWrite $dstSpeedWrite -Force
    Write-Host "  [OK] Speed writing.md -> Vostavlyausya/" -ForegroundColor Green
}

# Speed reading.md -> Vostavlyausya/
$srcSpeedRead = "$baseDir\Razvitie\Speed reading.md"
$dstSpeedRead = "$baseDir\Vostavlyausya\Speed reading.md"
if (Test-Path $srcSpeedRead) {
    Move-Item $srcSpeedRead $dstSpeedRead -Force
    Write-Host "  [OK] Speed reading.md -> Vostavlyausya/" -ForegroundColor Green
}

# Rename Razvitie -> Vostavlyausya
if (Test-Path "$baseDir\Vostavlyausya") {
    Remove-Item "$baseDir\Vostavlyausya" -Recurse -Force
}
Rename-Item -Path "$baseDir\Razvitie" -NewName "Vostavlyausya" -Force
Write-Host "  [+] Renamed Razvitie -> Vostavlyausya" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== FINAL STRUCTURE ===" -ForegroundColor Yellow

$folders = Get-ChildItem $baseDir
foreach ($folder in $folders) {
    $files = Get-ChildItem "$baseDir\$($folder.Name)" -File
    if ($files.Count -gt 0) {
        Write-Host ("  📂 " + $folder.Name + ": " + $files.Count + " files") -ForegroundColor Cyan
        # Show first 5 files to verify
        $files | Select-Object -First 5 | ForEach-Object { Write-Host ("      📄 " + $_.Name) -ForegroundColor Gray }
        if ($files.Count -gt 5) {
            Write-Host ("      ... and " + ($files.Count - 5) + " more files") -ForegroundColor Gray
        }
    } else {
        Write-Host ("  📁 " + $folder.Name + ": 0 files") -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "=== ORGANIZATION COMPLETE ===" -ForegroundColor Green