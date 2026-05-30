$vaultPath = "C:\obsidian\Main"
$problemsDir = [System.IO.Path]::Combine($vaultPath, "Problems")
$cachePath = [System.IO.Path]::Combine($vaultPath, "Tasks", "leetcode_problems_cache.json")
$existingDir = [System.IO.Path]::Combine($vaultPath, "Tasks", "LeetCode")
$utf8 = [System.Text.UTF8Encoding]::new($false)

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

if (-not (Test-Path -LiteralPath $problemsDir)) {
    New-Item -ItemType Directory -Path $problemsDir -Force | Out-Null
    Write-Host "Created directory: $problemsDir"
}

if (Test-Path -LiteralPath $cachePath) {
    $cacheRaw = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8
    $cache = $cacheRaw | ConvertFrom-Json
    $slugToProblem = @{}
    $idToProblem = @{}
    foreach ($p in $cache) {
        $slugToProblem[$p.titleSlug] = $p
        $idToProblem[$p.frontendQuestionId] = $p
    }
    Write-Host "Loaded $($cache.Count) problems from cache"
} else {
    Write-Host "ERROR: Cache file not found at $cachePath. Run fetch first."
    exit 1
}

$solvedSlugs = [System.Collections.Generic.HashSet[string]]::new()

Write-Host "Fetching recent solved problems from API..."
try {
    $solvedResp = Invoke-RestMethod -Uri "https://leetcode-api-pied.vercel.app/user/Mr_Kefir/solved" -Method Get -TimeoutSec 15
    foreach ($s in $solvedResp.solved_slugs) {
        $null = $solvedSlugs.Add($s)
    }
    Write-Host "  Found $($solvedResp.solved_slugs.Count) from API"
} catch {
    Write-Host "  WARNING: API failed: $($_.Exception.Message)"
}

Write-Host "Scanning existing files in $existingDir..."
$existingFiles = Get-ChildItem -LiteralPath $existingDir -Filter "*.md"
$fileCount = 0
foreach ($f in $existingFiles) {
    $name = $f.BaseName
    if ($name -match '^(\d+)\.\s+(.*)') {
        $problemId = $Matches[1]
        if ($idToProblem.ContainsKey($problemId)) {
            $null = $solvedSlugs.Add($idToProblem[$problemId].titleSlug)
            $fileCount++
        }
    }
}
Write-Host "  Found $fileCount existing problem files"

Write-Host "`nGenerating problem files in $problemsDir..."
$generated = 0
$skipped = 0
$sortedSlugs = $solvedSlugs | Sort-Object
foreach ($slug in $sortedSlugs) {
    if (-not $slugToProblem.ContainsKey($slug)) {
        Write-Host "  WARNING: No cache data for slug: $slug"
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
    $filePath = [System.IO.Path]::Combine($problemsDir, $fileName)

    if (Test-Path -LiteralPath $filePath) {
        $skipped++
        continue
    }

    $selectedTopics = @()
    foreach ($t in $tags) {
        $apiName = $t.name
        if ($topicMap.ContainsKey($apiName)) {
            $mapped = $topicMap[$apiName]
            if ($mapped -notin $selectedTopics) {
                $selectedTopics += $mapped
            }
        } else {
            $safeName = $apiName.Replace(" ", "_").Replace("-", "_")
            if ($safeName -notin $selectedTopics) {
                $selectedTopics += $safeName
            }
        }
        if ($selectedTopics.Count -ge 2) { break }
    }

    $topicLine = ""
    $topicFrontmatter = ""
    $topicContent = ""
    if ($selectedTopics.Count -gt 0) {
        $topicFrontmatter = $selectedTopics[0]
        $topicContent = ($selectedTopics | ForEach-Object { "[[$_]]" }) -join " "
        $topicLine = $selectedTopics[0]
    }

    $diffTag = "#$difficulty"
    $diffLower = $difficulty.ToLower()
    $diffFrontmatter = $difficulty.Substring(0,1).ToUpper() + $difficulty.Substring(1).ToLower()

    $lines = @()
    $lines += "---"
    $lines += "type: problem"
    $lines += "difficulty: $diffFrontmatter"
    $lines += "topic: [[$topicFrontmatter]]"
    $lines += "leetcode_id: $id"
    $lines += "---"
    $lines += ""
    $lines += "# $title"
    $lines += ""
    $lines += "**Difficulty:** $difficulty"
    $lines += ""
    if ($selectedTopics.Count -gt 0) {
        $lines += "**Topic:** $topicContent"
        $lines += ""
    }
    $lines += "**LeetCode Link:** https://leetcode.com/problems/$slug/"
    $lines += ""
    $lines += "**Status:** ✅ Solved"
    $lines += ""
    $lines += $diffTag

    $content = $lines -join "`n"
    [System.IO.File]::WriteAllText($filePath, $content, $utf8)
    $generated++

    if ($generated % 10 -eq 0) {
        Write-Host "  Generated $generated files..."
    }
}

Write-Host "`nDone!"
Write-Host "  Generated: $generated new files"
Write-Host "  Skipped (already exist): $skipped"
Write-Host "  Total known solved: $($solvedSlugs.Count)"
Write-Host ""
Write-Host "NOTE: LeetCode API only exposes the last ~20 submissions."
Write-Host "Your profile shows 340 solved, but only $($solvedSlugs.Count) are retrievable via public API."
Write-Host "Re-run this script periodically to pick up new solves."
Write-Host "For full export, use a LeetCode export tool with your session cookie."
