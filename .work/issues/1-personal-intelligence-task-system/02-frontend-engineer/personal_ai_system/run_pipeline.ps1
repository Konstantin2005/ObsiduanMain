# PITS Pipeline Runner
Write-Host "PITS Pipeline" -ForegroundColor Cyan

# Step 1: Ingest diary files
Write-Host "`n[1/3] Ingesting diary files..." -ForegroundColor Yellow
python cli.py ingest

# Step 2: Show memory stats
Write-Host "`n[2/3] Memory summary:" -ForegroundColor Yellow
python cli.py memory --limit 5

# Step 3: Show pending suggestions
Write-Host "`n[3/3] Pending suggestions:" -ForegroundColor Yellow
python cli.py suggestions

Write-Host "`nDone." -ForegroundColor Green
