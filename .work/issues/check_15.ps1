$testpath = '.work/issues/15-cpu-governor-worker-pool'
if (Test-Path $testpath) {
    Write-Host "Found work directory: $testpath" -ForegroundColor Green
    $files = Get-ChildItem -Recurse $testpath -File
    Write-Host "Files count: $($files.Count)"
    Write-Host "Most important files:"
    $archFiles = $files | Where-Object { $_.Name -match "(plan|architecture|decisions)\\.md$" }
    $backendFiles = $files | Where-Object { $_.Name -match "backend\\.(md|txt|js|py|ts)$" }
    $frontendFiles = $files | Where-Object { $_.Name -match "frontend\\.(md|txt|js|py|ts)$" }
    $qaFiles = $files | Where-Object { $_.Name -match "(test-cases|validation)\\.md$" }
    $reviewFiles = $files | Where-Object { $_.Name -match "review\\.md$" }
    
    if ($archFiles.Count -eq 3) { Write-Host "✅ ARCHITECT: Complete" }
    if ($backendFiles.Count -gt 0) { Write-Host "✅ BACKEND: Started" }
    if ($frontendFiles.Count -gt 0) { Write-Host "✅ FRONTEND: Started" }
    if ($qaFiles.Count -gt 0) { Write-Host "✅ QA: Started" }
    if ($reviewFiles.Count -gt 0) { Write-Host "✅ REVIEW: Started" }
    Write-Host ""
    Write-Host "Summary: $($files.Count) files exist - most developed stub"
} else {
    Write-Host "Work directory not found: $testpath" -ForegroundColor Red
}