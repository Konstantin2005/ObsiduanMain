param(
    [string]$VaultPath = "C:\obsidian\Main",
    [string]$ProblemsDir = (Join-Path $VaultPath "Problems"),
    [string]$CachePath = (Join-Path $VaultPath "Tasks\leetcode_problems_cache.json"),
    [string]$ExistingDir = (Join-Path $VaultPath "Tasks\LeetCode"),
    [string[]]$SolvedSlugs,
    [string]$ApiUrl = "https://leetcode-api-pied.vercel.app/user/Mr_Kefir/solved",
    [switch]$DryRun,
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot 'VaultHelpers.ps1')

Assert-PathInsideRoot -Root $VaultPath -Path $ProblemsDir -Operation 'sync_leetcode problems directory'
Assert-PathInsideRoot -Root $VaultPath -Path $CachePath -Operation 'sync_leetcode cache read'
Assert-PathInsideRoot -Root $VaultPath -Path $ExistingDir -Operation 'sync_leetcode existing directory'

$topicMap = @{
    "Array" = "Array"
    "Hash Table" = "Hash_Map"
    "String" = "String"
    "Binary Search" = "Binary_Searc"
    "Two Pointers" = "Two Pointer"
    "Linked List" = "Linked_List"
    "Recursion" = "Recursion"
    "Heap (Priority Queue)" = "Heap"
    "Sliding Window" = "Sliding Window"
    "Stack" = "Stack"
    "Prefix Sum" = "Prefix Sum"
    "Bit Manipulation" = "Bit Manipulation"
    "Hash Function" = "Hash_Map"
    "Sorting" = "Array"
    "Database" = "Array"
    "Dynamic Programming" = "Recursion"
    "Depth-First Search" = "Recursion"
    "Breadth-First Search" = "Recursion"
    "Tree" = "Recursion"
    "Binary Tree" = "Recursion"
    "Math" = "Array"
    "Matrix" = "Array"
    "Simulation" = "Array"
    "Counting" = "Hash_Map"
    "Greedy" = "Array"
    "Design" = "Array"
    "Enumeration" = "Array"
    "Backtracking" = "Recursion"
    "Queue" = "Stack"
    "Monotonic Stack" = "Stack"
    "Divide and Conquer" = "Recursion"
    "Merge Sort" = "Array"
    "Counting Sort" = "Array"
    "Bucket Sort" = "Array"
    "Radix Sort" = "Array"
    "Ordered Set" = "Heap"
    "Geometry" = "Array"
    "Number Theory" = "Array"
    "Combinatorics" = "Array"
    "Iterator" = "Array"
    "Game Theory" = "Array"
    "Reservoir Sampling" = "Array"
    "Memoization" = "Recursion"
    "Trie" = "Hash_Map"
    "Union Find" = "Hash_Map"
    "Graph" = "Hash_Map"
    "Topological Sort" = "Recursion"
    "Shortest Path" = "Recursion"
    "Minimum Spanning Tree" = "Recursion"
    "Strongly Connected Component" = "Recursion"
    "Rolling Hash" = "String"
    "Suffix Array" = "String"
    "Line Sweep" = "Array"
    "Brainteaser" = "Array"
    "Randomized" = "Array"
    "Monte Carlo" = "Array"
    "Rejection Sampling" = "Array"
    "Quickselect" = "Array"
    "Probability and Statistics" = "Array"
    "Doubly-Linked List" = "Linked_List"
    "Segment Tree" = "Binary_Searc"
    "Binary Indexed Tree" = "Binary_Searc"
    "Data Stream" = "Array"
    "Interactive" = "Array"
}

if (-not (Test-Path -LiteralPath $ProblemsDir)) {
    New-Item -ItemType Directory -Path $ProblemsDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $CachePath)) {
    throw "Cache file not found: $CachePath"
}

$cacheRaw = Get-Content -LiteralPath $CachePath -Raw -Encoding UTF8
$cache = $cacheRaw | ConvertFrom-Json
$slugToProblem = @{}
$idToProblem = @{}
foreach ($p in $cache) {
    $slugToProblem[$p.titleSlug] = $p
    $idToProblem[$p.frontendQuestionId] = $p
}

