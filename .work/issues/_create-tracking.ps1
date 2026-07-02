# Create tracking GitHub issues for existing work directories
$ErrorActionPreference = "Continue"

# Mapping: work dir -> issue number (known mappings)
$mappings = @{
    "2-live-graph-dedupe" = 2
    "3-reduce-repo-size" = 3
    "4-sync-perf-benchmarks" = 4
    "8-obsidian-discord-sync" = 8
    "9-speed-graph-update" = 9
    "10-background-people-links" = 10
    "11-worker-pool-calculations" = 11
    "12-cache-graph-layout" = 12
    "15-cpu-governor-worker-pool" = 15
    "16-shard-compaction" = 16
}

$steps = @("architect", "backend", "frontend", "qa", "code-review")
$stepLabels = @{
    architect = "pipeline:architect"
    backend = "pipeline:backend"
    frontend = "pipeline:frontend"
    qa = "pipeline:qa"
    "code-review" = "pipeline:code-review"
}
$stepEmoji = @{
    architect = "Architect"
    backend = "Backend Engineer"
    frontend = "Frontend Engineer"
    qa = "QA Engineer"
    "code-review" = "Code Review"
}

$totalCreated = 0

foreach ($dir in $mappings.Keys | Sort-Object) {
    $issueNum = $mappings[$dir]
    $workDir = ".work/issues/$dir"
    
    # Get original issue title
    $origTitle = (gh issue view $issueNum --json title -q ".title" 2>$null)
    if (-not $origTitle) {
        Write-Host "WARNING: Could not get title for issue #$issueNum, skipping"
        continue
    }
    
    Write-Host "`n=== Issue #$issueNum : $origTitle ===" -ForegroundColor Cyan
    
    foreach ($step in $steps) {
        $stepDir = "$workDir/$step"
        if ($step -eq "code-review") { $stepDir = "$workDir/04-code-reviewer" }
        elseif ($step -eq "architect") { $stepDir = "$workDir/00-architect" }
        elseif ($step -eq "backend") { $stepDir = "$workDir/01-backend-engineer" }
        elseif ($step -eq "frontend") { $stepDir = "$workDir/02-frontend-engineer" }
        elseif ($step -eq "qa") { $stepDir = "$workDir/03-qa-engineer" }
        
        $title = "[Pipeline/$($stepEmoji[$step])] #$issueNum : $(($origTitle -replace '"',"'").Substring(0,[Math]::Min(60, $origTitle.Length)))"
        
        $body = @"
## Pipeline Step: $($stepEmoji[$step])
**Parent Issue:** #$issueNum
**Work Directory:** `$workDir/$step

## Status
- [ ] Step initiated
- [ ] Artifacts created
- [ ] Review completed
"@
        
        Write-Host "  Creating: $title" -ForegroundColor Yellow
        $result = gh issue create --title "$title" --body "$body" --label "$($stepLabels[$step])" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    OK: $result" -ForegroundColor Green
            $totalCreated++
        } else {
            Write-Host "    FAIL: $result" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Total tracking issues created: $totalCreated ===" -ForegroundColor Green
