param(
    [string]$IssuesCsv = "2,3,4,8,9,10,11,12,15,16,54,55,56,57,58,59,60,62,63,66,73,74,86,87,88,94,95,97,99,102,103,104,105,106,113,114,115"
)

$steps = @(
    @{name="architect"; label="pipeline:architect"; emoji="Architect"; dir="00-architect"}
    @{name="backend"; label="pipeline:backend"; emoji="Backend Engineer"; dir="01-backend-engineer"}
    @{name="frontend"; label="pipeline:frontend"; emoji="Frontend Engineer"; dir="02-frontend-engineer"}
    @{name="qa"; label="pipeline:qa"; emoji="QA Engineer"; dir="03-qa-engineer"}
    @{name="code-review"; label="pipeline:code-review"; emoji="Code Review"; dir="04-code-reviewer"}
)

$issues = $IssuesCsv -split "," | ForEach-Object { $_.Trim() }
$created = 0
$failed = 0

foreach ($issueNum in $issues) {
    $origTitle = ""
    $origTitle = gh issue view $issueNum --json title -q ".title" 2> $null
    
    if (-not $origTitle) {
        Write-Host "[SKIP] Issue #$issueNum : could not fetch title, skipping"
        continue
    }
    
    $shortTitle = if ($origTitle.Length -gt 55) { $origTitle.Substring(0, 55) + "..." } else { $origTitle }
    Write-Host "[ISSUE #$issueNum] $shortTitle" -ForegroundColor Cyan
    
    foreach ($step in $steps) {
        $stepTitle = "[Pipeline/$($step.emoji)] #$issueNum : $shortTitle"
        
        $body = "## Pipeline Step: $($step.emoji)`n`n**Parent Issue:** #$issueNum`n**Work Directory:** .work/issues/`n`n## Status`n- [x] Step initiated`n- [ ] Artifacts created`n- [ ] Review completed"
        
        $result = gh issue create --title "$stepTitle" --body "$body" --label "$($step.label)" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  + $($step.emoji): $result" -ForegroundColor Green
            $created++
        } else {
            Write-Host "  - $($step.emoji): FAILED - $result" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "Created: $created" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