$resolvedSolved = [System.Collections.Generic.HashSet[string]]::new()
if ($SolvedSlugs) {
    foreach ($s in $SolvedSlugs) { $null = $resolvedSolved.Add($s) }
} else {
    Write-Host "Fetching recent solved problems from API..."
    try {
        $solvedResp = Invoke-RestMethod -Uri $ApiUrl -Method Get -TimeoutSec 15
        foreach ($s in $solvedResp.solved_slugs) { $null = $resolvedSolved.Add($s) }
    } catch {
        Write-Host "  WARNING: API failed: $($_.Exception.Message)"
    }
}

if (Test-Path -LiteralPath $ExistingDir) {
    $existingFiles = Get-ChildItem -LiteralPath $ExistingDir -Filter "*.md"
    foreach ($f in $existingFiles) {
        if ($f.BaseName -match '^(\d+)\.\s+(.*)') {
            $problemId = $Matches[1]
            if ($idToProblem.ContainsKey($problemId)) {
                $null = $resolvedSolved.Add($idToProblem[$problemId].titleSlug)
            }
        }
    }
}

$generated = 0
$skipped = 0
$moveDetails = @()
$sortedSlugs = $resolvedSolved | Sort-Object

foreach ($slug in $sortedSlugs) {
    if (-not $slugToProblem.ContainsKey($slug)) {
        continue
    }

    $problem = $slugToProblem[$slug]
    $id = $problem.frontendQuestionId
    $title = $problem.title
    $difficulty = $problem.difficulty
    $tags = $problem.topicTags

    $fileName = "$id. $title.md"
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $fileName = [regex]::Replace($fileName, "[$invalidChars]", '')
    $filePath = [System.IO.Path]::Combine($ProblemsDir, $fileName)

    if (Test-Path -LiteralPath $filePath) {
        $skipped++
        continue
    }

    $selectedTopics = @()
    foreach ($t in $tags) {
        $apiName = $t.name
        if ($topicMap.ContainsKey($apiName)) {
            $mapped = $topicMap[$apiName]
            if ($mapped -notin $selectedTopics) { $selectedTopics += $mapped }
        } else {
            $safeName = $apiName.Replace(" ", "_").Replace("-", "_")
            if ($safeName -notin $selectedTopics) { $selectedTopics += $safeName }
        }
        if ($selectedTopics.Count -ge 2) { break }
    }

    $topicFrontmatter = if ($selectedTopics.Count -gt 0) { $selectedTopics[0] } else { "" }
    $topicContent = if ($selectedTopics.Count -gt 0) { ($selectedTopics | ForEach-Object { "[[$_]]" }) -join " " } else { "" }
    $diffFrontmatter = $difficulty.Substring(0,1).ToUpper() + $difficulty.Substring(1).ToLower()

    $lines = @(
        "---",
        "type: problem",
        "difficulty: $diffFrontmatter",
        "topic: [[$topicFrontmatter]]",
        "leetcode_id: $id",
        "---",
        "",
        "# $title",
        "",
        "**Difficulty:** $difficulty",
        ""
    )
    if ($selectedTopics.Count -gt 0) {
        $lines += "**Topic:** $topicContent"
        $lines += ""
    }
    $lines += "**LeetCode Link:** https://leetcode.com/problems/$slug/"
    $lines += ""
    $lines += "**Status:** Solved"
    $lines += ""
    $lines += "#$difficulty"

    $content = $lines -join "`n"
    if (-not $DryRun) {
        Assert-SafeBulkOperation -Operation 'sync_leetcode problem write' -Root $VaultPath -TargetPaths @($filePath) -DryRun:$DryRun
        Write-Utf8Text -Path $filePath -Content $content
    }
    $generated++
    $moveDetails += [pscustomobject]@{
        Slug = $slug
        FilePath = $filePath
        LeetCodeId = $id
    }
}

Write-Host "Done!"
Write-Host "  Generated: $generated new files"
Write-Host "  Skipped (already exist): $skipped"
Write-Host "  Total known solved: $($resolvedSolved.Count)"

if ($PassThru) {
    [pscustomobject]@{
        Generated = $generated
        Skipped = $skipped
        TotalSolved = $resolvedSolved.Count
        Details = $moveDetails
        DryRun = [bool]$DryRun
    }
}
