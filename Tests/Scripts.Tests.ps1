$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'Scripts\Vault\VaultHelpers.ps1')

function New-TempRoot {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

function Initialize-CollectMentionsVault {
    param([Parameter(Mandatory = $true)][string]$Root)

    $diaryRoot = Join-Path $Root 'Calendula\Calendula'
    $socialRoot = Join-Path $Root 'Calendula\Соц Капитал'
    New-Item -ItemType Directory -Path (Join-Path $diaryRoot '2026\Июнь') -Force | Out-Null
    New-Item -ItemType Directory -Path $socialRoot -Force | Out-Null

    Write-Utf8Text -Path (Join-Path $socialRoot 'John.md') -Content @"
---
name: John
---
"@

    Write-Utf8Text -Path (Join-Path $socialRoot 'Mary.md') -Content @"
---
name: Mary
---
"@

    Write-Utf8Text -Path (Join-Path $socialRoot 'Alex.md') -Content @"
---
name: Alex
---
"@

    Write-Utf8Text -Path (Join-Path $diaryRoot '2026\Июнь\01-06-26.md') -Content @"
# Дневник 1

Сегодня видел [[John]] и Mary.

Вечером снова встретил John.
"@

    Write-Utf8Text -Path (Join-Path $diaryRoot '2026\Июнь\02-06-26.md') -Content @"
# Дневник 2

Alex пришёл раньше.

Потом John и Mary обсуждали планы.
"@

    Write-Utf8Text -Path (Join-Path $diaryRoot '2026\Июнь\03-06-26.md') -Content @"
# Дневник 3

Mary помогла Alex.

John пришёл позже и снова встретил Mary.
"@
}

Describe 'Scripts' {
    Context 'VaultHelpers' {
        It 'maps month numbers to Russian names' {
            Get-MonthName -Month 6 | Should Be 'Июнь'
        }

        It 'returns null when a section heading is missing' {
            (Get-SectionRange -Lines @('alpha', 'beta') -Heading 'Сегодня') | Should Be $null
        }

        It 'detects trailing newline style' {
            Get-TrailingNewline "hello`r`n" | Should Be "`r`n"
        }

        It 'guards writes so they stay inside the declared root' {
            $root = New-TempRoot
            try {
                $inside = Join-Path $root 'inside\note.md'
                $outside = Join-Path ([System.IO.Directory]::GetParent($root).FullName) 'outside-note.md'

                (Test-PathInsideRoot -Root $root -Path $inside) | Should Be $true
                (Test-PathInsideRoot -Root $root -Path $outside) | Should Be $false
                { Assert-PathInsideRoot -Root $root -Path $outside -Operation 'test operation' } | Should Throw
            }
            finally {
                if (Test-Path -LiteralPath $root) {
                    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'requires Force for destructive bulk operations' {
            $root = New-TempRoot
            try {
                $file = Join-Path $root 'delete-me.md'
                Write-Utf8Text -Path $file -Content 'delete me'

                { Assert-SafeBulkOperation -Operation 'test cleanup' -Root $root -TargetPaths @($file) -Destructive } | Should Throw
                { Assert-SafeBulkOperation -Operation 'test cleanup' -Root $root -TargetPaths @($file) -Destructive -Force } | Should Not Throw
                { Assert-SafeBulkOperation -Operation 'test cleanup' -Root $root -TargetPaths @($file) -Destructive -DryRun } | Should Not Throw
            }
            finally {
                if (Test-Path -LiteralPath $root) {
                    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It 'daily-push invokes git steps in order and writes a success log' {
        $root = New-TempRoot
        try {
            $repo = Join-Path $root 'repo'
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            $fakeGit = Join-Path $root 'fake-git.ps1'
            $gitCalls = Join-Path $root 'git-calls.txt'
            $logPath = Join-Path $repo 'Scripts\Logs\daily-push.log'

            Write-Utf8Text -Path $fakeGit -Content @"
Add-Content -LiteralPath '$gitCalls' -Value (`$args -join ' ')
exit 0
"@

            & (Join-Path $repoRoot 'Scripts\Git\daily-push.ps1') -RepoPath $repo -Branch 'develop' -GitPath $fakeGit -LogPath $logPath

            $calls = Get-Content -LiteralPath $gitCalls -Encoding UTF8
            $calls.Count | Should Be 3
            $calls[0] | Should Match '^fetch '
            $calls[1] | Should Match '^pull '
            $calls[2] | Should Match '^push origin develop$'
            (Read-Utf8Text -Path $logPath) | Should Match 'Push completed successfully\.'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'daily-push dry run skips git commands' {
        $root = New-TempRoot
        try {
            $repo = Join-Path $root 'repo'
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            $fakeGit = Join-Path $root 'fake-git.ps1'
            $gitCalls = Join-Path $root 'git-calls.txt'
            $logPath = Join-Path $repo 'Scripts\Logs\daily-push.log'

            Write-Utf8Text -Path $fakeGit -Content @"
Add-Content -LiteralPath '$gitCalls' -Value (`$args -join ' ')
exit 0
"@

            & (Join-Path $repoRoot 'Scripts\Git\daily-push.ps1') -RepoPath $repo -GitPath $fakeGit -LogPath $logPath -DryRun

            Test-Path -LiteralPath $gitCalls | Should Be $false
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Move-TodayTasks moves dated tasks from Запланировано to Сегодня' {
        $root = New-TempRoot
        try {
            $plan = Join-Path $root 'Calendula\План'
            $yearDir = Join-Path $plan '2026'
            New-Item -ItemType Directory -Path $yearDir -Force | Out-Null
            $file = Join-Path $yearDir '2026 - Июнь.md'
            $initial = @"
## Запланировано

- [ ] Сделать тест @{2026-06-10}
- [ ] Остаться здесь @{2026-06-11}

## Сегодня

- [ ] Уже есть задача
"@
            Write-Utf8Text -Path $file -Content $initial

            & (Join-Path $repoRoot 'Scripts\Vault\Move-TodayTasks.ps1') -Date '2026-06-10' -KanbanDir $plan

            $content = Read-Utf8Text -Path $file
            $plannedSection = ($content -split '## Сегодня', 2)[0]
            $todaySection = ($content -split '## Сегодня', 2)[1]
            $todaySection | Should Match 'Сделать тест @\{2026-06-10\}'
            $plannedSection | Should Not Match 'Сделать тест @\{2026-06-10\}'
            $plannedSection | Should Match 'Остаться здесь @\{2026-06-11\}'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Move-TodayTasks leaves the file unchanged when no task matches the date' {
        $root = New-TempRoot
        try {
            $plan = Join-Path $root 'Calendula\План'
            $yearDir = Join-Path $plan '2026'
            New-Item -ItemType Directory -Path $yearDir -Force | Out-Null
            $file = Join-Path $yearDir '2026 - Июнь.md'
            $initial = @"
## Запланировано

- [ ] Остаться здесь @{2026-06-11}

## Сегодня

- [ ] Уже есть задача
"@
            Write-Utf8Text -Path $file -Content $initial

            & (Join-Path $repoRoot 'Scripts\Vault\Move-TodayTasks.ps1') -Date '2026-06-10' -KanbanDir $plan

            (Read-Utf8Text -Path $file) | Should Be $initial
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Sort-BoardTasks moves tasks to the correct month board' {
        $root = New-TempRoot
        try {
            $plan = Join-Path $root 'Calendula\План'
            $yearDir = Join-Path $plan '2026'
            New-Item -ItemType Directory -Path $yearDir -Force | Out-Null
            $june = Join-Path $yearDir '2026 - Июнь.md'
            $july = Join-Path $yearDir '2026 - Июль.md'
            Write-Utf8Text -Path $june -Content @"
## Запланировано

- [ ] Перенести в июль @{2026-07-01}

## Сегодня
"@
            Write-Utf8Text -Path $july -Content @"
## Запланировано

## Сегодня
"@

            & (Join-Path $repoRoot 'Scripts\Vault\Sort-BoardTasks.ps1') -KanbanDir $plan

            (Read-Utf8Text -Path $june) | Should Not Match 'Перенести в июль'
            (Read-Utf8Text -Path $july) | Should Match 'Перенести в июль @\{2026-07-01\}'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Sort-BoardTasks deduplicates repeated tasks when moving boards' {
        $root = New-TempRoot
        try {
            $plan = Join-Path $root 'Calendula\План'
            $yearDir = Join-Path $plan '2026'
            New-Item -ItemType Directory -Path $yearDir -Force | Out-Null
            $june = Join-Path $yearDir '2026 - Июнь.md'
            $july = Join-Path $yearDir '2026 - Июль.md'
            Write-Utf8Text -Path $june -Content @"
## Запланировано

- [ ] Перенести в июль @{2026-07-01}
- [ ] Перенести в июль @{2026-07-01}

## Сегодня
"@
            Write-Utf8Text -Path $july -Content @"
## Запланировано

## Сегодня
"@

            & (Join-Path $repoRoot 'Scripts\Vault\Sort-BoardTasks.ps1') -KanbanDir $plan

            [regex]::Matches((Read-Utf8Text -Path $july), [regex]::Escape('Перенести в июль @{2026-07-01}')).Count | Should Be 1
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'collect-mentions writes a mentions section for detected people' {
        $root = New-TempRoot
        try {
            $diaryRoot = Join-Path $root 'Calendula\Calendula'
            $socialRoot = Join-Path $root 'Calendula\Соц Капитал'
            $diaryFile = Join-Path $diaryRoot '2026\Июнь\01-06-26.md'
            $personFile = Join-Path $socialRoot 'John.md'

            Write-Utf8Text -Path $diaryFile -Content @"
# Дневник

Сегодня видел [[John]] на улице #Обычный
"@
            Write-Utf8Text -Path $personFile -Content @"
---
name: John
---
"@

            & (Join-Path $repoRoot 'Scripts\Vault\collect-mentions.ps1') -VaultPath $root -DiaryRoot $diaryRoot -SocialCapitalRoot $socialRoot

            $personContent = Read-Utf8Text -Path $personFile
            $personContent | Should Match '## Упоминания в дневниках'
            $personContent | Should Match '\*\*2026/Июнь/01-06-26\.md\*\*'
            $personContent | Should Not Match '#Обычный'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'collect-mentions replaces an existing mentions section instead of appending another one' {
        $root = New-TempRoot
        try {
            $diaryRoot = Join-Path $root 'Calendula\Calendula'
            $socialRoot = Join-Path $root 'Calendula\Соц Капитал'
            $diaryFile = Join-Path $diaryRoot '2026\Июнь\01-06-26.md'
            $personFile = Join-Path $socialRoot 'John.md'

            Write-Utf8Text -Path $diaryFile -Content @"
# Дневник

Сегодня видел John на улице
"@
            Write-Utf8Text -Path $personFile -Content @"
---
name: John
---

## Упоминания в дневниках

старое
"@

            & (Join-Path $repoRoot 'Scripts\Vault\collect-mentions.ps1') -VaultPath $root -DiaryRoot $diaryRoot -SocialCapitalRoot $socialRoot

            $personContent = Read-Utf8Text -Path $personFile
            [regex]::Matches($personContent, '## Упоминания в дневниках').Count | Should Be 1
            $personContent | Should Not Match 'старое'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'collect-mentions produces the same result with parallel and serial scans' {
        $serialRoot = New-TempRoot
        $parallelRoot = New-TempRoot
        try {
            Initialize-CollectMentionsVault -Root $serialRoot
            Initialize-CollectMentionsVault -Root $parallelRoot

            & (Join-Path $repoRoot 'Scripts\Vault\collect-mentions.ps1') -VaultPath $serialRoot -DiaryRoot (Join-Path $serialRoot 'Calendula\Calendula') -SocialCapitalRoot (Join-Path $serialRoot 'Calendula\Соц Капитал') -ThrottleLimit 1
            & (Join-Path $repoRoot 'Scripts\Vault\collect-mentions.ps1') -VaultPath $parallelRoot -DiaryRoot (Join-Path $parallelRoot 'Calendula\Calendula') -SocialCapitalRoot (Join-Path $parallelRoot 'Calendula\Соц Капитал') -ThrottleLimit 4

            $people = 'Alex', 'John', 'Mary'
            foreach ($name in $people) {
                $serialFile = Join-Path $serialRoot "Calendula\Соц Капитал\$name.md"
                $parallelFile = Join-Path $parallelRoot "Calendula\Соц Капитал\$name.md"
                (Read-Utf8Text -Path $serialFile) | Should Be (Read-Utf8Text -Path $parallelFile)
            }
        }
        finally {
            foreach ($root in @($serialRoot, $parallelRoot)) {
                if (Test-Path -LiteralPath $root) {
                    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It 'Normalize-DayNoteNumbers renames numbered notes and updates references' {
        $root = New-TempRoot
        try {
            $diaryRoot = Join-Path $root 'Calendula\Calendula'
            $monthDir = Join-Path $diaryRoot '2026\Июнь'
            $mainNote = Join-Path $monthDir '1-6-26.md'
            $numberedNote = Join-Path $monthDir '1.1-6-26.md'
            $refs = Join-Path $diaryRoot 'refs.md'

            Write-Utf8Text -Path $mainNote -Content 'main'
            Write-Utf8Text -Path $numberedNote -Content 'numbered'
            Write-Utf8Text -Path $refs -Content 'link: 1.1-6-26.md'

            & (Join-Path $repoRoot 'Scripts\Vault\Normalize-DayNoteNumbers.ps1') -VaultPath $root -DiaryRoot $diaryRoot

            Test-Path -LiteralPath (Join-Path $monthDir '02.1-6-26.md') | Should Be $true
            Test-Path -LiteralPath $numberedNote | Should Be $false
            (Read-Utf8Text -Path $refs) | Should Match 'link: 02\.1-6-26\.md'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Normalize-DayNoteNumbers fails when a rename target already exists' {
        $root = New-TempRoot
        try {
            $diaryRoot = Join-Path $root 'Calendula\Calendula'
            $monthDir = Join-Path $diaryRoot '2026\Июнь'
            $mainNote = Join-Path $monthDir '1-6-26.md'
            $numberedNote = Join-Path $monthDir '1.1-6-26.md'
            $conflict = Join-Path $monthDir '02.1-6-26.md'

            Write-Utf8Text -Path $mainNote -Content 'main'
            Write-Utf8Text -Path $numberedNote -Content 'numbered'
            New-Item -ItemType Directory -Path $conflict -Force | Out-Null

            { & (Join-Path $repoRoot 'Scripts\Vault\Normalize-DayNoteNumbers.ps1') -VaultPath $root -DiaryRoot $diaryRoot } | Should Throw
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'generate_terms_v2 creates term files in a test vault' {
        $root = New-TempRoot
        try {
            & (Join-Path $repoRoot 'Scripts\Vault\generate_terms_v2.ps1') -VaultPath $root -MaxWords 3

            $files = Get-ChildItem -LiteralPath $root -File -Filter '*.md'
            $files.Count | Should Be 3
            $sample = Read-Utf8Text -Path $files[0].FullName
            $sample | Should Match 'type: term'
            $sample | Should Match '## Abstractions'
            $sample | Should Match '\[\[.+\]\]'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'generate_terms_v2 dry run does not create files' {
        $root = New-TempRoot
        try {
            $existing = Join-Path $root 'keep.md'
            Write-Utf8Text -Path $existing -Content 'keep'

            & (Join-Path $repoRoot 'Scripts\Vault\generate_terms_v2.ps1') -VaultPath $root -MaxWords 2 -DryRun

            Test-Path -LiteralPath $existing | Should Be $true
            (Get-ChildItem -LiteralPath $root -File -Filter '*.md').Count | Should Be 1
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'generate_terms_v2 refuses destructive cleanup without Force' {
        $root = New-TempRoot
        try {
            $existing = Join-Path $root 'keep.md'
            Write-Utf8Text -Path $existing -Content 'keep'

            { & (Join-Path $repoRoot 'Scripts\Vault\generate_terms_v2.ps1') -VaultPath $root -MaxWords 1 } | Should Throw

            & (Join-Path $repoRoot 'Scripts\Vault\generate_terms_v2.ps1') -VaultPath $root -MaxWords 1 -Force

            Test-Path -LiteralPath $existing | Should Be $false
            (Get-ChildItem -LiteralPath $root -File -Filter '*.md').Count | Should Be 1
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'sync_leetcode generates problem notes from solved slugs and cache' {
        $root = New-TempRoot
        try {
            $tasksDir = Join-Path $root 'Tasks'
            $problemsDir = Join-Path $root 'Problems'
            $existingDir = Join-Path $tasksDir 'LeetCode'
            New-Item -ItemType Directory -Path $existingDir -Force | Out-Null

            $cachePath = Join-Path $tasksDir 'leetcode_problems_cache.json'
            $cache = @(
                @{
                    titleSlug = 'two-sum'
                    frontendQuestionId = '1'
                    title = 'Two Sum'
                    difficulty = 'Easy'
                    topicTags = @(@{ name = 'Array' })
                },
                @{
                    titleSlug = 'add-two-numbers'
                    frontendQuestionId = '2'
                    title = 'Add Two Numbers'
                    difficulty = 'Medium'
                    topicTags = @(@{ name = 'Linked List' })
                }
            ) | ConvertTo-Json -Depth 5
            Write-Utf8Text -Path $cachePath -Content $cache

            & (Join-Path $repoRoot 'Scripts\Vault\sync_leetcode.ps1') -VaultPath $root -ProblemsDir $problemsDir -CachePath $cachePath -ExistingDir $existingDir -SolvedSlugs @('two-sum')

            $problemFile = Join-Path $problemsDir '1. Two Sum.md'
            Test-Path -LiteralPath $problemFile | Should Be $true
            $content = Read-Utf8Text -Path $problemFile
            $content | Should Match 'type: problem'
            $content | Should Match 'leetcode_id: 1'
            $content | Should Match '\*\*Status:\*\* Solved'
            $content | Should Match '\[\[Array\]\]'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'sync_leetcode skips files that already exist and reports zero new files' {
        $root = New-TempRoot
        try {
            $tasksDir = Join-Path $root 'Tasks'
            $problemsDir = Join-Path $root 'Problems'
            $existingDir = Join-Path $tasksDir 'LeetCode'
            New-Item -ItemType Directory -Path $existingDir -Force | Out-Null

            $cachePath = Join-Path $tasksDir 'leetcode_problems_cache.json'
            $cache = @(
                @{
                    titleSlug = 'two-sum'
                    frontendQuestionId = '1'
                    title = 'Two Sum'
                    difficulty = 'Easy'
                    topicTags = @(@{ name = 'Array' })
                }
            ) | ConvertTo-Json -Depth 5
            Write-Utf8Text -Path $cachePath -Content $cache

            New-Item -ItemType Directory -Path $problemsDir -Force | Out-Null
            Write-Utf8Text -Path (Join-Path $problemsDir '1. Two Sum.md') -Content 'existing'

            $result = & (Join-Path $repoRoot 'Scripts\Vault\sync_leetcode.ps1') -VaultPath $root -ProblemsDir $problemsDir -CachePath $cachePath -ExistingDir $existingDir -SolvedSlugs @('two-sum', 'two-sum') -PassThru

            $result.Generated | Should Be 0
            $result.Skipped | Should Be 1
            (Read-Utf8Text -Path (Join-Path $problemsDir '1. Two Sum.md')) | Should Be 'existing'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Calendula-20K rendering profile' {
    It 'keeps the generated graph resolved, balanced, and startup-safe' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(() => {
  const fs = require('fs');
  const path = require('path');
  const root = path.join(__REPO_ROOT__, 'Calendula-20K');
  const linkRe = /\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]/g;

  function walk(dir) {
    const out = [];
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        out.push(...walk(full));
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        out.push(full);
      }
    }
    return out;
  }

  function vaultPath(file) {
    return path.relative(root, file).replace(/\\/g, '/');
  }

  function basename(file) {
    return path.basename(file, '.md');
  }

  const files = walk(root).filter((file) => !vaultPath(file).startsWith('.obsidian/')).sort();
  const byPath = new Map(files.map((file) => [vaultPath(file).replace(/\.md$/i, ''), file]));
  const byBase = new Map();
  const duplicateBasenames = new Set();

  for (const file of files) {
    const base = basename(file);
    if (byBase.has(base)) {
      duplicateBasenames.add(base);
    } else {
      byBase.set(base, file);
    }
  }

  const outDegree = new Map(files.map((file) => [vaultPath(file), 0]));
  const inDegree = new Map(files.map((file) => [vaultPath(file), 0]));
  let edgeCount = 0;
  let unresolved = 0;
  let backboneCount = 0;
  let backboneEdges = 0;

  for (const file of files) {
    const source = vaultPath(file);
    const text = fs.readFileSync(file, 'utf8');
    const isBackbone = text.includes('#graph/backbone');
    if (isBackbone) {
      backboneCount += 1;
      if (text.includes('Backbone link: [[')) {
        backboneEdges += 1;
      }
    }
    let match;
    while ((match = linkRe.exec(text))) {
      edgeCount += 1;
      outDegree.set(source, outDegree.get(source) + 1);
      const target = match[1].trim().replace(/\.md$/i, '');
      const resolved = byPath.get(target) || byBase.get(path.basename(target));
      if (resolved) {
        const resolvedPath = vaultPath(resolved);
        inDegree.set(resolvedPath, inDegree.get(resolvedPath) + 1);
      } else {
        unresolved += 1;
      }
    }
  }

  const zeroOut = [...outDegree.values()].filter((value) => value === 0).length;
  const zeroIn = [...inDegree.values()].filter((value) => value === 0).length;
  const graph = JSON.parse(fs.readFileSync(path.join(root, '.obsidian', 'graph.json'), 'utf8'));
  const profiles = JSON.parse(fs.readFileSync(path.join(root, '.obsidian', 'graph-profiles.json'), 'utf8'));
  const workspace = JSON.parse(fs.readFileSync(path.join(root, '.obsidian', 'workspace.json'), 'utf8'));
  const plugins = JSON.parse(fs.readFileSync(path.join(root, '.obsidian', 'core-plugins.json'), 'utf8'));
  const communityPlugins = JSON.parse(fs.readFileSync(path.join(root, '.obsidian', 'community-plugins.json'), 'utf8'));
  const enabledPlugins = Object.entries(plugins).filter(([, enabled]) => enabled).map(([name]) => name).sort();
  const expectedPlugins = ['command-palette', 'editor-status', 'file-explorer', 'graph', 'switcher'];
  const mainTabs = workspace.main.children[0].children.map((child) => child.state.type);
  const guardManifestPath = path.join(root, '.obsidian', 'plugins', 'calendula-graph-guard', 'manifest.json');
  const guardMainPath = path.join(root, '.obsidian', 'plugins', 'calendula-graph-guard', 'main.js');
  const ultraManifestPath = path.join(root, '.obsidian', 'plugins', 'calendula-ultra-graph', 'manifest.json');
  const ultraMainPath = path.join(root, '.obsidian', 'plugins', 'calendula-ultra-graph', 'main.js');
  const ultraStylesPath = path.join(root, '.obsidian', 'plugins', 'calendula-ultra-graph', 'styles.css');

  if (files.length < 30000) throw new Error(`Expected at least 30000 notes, got ${files.length}`);
  if (duplicateBasenames.size) throw new Error(`Duplicate basenames: ${[...duplicateBasenames].slice(0, 5).join(', ')}`);
  if (backboneCount < 1000 || backboneCount > 2500) throw new Error(`Unexpected backbone size: ${backboneCount}`);
  if (backboneEdges !== backboneCount) throw new Error(`Expected one backbone edge per backbone node, got ${backboneEdges}/${backboneCount}`);
  if (edgeCount !== files.length + backboneCount) throw new Error(`Expected ring plus backbone edges, got ${edgeCount} for ${files.length} files and ${backboneCount} backbone nodes`);
  if (unresolved !== 0) throw new Error(`Expected no unresolved links, got ${unresolved}`);
  if (zeroOut !== 0 || zeroIn !== 0) throw new Error(`Expected balanced graph, got zeroOut=${zeroOut}, zeroIn=${zeroIn}`);
  if (profiles.schemaVersion !== 6) throw new Error(`Expected graph profile schema v6, got ${profiles.schemaVersion}`);
  if (profiles.startupProfile !== 'fast-backbone') throw new Error(`Expected fast-backbone startup profile, got ${profiles.startupProfile}`);
  if (!profiles.profiles['fast-backbone']?.startupAllowed) throw new Error('fast-backbone must be startupAllowed');
  if (profiles.profiles['fast-backbone']?.graphSettings?.search !== 'tag:#graph/backbone') throw new Error('fast-backbone graph settings are invalid');
  if (profiles.profiles['full-danger']?.startupAllowed) throw new Error('full-danger cannot be startupAllowed');
  if (!profiles.profiles['full-danger']?.danger) throw new Error('full-danger must be marked dangerous');
  if (!graph.hideUnresolved || graph.showOrphans) throw new Error('Graph settings should hide unresolved links and orphans');
  if (graph.search !== 'tag:#graph/backbone') throw new Error(`Expected fast backbone graph search, got ${graph.search}`);
  if (workspace.active !== 'calendula-20k-fast-graph') throw new Error(`Workspace active pane is ${workspace.active}`);
  if (mainTabs.length !== 1 || mainTabs[0] !== 'graph') throw new Error(`Workspace should open one filtered graph tab, got ${mainTabs.join(', ')}`);
  if (!communityPlugins.includes('calendula-graph-guard')) throw new Error('Calendula graph guard plugin should be enabled');
  if (!communityPlugins.includes('calendula-ultra-graph')) throw new Error('Calendula ultra graph plugin should be enabled');
  if (!fs.existsSync(guardManifestPath) || !fs.existsSync(guardMainPath)) throw new Error('Calendula graph guard plugin files are missing');
  if (!fs.existsSync(ultraManifestPath) || !fs.existsSync(ultraMainPath) || !fs.existsSync(ultraStylesPath)) throw new Error('Calendula ultra graph plugin files are missing');
  if (JSON.stringify(enabledPlugins) !== JSON.stringify(expectedPlugins)) {
    throw new Error(`Unexpected enabled plugins: ${enabledPlugins.join(', ')}`);
  }

  process.stdout.write(`calendula-20k-topology:ok ${JSON.stringify({ files: files.length, edgeCount, backboneCount, unresolved, zeroOut, zeroIn })}\n`);
})()
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'calendula-20k-topology-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'calendula-20k-topology:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'rejects dangerous profiles unless explicitly allowed' {
        $root = New-TempRoot
        try {
            $vault = Join-Path $root 'Vault'
            $obsidian = Join-Path $vault '.obsidian'
            $diaryDir = Join-Path $vault 'Calendula\2026\Июнь'
            $peopleDir = Join-Path $vault 'People'
            New-Item -ItemType Directory -Path $obsidian, $diaryDir, $peopleDir -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $repoRoot 'Calendula-20K\.obsidian\graph-profiles.json') -Destination (Join-Path $obsidian 'graph-profiles.json')
            Write-Utf8Text -Path (Join-Path $diaryDir '01-06-26.md') -Content '# Test diary'
            Write-Utf8Text -Path (Join-Path $peopleDir 'Person-0001.md') -Content '# Person'
            Write-Utf8Text -Path (Join-Path $obsidian 'core-plugins.json') -Content @'
{
  "file-explorer": true,
  "switcher": true,
  "graph": true,
  "command-palette": true,
  "editor-status": true,
  "backlink": true
}
'@
            Write-Utf8Text -Path (Join-Path $obsidian 'workspace.json') -Content @'
{
  "main": {},
  "left": {},
  "right": {},
  "left-ribbon": {},
  "active": "",
  "lastOpenFiles": []
}
'@

            $output = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'Scripts/Obsidian/Set-Calendula20KGraphProfile.ps1') -Profile full-danger -VaultPath $vault 2>&1
            $LASTEXITCODE | Should Not Be 0
            ($output -join [Environment]::NewLine) | Should Match 'requires -AllowDanger'

            $output = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'Scripts/Obsidian/Set-Calendula20KGraphProfile.ps1') -Profile fast-backbone -VaultPath $vault 2>&1
            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'Applied Calendula-20K graph profile'
            $communityPlugins = Get-Content -LiteralPath (Join-Path $obsidian 'community-plugins.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            ($communityPlugins -contains 'calendula-graph-guard') | Should Be $true
            ($communityPlugins -contains 'calendula-ultra-graph') | Should Be $true
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'repairs graph and workspace drift through the guard quarantine mode' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $tempRootJson = $root | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const fs = require('fs');
  const path = require('path');
  const Module = require('module');
  const repoRoot = __REPO_ROOT__;
  const tempRoot = __TEMP_ROOT__;
  const vaultRoot = path.join(tempRoot, 'Vault');
  const obsidianRoot = path.join(vaultRoot, '.obsidian');
  fs.mkdirSync(obsidianRoot, { recursive: true });
  fs.copyFileSync(path.join(repoRoot, 'Calendula-20K/.obsidian/graph-profiles.json'), path.join(obsidianRoot, 'graph-profiles.json'));
  fs.writeFileSync(path.join(obsidianRoot, 'graph.json'), JSON.stringify({
    search: '',
    hideUnresolved: false,
    showOrphans: true,
    repelStrength: 20,
    linkDistance: 250,
    nodeSizeMultiplier: 2
  }, null, 2));

  let graphDetached = 0;
  let heavyDetached = 0;
  const graphLeaves = [
    { detach: async () => { graphDetached += 1; } },
    { detach: async () => { graphDetached += 1; } },
    { detach: async () => { graphDetached += 1; } },
  ];
  const heavyLeaf = {
    view: { getViewType() { return 'backlink'; } },
    detach: async () => { heavyDetached += 1; },
  };

  class Plugin {
    constructor() {
      this.app = {
        vault: {
          adapter: {
            async read(filePath) {
              return fs.readFileSync(path.join(vaultRoot, filePath), 'utf8');
            },
            async write(filePath, value) {
              const full = path.join(vaultRoot, filePath);
              fs.mkdirSync(path.dirname(full), { recursive: true });
              fs.writeFileSync(full, value, 'utf8');
            },
          },
        },
        workspace: {
          getLeavesOfType(type) {
            return type === 'graph' ? graphLeaves : [];
          },
          iterateAllLeaves(callback) {
            callback(heavyLeaf);
          },
          getLeaf() {
            return {
              setViewState: async () => {},
            };
          },
          revealLeaf() {},
          onLayoutReady() {},
        },
      };
    }
    addCommand() {}
    registerInterval() {}
  }
  class Notice {
    constructor(message) {
      this.message = message;
    }
  }

  const originalLoad = Module._load;
  Module._load = function patchedLoad(request, parent, isMain) {
    if (request === 'obsidian') {
      return { Plugin, Notice };
    }
    return originalLoad.call(this, request, parent, isMain);
  };

  try {
    const Guard = require(path.join(repoRoot, 'Calendula-20K/.obsidian/plugins/calendula-graph-guard/main.js'));
    const guard = new Guard();
    const result = await guard.guardFastProfile('test-drift');
    const repairedGraph = JSON.parse(fs.readFileSync(path.join(obsidianRoot, 'graph.json'), 'utf8'));
    const guardData = JSON.parse(fs.readFileSync(path.join(obsidianRoot, 'calendula-graph-guard-data.json'), 'utf8'));

    if (!result.repaired) throw new Error('Expected guard to repair drift');
    if (repairedGraph.search !== 'tag:#graph/backbone') throw new Error(`Graph search was not repaired: ${repairedGraph.search}`);
    if (repairedGraph.repelStrength > 1.5 || repairedGraph.linkDistance > 30) throw new Error('Graph physics were not repaired');
    if (graphDetached !== 2) throw new Error(`Expected 2 extra graph leaves detached, got ${graphDetached}`);
    if (heavyDetached !== 1) throw new Error(`Expected 1 heavy leaf detached, got ${heavyDetached}`);
    if (!guardData.incidents?.some((entry) => entry.type === 'quarantine-repair')) throw new Error('Missing quarantine incident');
    process.stdout.write('guard-quarantine:ok\n');
  } finally {
    Module._load = originalLoad;
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson).Replace('__TEMP_ROOT__', $tempRootJson)
            $scriptPath = Join-Path $root 'guard-quarantine-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'guard-quarantine:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'loads the ultra graph plugin with budgeted canvas rendering and cleanup' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
  const Module = require('module');
  const repoRoot = __REPO_ROOT__;
  let registeredType = null;
  let viewFactory = null;
  const commands = [];
  const frameQueue = [];
  const resizeHandlers = new Set();
  let openedState = null;
  let revealed = false;
  let detachedType = null;
  let frameId = 0;
  let now = 0;
  let rectCalls = 0;
  let fillCalls = 0;
  let removedCanvasListeners = 0;

  global.performance = {
    now() {
      now += 0.5;
      return now;
    },
  };

  const gradient = { addColorStop() {} };
  const ctx = {
    setTransform() {},
    clearRect() {},
    createLinearGradient() { return gradient; },
    fillRect() {},
    beginPath() {},
    rect() { rectCalls += 1; },
    fill() { fillCalls += 1; },
  };

  function makeEl(tag = 'div') {
    return {
      tagName: tag,
      children: [],
      style: {},
      textContent: '',
      empty() {
        this.children = [];
        this.textContent = '';
      },
      addClass() {},
      createDiv(options = {}) {
        const child = makeEl('div');
        if (options.text) child.textContent = options.text;
        this.children.push(child);
        return child;
      },
      createEl(tagName, options = {}) {
        const child = tagName === 'canvas' ? makeCanvas() : makeEl(tagName);
        if (options.text) child.textContent = options.text;
        this.children.push(child);
        return child;
      },
      setText(text) {
        this.textContent = text;
      },
      appendChild(child) {
        this.children.push(child);
        return child;
      },
      getBoundingClientRect() {
        return { width: 1280, height: 720 };
      },
      addEventListener() {},
      removeEventListener() {},
    };
  }

  function makeCanvas() {
    const canvas = makeEl('canvas');
    canvas.getContext = (kind) => (kind === '2d' ? ctx : null);
    canvas.addEventListener = () => {};
    canvas.removeEventListener = () => {
      removedCanvasListeners += 1;
    };
    canvas.setPointerCapture = () => {};
    return canvas;
  }

  global.window = {
    devicePixelRatio: 1,
    requestAnimationFrame(callback) {
      frameId += 1;
      frameQueue.push(callback);
      return frameId;
    },
    cancelAnimationFrame() {},
    addEventListener(type, handler) {
      if (type === 'resize') resizeHandlers.add(handler);
    },
    removeEventListener(type, handler) {
      if (type === 'resize') resizeHandlers.delete(handler);
    },
    setTimeout,
    clearTimeout,
  };
  global.requestAnimationFrame = global.window.requestAnimationFrame;
  global.cancelAnimationFrame = global.window.cancelAnimationFrame;
  global.document = {
    createElement(tag) { return makeEl(tag); },
    body: makeEl('body'),
  };

  class ItemView {
    constructor(leaf) {
      this.leaf = leaf;
      this.containerEl = makeEl('div');
    }
  }

  class Plugin {
    constructor() {
      this.app = {
        workspace: {
          getLeaf() {
            return {
              setViewState: async (state) => {
                openedState = state;
              },
            };
          },
          revealLeaf() {
            revealed = true;
          },
          detachLeavesOfType(type) {
            detachedType = type;
          },
        },
      };
    }
    registerView(type, factory) {
      registeredType = type;
      viewFactory = factory;
    }
    addCommand(command) {
      commands.push(command);
    }
  }

  const originalLoad = Module._load;
  Module._load = function patchedLoad(request, parent, isMain) {
    if (request === 'obsidian') {
      return { ItemView, Plugin };
    }
    return originalLoad.call(this, request, parent, isMain);
  };

  try {
    const UltraGraphPlugin = require(path.join(repoRoot, 'Calendula-20K/.obsidian/plugins/calendula-ultra-graph/main.js'));
    const plugin = new UltraGraphPlugin();
    await plugin.onload();

    if (registeredType !== 'calendula-ultra-graph') throw new Error(`Unexpected view type: ${registeredType}`);
    const command = commands.find((item) => item.id === 'open-calendula-ultra-graph');
    if (!command) throw new Error('Missing open ultra graph command');
    await command.callback();
    if (!openedState || openedState.type !== 'calendula-ultra-graph' || !revealed) throw new Error('Ultra graph command did not open the view');

    const view = viewFactory({});
    await view.onOpen();
    if (!(view.nodes instanceof Float32Array) || view.nodes.length !== 40000) throw new Error('Expected 20K synthetic node coordinates');
    if (resizeHandlers.size !== 1) throw new Error(`Expected one resize handler, got ${resizeHandlers.size}`);

    const firstFrame = frameQueue.shift();
    if (typeof firstFrame !== 'function') throw new Error('No animation frame was scheduled');
    firstFrame();

    if (view.cursor <= 0 || view.cursor >= 20000) throw new Error(`Expected chunked progressive draw cursor, got ${view.cursor}`);
    if (rectCalls <= 0 || fillCalls <= 0) throw new Error('Expected batched canvas draw calls');
    if (!/synthetic 20[\s,.]?000 nodes/.test(view.statusEl.textContent)) {
      throw new Error(`Unexpected status text: ${view.statusEl.textContent}`);
    }
    const steadyHealth = view.getHealthSnapshot();
    if (!Object.isFrozen(steadyHealth)) throw new Error('Health snapshot should be frozen');
    if (steadyHealth.mode !== 'steady' || steadyHealth.renderStride !== 1) {
      throw new Error(`Expected steady health mode, got ${JSON.stringify(steadyHealth)}`);
    }

    view.fps = 20;
    view.lastInteractionAt = -10000;
    view.updateFrameBudget(performance.now());
    const emergencyHealth = view.getHealthSnapshot();
    if (emergencyHealth.mode !== 'emergency' || emergencyHealth.renderStride < 4) {
      throw new Error(`Expected emergency degradation, got ${JSON.stringify(emergencyHealth)}`);
    }

    await view.onClose();
    if (resizeHandlers.size !== 0) throw new Error('Resize handler was not removed on close');
    if (removedCanvasListeners < 5) throw new Error(`Expected canvas listeners cleanup, got ${removedCanvasListeners}`);

    await plugin.onunload();
    if (detachedType !== 'calendula-ultra-graph') throw new Error('Plugin unload did not detach ultra graph leaves');

    process.stdout.write('ultra-graph:ok\n');
  } finally {
    Module._load = originalLoad;
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'ultra-graph-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'ultra-graph:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Calendula graph store' {
    It 'builds an atomic graph store with forward and reverse CSR recovery' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $tempRootJson = $root | ConvertTo-Json -Compress
            $scriptContent = @'
(() => {
  const fs = require('fs');
  const path = require('path');
  const repoRoot = __REPO_ROOT__;
  const tempRoot = __TEMP_ROOT__;
  const vaultRoot = path.join(repoRoot, 'Calendula-20K');
  const outRoot = path.join(tempRoot, 'graph-store');
  const store = require(path.join(repoRoot, 'Scripts/Obsidian/build-calendula-graph-store.js'));

  const graph = store.buildGraph(vaultRoot);
  const first = store.writeStore(vaultRoot, outRoot, graph);
  const second = store.writeStore(vaultRoot, outRoot, graph);
  const currentDir = path.join(outRoot, 'graph.current');
  const previousDir = path.join(outRoot, 'graph.previous');
  const rootManifest = JSON.parse(fs.readFileSync(path.join(outRoot, 'graph.manifest.json'), 'utf8'));

  function size(fileName) {
    return fs.statSync(path.join(currentDir, fileName)).size;
  }

  if (!first.validation.ok || !second.validation.ok) throw new Error('Manifest validation failed');
  if (!fs.existsSync(currentDir)) throw new Error('Missing graph.current');
  if (!fs.existsSync(previousDir)) throw new Error('Missing graph.previous after second write');
  if (fs.existsSync(path.join(outRoot, 'graph.lock'))) throw new Error('graph.lock should be removed after build');
  if (rootManifest.schemaVersion !== 6) throw new Error(`Expected schema v6, got ${rootManifest.schemaVersion}`);
  if (rootManifest.stats.nodes < 30000) throw new Error(`Expected high-load node count, got ${rootManifest.stats.nodes}`);
  if (rootManifest.stats.unresolved !== 0) throw new Error(`Expected no unresolved links, got ${rootManifest.stats.unresolved}`);
  if (size(rootManifest.files.outOffsets) !== (rootManifest.stats.nodes + 1) * 4) throw new Error('Forward CSR offsets size mismatch');
  if (size(rootManifest.files.inOffsets) !== (rootManifest.stats.nodes + 1) * 4) throw new Error('Reverse CSR offsets size mismatch');
  if (size(rootManifest.files.outTargets) !== rootManifest.stats.edges * 4) throw new Error('Forward CSR target size mismatch');
  if (size(rootManifest.files.inSources) !== rootManifest.stats.edges * 4) throw new Error('Reverse CSR source size mismatch');

  fs.writeFileSync(path.join(currentDir, rootManifest.files.edgesSource), 'corrupt-current');
  const loaded = store.loadGraphStore(outRoot);
  if (!loaded.ok || !loaded.recoveredFromPrevious || loaded.activeDir !== 'graph.previous') {
    throw new Error(`Expected recovery from previous store, got ${JSON.stringify(loaded)}`);
  }

  process.stdout.write(`graph-store:ok ${JSON.stringify({ nodes: rootManifest.stats.nodes, edges: rootManifest.stats.edges, recovered: loaded.recoveredFromPrevious })}\n`);
})()
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson).Replace('__TEMP_ROOT__', $tempRootJson)
            $scriptPath = Join-Path $root 'graph-store-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'graph-store:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Calendula RenderPlan' {
    It 'builds budgeted immutable render plans from the graph store' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $tempRootJson = $root | ConvertTo-Json -Compress
            $scriptContent = @'
(() => {
  const path = require('path');
  const repoRoot = __REPO_ROOT__;
  const tempRoot = __TEMP_ROOT__;
  const vaultRoot = path.join(repoRoot, 'Calendula-20K');
  const outRoot = path.join(tempRoot, 'graph-store');
  const store = require(path.join(repoRoot, 'Scripts/Obsidian/build-calendula-graph-store.js'));
  const renderPlan = require(path.join(repoRoot, 'Scripts/Obsidian/graph-render-plan.js'));

  const graph = store.buildGraph(vaultRoot);
  store.writeStore(vaultRoot, outRoot, graph);

  const profile = {
    name: 'ultra-indexed-test',
    maxVisibleNodes: 1200,
    maxVisibleEdges: 1800,
    labelPolicy: 'selected-only',
    edgePolicy: 'aggregated',
    lodPolicy: 'aggressive',
  };

  const normal = renderPlan.buildRenderPlan({
    storeRoot: outRoot,
    profile,
    camera: { x: 0, y: 0, width: 100000, height: 100000, zoom: 1 },
    frameId: 7,
  });

  if (!Object.isFrozen(normal) || !Object.isFrozen(normal.budgets) || !Object.isFrozen(normal.skipped)) {
    throw new Error('RenderPlan should be frozen');
  }
  if (!(normal.nodes instanceof Uint32Array) || !(normal.edges instanceof Uint32Array)) {
    throw new Error('RenderPlan should use typed arrays');
  }
  if (normal.nodes.length > normal.budgets.nodeBudget) throw new Error('Node budget exceeded');
  if (normal.edges.length > normal.budgets.edgeBudget) throw new Error('Edge budget exceeded');
  if (normal.edges.length >= normal.stats.edges) throw new Error('RenderPlan should not draw every edge by default');
  if (normal.labels.length !== 0) throw new Error('Labels should be skipped before LOD 4');

  const memory = renderPlan.buildRenderPlan({
    storeRoot: outRoot,
    profile,
    camera: { x: 0, y: 0, width: 100000, height: 100000, zoom: 0.1 },
    memoryPressure: true,
    frameId: 8,
  });

  if (memory.mode !== 'memory-pressure') throw new Error(`Expected memory-pressure mode, got ${memory.mode}`);
  if (memory.edges.length !== 0 || memory.labels.length !== 0) throw new Error('Memory-pressure mode should disable edges and labels');
  if (memory.nodes.length > 500) throw new Error('Memory-pressure mode should cap visible nodes');

  const degraded = renderPlan.buildRenderPlan({
    storeRoot: outRoot,
    profile,
    camera: { x: 0, y: 0, width: 100000, height: 100000, zoom: 1 },
    frameHistory: { p95FrameMs: 30 },
    frameId: 9,
  });
  if (degraded.mode !== 'degraded') throw new Error(`Expected degraded mode, got ${degraded.mode}`);
  if (degraded.budgets.edgeBudget >= normal.budgets.edgeBudget) throw new Error('Degraded mode should reduce edge budget');

  process.stdout.write(`render-plan:ok ${JSON.stringify({ nodes: normal.nodes.length, edges: normal.edges.length, memoryMode: memory.mode, degradedEdges: degraded.budgets.edgeBudget })}\n`);
})()
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson).Replace('__TEMP_ROOT__', $tempRootJson)
            $scriptPath = Join-Path $root 'render-plan-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'render-plan:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Calendula GraphScheduler' {
    It 'turns backpressure signals into reduced render budgets' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $tempRootJson = $root | ConvertTo-Json -Compress
            $scriptContent = @'
(() => {
  const path = require('path');
  const repoRoot = __REPO_ROOT__;
  const tempRoot = __TEMP_ROOT__;
  const vaultRoot = path.join(repoRoot, 'Calendula-20K');
  const outRoot = path.join(tempRoot, 'graph-store');
  const store = require(path.join(repoRoot, 'Scripts/Obsidian/build-calendula-graph-store.js'));
  const { GraphScheduler } = require(path.join(repoRoot, 'Scripts/Obsidian/graph-scheduler.js'));

  const graph = store.buildGraph(vaultRoot);
  store.writeStore(vaultRoot, outRoot, graph);

  const scheduler = new GraphScheduler();
  const profile = {
    name: 'scheduler-test',
    maxVisibleNodes: 3000,
    maxVisibleEdges: 5000,
    labelPolicy: 'selected-only',
    lodPolicy: 'aggressive',
  };
  const camera = { x: 0, y: 0, width: 100000, height: 100000, zoom: 1 };

  const normal = scheduler.scheduleFrame({ storeRoot: outRoot, profile, camera });
  if (normal.signals.frameOverBudget) throw new Error('Normal frame should not be over budget');
  if (normal.plan.edges.length > normal.plan.budgets.edgeBudget) throw new Error('Normal plan exceeded edge budget');

  for (let i = 0; i < 20; i += 1) scheduler.recordFrame(35);
  const degraded = scheduler.scheduleFrame({ storeRoot: outRoot, profile, camera });
  if (!degraded.signals.frameOverBudget) throw new Error('Expected frameOverBudget signal');
  if (!degraded.actions.includes('increase-lod')) throw new Error('Expected increase-lod action');
  if (degraded.plan.mode !== 'degraded' && degraded.plan.mode !== 'emergency') throw new Error(`Expected degraded/emergency plan, got ${degraded.plan.mode}`);
  if (degraded.adaptiveProfile.maxVisibleEdges >= profile.maxVisibleEdges) throw new Error('Expected reduced edge budget');

  const burst = scheduler.scheduleFrame({
    storeRoot: outRoot,
    profile,
    camera,
    input: { inputBurst: true, rendererQueueLength: 5, profileSwitch: true },
  });
  if (!burst.signals.inputBurst || !burst.signals.rendererQueueTooLong) throw new Error('Expected inputBurst and rendererQueueTooLong');
  if (!burst.actions.includes('drop-stale-frames')) throw new Error('Expected stale frame drop action');
  if (burst.adaptiveProfile.labelPolicy !== 'none') throw new Error('Input burst should disable labels');

  const memory = scheduler.scheduleFrame({
    storeRoot: outRoot,
    profile,
    camera,
    input: { memoryPressure: true },
  });
  if (memory.plan.mode !== 'memory-pressure') throw new Error(`Expected memory-pressure plan, got ${memory.plan.mode}`);
  if (memory.plan.edges.length !== 0 || memory.plan.labels.length !== 0) throw new Error('Memory-pressure plan should not draw edges or labels');

  if (!Object.isFrozen(memory) || !Object.isFrozen(memory.signals) || !Object.isFrozen(memory.actions)) {
    throw new Error('Scheduler result should be frozen');
  }

  process.stdout.write(`scheduler:ok ${JSON.stringify({ normalEdges: normal.plan.edges.length, degradedMode: degraded.plan.mode, memoryMode: memory.plan.mode })}\n`);
})()
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson).Replace('__TEMP_ROOT__', $tempRootJson)
            $scriptPath = Join-Path $root 'scheduler-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'scheduler:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Calendula graph benchmark tooling' {
    It 'produces a validated graph performance report on a temp vault' {
        $root = New-TempRoot
        try {
            $vault = Join-Path $root 'Vault'
            $storeRoot = Join-Path $root 'graph-store'
            New-Item -ItemType Directory -Path $vault -Force | Out-Null
            Write-Utf8Text -Path (Join-Path $vault 'A.md') -Content "# A`n[[B]]`n"
            Write-Utf8Text -Path (Join-Path $vault 'B.md') -Content "# B`n[[C]]`n"
            Write-Utf8Text -Path (Join-Path $vault 'C.md') -Content "# C`n[[A]]`n"

            $report = & (Join-Path $repoRoot 'Scripts\Obsidian\Measure-CalendulaGraphPerformance.ps1') -VaultPath $vault -StoreRoot $storeRoot -MinimumNodes 3 -NodeBudget 2 -EdgeBudget 2 -PassThru

            $report.ok | Should Be $true
            [int]$report.stats.nodes | Should Be 3
            [int]$report.stats.unresolved | Should Be 0
            ([int]$report.renderPlan.nodes -le 2) | Should Be $true
            ([int]$report.renderPlan.edges -le 2) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $storeRoot 'graph.manifest.json')) | Should Be $true

            { & (Join-Path $repoRoot 'Scripts\Obsidian\Measure-CalendulaGraphPerformance.ps1') -VaultPath $vault -StoreRoot (Join-Path $root 'too-small-store') -MinimumNodes 4 } | Should Throw
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'LiveGraph' {
    It 'loads the live-graph bundle and sources without crashing' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
  const root = __REPO_ROOT__;
  const targets = [
    { label: 'bundle', file: path.join(root, 'Calendula/.obsidian/plugins/live-graph/core.js') },
    { label: 'source-v1', file: path.join(root, 'Scripts/ObsidianPlugins/live-graph/live-graph-core.js') },
    { label: 'source-v2', file: path.join(root, 'Scripts/ObsidianPlugins/live-graph/live-graph-core-v2.js') }
  ];

  function makeEl() {
    return {
      empty() {},
      addClass() {},
      createDiv() { return makeEl(); },
      createEl() { return makeEl(); },
      setText() {},
      appendChild() {},
      style: {},
      classList: { add() {} },
      setAttribute() {},
      addEventListener() {},
    };
  }

  global.document = {
    createElementNS(_ns, tag) { return makeEl(tag); },
    createElement(tag) { return makeEl(tag); },
    getElementById() { return null; },
    body: makeEl(),
    head: makeEl(),
  };
  global.window = {
    requestAnimationFrame() { return 1; },
    cancelAnimationFrame() {},
    devicePixelRatio: 1,
  };

  function makeMockObsidian() {
    class ItemView {
      constructor() {
        this.containerEl = makeEl();
      }
    }

    class Plugin {
      constructor() {
      this.app = {
        workspace: {
          onLayoutReady(cb) { cb(); },
          getLeavesOfType() { return []; },
          getLeaf() { return { setViewState: async () => {}, detach: async () => {} }; },
          revealLeaf() {},
        },
        vault: {
          getMarkdownFiles() { return []; },
          getAbstractFileByPath() { return null; },
          on() { return { off() {} }; },
        },
          metadataCache: { resolvedLinks: {}, on() { return { off() {} }; } },
        };
      }

      async loadData() { return { autoOpen: false }; }
      async saveData() {}
      registerView() {}
      addCommand() {}
      addRibbonIcon() { return makeEl(); }
      addSettingTab() {}
      registerEvent() {}
    }

    class PluginSettingTab {
      constructor() {
        this.containerEl = makeEl();
      }
    }

    class Setting {
      setName() { return this; }
      setDesc() { return this; }
      addToggle(cb) {
        cb({ setValue() { return { onChange() {} }; } });
        return this;
      }
      addDropdown(cb) {
        cb({
          addOption() { return this; },
          setValue() { return this; },
          onChange() { return this; },
        });
        return this;
      }
      addSlider(cb) {
        cb({
          setLimits() { return this; },
          setValue() { return this; },
          setDynamicTooltip() { return this; },
          onChange() { return this; },
        });
        return this;
      }
    }

    class Notice {
      constructor(message) {
        this.message = message;
      }
    }

    function setIcon() {}

    return { ItemView, Notice, Plugin, PluginSettingTab, Setting, setIcon };
  }

  for (const target of targets) {
    const create = require(target.file);
    const originalError = console.error;
    console.error = () => {};
    try {
      const MissingPlugin = create({});
      await new MissingPlugin().onload();

      const PluginClass = create(makeMockObsidian());
      const instance = new PluginClass();
      await instance.onload();
      await instance.onunload();

      process.stdout.write(target.label + ':ok\n');
    } finally {
      console.error = originalError;
    }
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'live-graph-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'bundle:ok'
            ($output -join [Environment]::NewLine) | Should Match 'source-v1:ok'
            ($output -join [Environment]::NewLine) | Should Match 'source-v2:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'caches vault enumeration across repeated renders in the live-graph bundle' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
  const root = __REPO_ROOT__;
  const create = require(path.join(root, 'Calendula/.obsidian/plugins/live-graph/core.js'));
  const fileCount = 10000;
  let markdownCalls = 0;
  let resolvedAccesses = 0;

  function makeEl(tag = 'div') {
    return {
      tagName: tag,
      children: [],
      empty() { this.children = []; this.textContent = ''; },
      addClass() {},
      removeClass() {},
      createDiv() { return makeEl('div'); },
      createEl(_tag, _opts = {}) { return makeEl(_tag); },
      setText(text) { this.textContent = text; },
      appendChild(child) { this.children.push(child); return child; },
      querySelector(selector) {
        return this.children.find((child) => child.tagName === selector) || makeEl(selector);
      },
      style: {},
      classList: { add() {} },
      setAttribute() {},
      addEventListener() {},
      getContext(kind) {
        if (tag !== 'canvas' || kind !== '2d') {
          return null;
        }
        if (!this._ctx) {
          const gradient = { addColorStop() {} };
          this._ctx = {
            setTransform() {},
            clearRect() {},
            save() {},
            restore() {},
            beginPath() {},
            moveTo() {},
            lineTo() {},
            quadraticCurveTo() {},
            closePath() {},
            fill() {},
            stroke() {},
            arc() {},
            setLineDash() {},
            measureText(text) { return { width: text.length * 6 }; },
            fillText() {},
            createLinearGradient() { return gradient; },
            imageSmoothingEnabled: true,
            lineCap: 'round',
            lineWidth: 1,
            strokeStyle: '',
            fillStyle: '',
            textBaseline: 'middle',
          };
        }
        return this._ctx;
      },
      getBoundingClientRect() { return { width: 1280, height: 820 }; },
      innerHTML: '',
      textContent: '',
    };
  }

  function drainQueue() {
    let guard = 0;
    while (rafQueue.length) {
      const tick = rafQueue.shift();
      if (typeof tick === 'function') {
        tick(2000 + (guard * 16));
      }
      guard += 1;
      if (guard > 100) {
        throw new Error('RAF queue did not drain');
      }
    }
  }

  global.document = {
    createElementNS(_ns, tag) { return makeEl(tag); },
    createElement(tag) { return makeEl(tag); },
    body: makeEl('body'),
  };
  global.getComputedStyle = () => ({
    getPropertyValue() { return '#d8dde8'; },
  });
  let rafCalls = 0;
  const rafQueue = [];
  global.window = {
    requestAnimationFrame(cb) {
      rafCalls += 1;
      rafQueue.push(cb);
      return rafCalls;
    },
    cancelAnimationFrame() {},
    devicePixelRatio: 1,
  };

  class ItemView {
    constructor() {
      this.containerEl = makeEl('div');
    }
  }

  class Plugin {
    constructor() {
      const files = Array.from({ length: fileCount }, (_, index) => ({
        path: `Notes/note-${String(index + 1).padStart(5, '0')}.md`,
        basename: `note-${String(index + 1).padStart(5, '0')}`,
        name: `note-${String(index + 1).padStart(5, '0')}`,
      }));
      this.app = {
        workspace: {
          onLayoutReady(cb) { cb(); },
          getLeavesOfType() { return []; },
          getLeaf() { return { setViewState: async () => {}, detach: async () => {}, openFile: async () => {} }; },
          revealLeaf() {},
        },
        vault: {
          getMarkdownFiles() {
            markdownCalls += 1;
            return files;
          },
          getAbstractFileByPath() { return null; },
          on() { return { off() {} }; },
        },
      };
      const metadataCache = {
        on() { return { off() {} }; },
      };
      Object.defineProperty(metadataCache, 'resolvedLinks', {
        get() {
          resolvedAccesses += 1;
          return {
            'Notes/note-00001.md': { 'Notes/note-00002.md': 1 },
            'Notes/note-00002.md': { 'Notes/note-00001.md': 1 },
          };
        },
      });
      this.app.metadataCache = metadataCache;
    }

    async loadData() { return { autoOpen: false }; }
    async saveData() {}
    registerView(_type, factory) { this._factory = factory; }
    addCommand() {}
    addRibbonIcon() { return makeEl('button'); }
    addSettingTab() {}
    registerEvent() {}
  }

  class PluginSettingTab {
    constructor() {
      this.containerEl = makeEl('div');
    }
  }

  class Setting {
    setName() { return this; }
    setDesc() { return this; }
    addToggle(cb) {
      cb({ setValue() { return { onChange() {} }; } });
      return this;
    }
    addDropdown(cb) {
      cb({
        addOption() { return this; },
        setValue() { return this; },
        onChange() { return this; },
      });
      return this;
    }
    addSlider(cb) {
      cb({
        setLimits() { return this; },
        setValue() { return this; },
        setDynamicTooltip() { return this; },
        onChange() { return this; },
      });
      return this;
    }
  }

  class Notice {
    constructor(message) {
      this.message = message;
    }
  }

  function setIcon() {}

  const plugin = new (create({ ItemView, Notice, Plugin, PluginSettingTab, Setting, setIcon }))();
  await plugin.onload();
  const view = plugin._factory({});
  view.startRenderLoop = () => {};
  await view.onOpen();
  drainQueue();
  view.renderGraph(false);
  drainQueue();
  view.renderGraph(false);
  drainQueue();

  process.stdout.write(`calls:${markdownCalls};resolved:${resolvedAccesses};raf:${rafCalls};mode:${view.currentProfile?.mode};frames:${view.lastPaintSummary?.frames};chunked:${view.lastPaintSummary?.chunked};skipped:${view.lastPaintSummary?.labelsSkipped}\n`);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'live-graph-cache-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'calls:1'
            ($output -join [Environment]::NewLine) | Should Match 'resolved:2'
            ($output -join [Environment]::NewLine) | Should Match 'mode:ultra'
            ($output -join [Environment]::NewLine) | Should Match 'chunked:true'
            ($output -join [Environment]::NewLine) | Should Match 'frames:[2-9][0-9]*'
            ($output -join [Environment]::NewLine) | Should Match 'skipped:[1-9][0-9]*'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'drives the render loop with requestAnimationFrame' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
  const root = __REPO_ROOT__;
  const create = require(path.join(root, 'Calendula/.obsidian/plugins/live-graph/core.js'));
  let markdownCalls = 0;
  let rafCalls = 0;
  const rafQueue = [];

  function makeEl(tag = 'div') {
    return {
      tagName: tag,
      children: [],
      empty() { this.children = []; this.textContent = ''; },
      addClass() {},
      removeClass() {},
      createDiv() { return makeEl('div'); },
      createEl(_tag, _opts = {}) { return makeEl(_tag); },
      setText(text) { this.textContent = text; },
      appendChild(child) { this.children.push(child); return child; },
      querySelector(selector) {
        return this.children.find((child) => child.tagName === selector) || makeEl(selector);
      },
      style: {},
      classList: { add() {} },
      setAttribute() {},
      addEventListener() {},
      getContext(kind) {
        if (tag !== 'canvas' || kind !== '2d') return null;
        if (!this._ctx) {
          const gradient = { addColorStop() {} };
          this._ctx = {
            setTransform() {},
            clearRect() {},
            save() {},
            restore() {},
            beginPath() {},
            moveTo() {},
            lineTo() {},
            quadraticCurveTo() {},
            closePath() {},
            fill() {},
            stroke() {},
            arc() {},
            setLineDash() {},
            measureText(text) { return { width: text.length * 6 }; },
            fillText() {},
            createLinearGradient() { return gradient; },
            imageSmoothingEnabled: true,
          };
        }
        return this._ctx;
      },
      getBoundingClientRect() { return { width: 1280, height: 820 }; },
      innerHTML: '',
      textContent: '',
    };
  }

  global.document = {
    createElementNS(_ns, tag) { return makeEl(tag); },
    createElement(tag) { return makeEl(tag); },
    body: makeEl('body'),
  };
  global.getComputedStyle = () => ({
    getPropertyValue() { return '#d8dde8'; },
  });
  global.window = {
    requestAnimationFrame(cb) {
      rafCalls += 1;
      rafQueue.push(cb);
      return rafCalls;
    },
    cancelAnimationFrame() {},
    devicePixelRatio: 1,
  };

  class ItemView {
    constructor() {
      this.containerEl = makeEl('div');
    }
  }

  class Plugin {
    constructor() {
      const files = Array.from({ length: 1000 }, (_, index) => ({
        path: `Notes/note-${String(index + 1).padStart(5, '0')}.md`,
        basename: `note-${String(index + 1).padStart(5, '0')}`,
        name: `note-${String(index + 1).padStart(5, '0')}`,
      }));
      this.app = {
        workspace: {
          onLayoutReady(cb) { cb(); },
          getLeavesOfType() { return []; },
          getLeaf() { return { setViewState: async () => {}, detach: async () => {}, openFile: async () => {} }; },
          revealLeaf() {},
        },
        vault: {
          getMarkdownFiles() {
            markdownCalls += 1;
            return files;
          },
          getAbstractFileByPath() { return null; },
          on() { return { off() {} }; },
        },
        metadataCache: {
          resolvedLinks: {
            'Notes/note-00001.md': { 'Notes/note-00002.md': 1 },
            'Notes/note-00002.md': { 'Notes/note-00001.md': 1 },
          },
          on() { return { off() {} }; },
        },
      };
    }

    async loadData() { return { autoOpen: false }; }
    async saveData() {}
    registerView(_type, factory) { this._factory = factory; }
    addCommand() {}
    addRibbonIcon() { return makeEl('button'); }
    addSettingTab() {}
    registerEvent() {}
  }

  class PluginSettingTab {
    constructor() {
      this.containerEl = makeEl('div');
    }
  }

  class Setting {
    setName() { return this; }
    setDesc() { return this; }
    addToggle(cb) {
      cb({ setValue() { return { onChange() {} }; } });
      return this;
    }
    addDropdown(cb) {
      cb({
        addOption() { return this; },
        setValue() { return this; },
        onChange() { return this; },
      });
      return this;
    }
    addSlider(cb) {
      cb({
        setLimits() { return this; },
        setValue() { return this; },
        setDynamicTooltip() { return this; },
        onChange() { return this; },
      });
      return this;
    }
  }

  class Notice {
    constructor(message) {
      this.message = message;
    }
  }

  function setIcon() {}

  const plugin = new (create({ ItemView, Notice, Plugin, PluginSettingTab, Setting, setIcon }))();
  await plugin.onload();
  const view = plugin._factory({});
  let renders = 0;
  const originalRender = view.renderGraph.bind(view);
  view.renderGraph = (...args) => {
    renders += 1;
    return originalRender(...args);
  };
  await view.onOpen();
  const firstTick = rafQueue.shift();
  if (typeof firstTick !== 'function') {
    throw new Error('No animation frame was scheduled');
  }
  firstTick(2000);

  process.stdout.write(`renders:${renders};raf:${rafCalls};calls:${markdownCalls}\n`);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'live-graph-raf-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'renders:2'
            ($output -join [Environment]::NewLine) | Should Match 'raf:2'
            ($output -join [Environment]::NewLine) | Should Match 'calls:1'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'opens the native graph for 20K vaults' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
  const root = __REPO_ROOT__;
  const create = require(path.join(root, 'Calendula/.obsidian/plugins/live-graph/core.js'));
  let openedState = null;

  function makeEl(tag = 'div') {
    return {
      tagName: tag,
      children: [],
      empty() { this.children = []; },
      addClass() {},
      removeClass() {},
      createDiv() { return makeEl('div'); },
      createEl(_tag) { return makeEl(_tag); },
      setText() {},
      appendChild(child) { this.children.push(child); return child; },
      style: {},
      classList: { add() {} },
      setAttribute() {},
      addEventListener() {},
      getBoundingClientRect() { return { width: 1200, height: 800 }; },
    };
  }

  global.document = {
    createElementNS(_ns, tag) { return makeEl(tag); },
    createElement(tag) { return makeEl(tag); },
    getElementById() { return null; },
    body: makeEl('body'),
    head: makeEl('head'),
  };
  global.window = {
    requestAnimationFrame() { return 1; },
    cancelAnimationFrame() {},
    devicePixelRatio: 1,
  };

  class ItemView {
    constructor() {
      this.containerEl = makeEl('div');
    }
  }

  class Plugin {
    constructor() {
      const files = Array.from({ length: 20000 }, (_, index) => ({
        path: `Notes/note-${index + 1}.md`,
        basename: `note-${index + 1}`,
        name: `note-${index + 1}`,
      }));
      this.app = {
        workspace: {
          onLayoutReady(cb) { cb(); },
          getLeavesOfType() { return []; },
          getLeaf() {
            return {
              setViewState: async (state) => {
                openedState = state;
              },
              detach: async () => {},
            };
          },
          revealLeaf() {},
        },
        vault: {
          getMarkdownFiles() { return files; },
          getAbstractFileByPath() { return null; },
          on() { return { off() {} }; },
        },
        metadataCache: { resolvedLinks: {}, on() { return { off() {} }; } },
      };
    }

    async loadData() { return { autoOpen: false }; }
    async saveData() {}
    registerView() {}
    addCommand() {}
    addRibbonIcon() { return makeEl('button'); }
    addSettingTab() {}
    registerEvent() {}
  }

  class PluginSettingTab {
    constructor() {
      this.containerEl = makeEl('div');
    }
  }

  class Setting {
    setName() { return this; }
    setDesc() { return this; }
    addToggle(cb) { cb({ setValue() { return { onChange() {} }; } }); return this; }
    addDropdown(cb) {
      cb({
        addOption() { return this; },
        setValue() { return this; },
        onChange() { return this; },
      });
      return this;
    }
    addSlider(cb) {
      cb({
        setLimits() { return this; },
        setValue() { return this; },
        setDynamicTooltip() { return this; },
        onChange() { return this; },
      });
      return this;
    }
  }

  class Notice {
    constructor(message) {
      this.message = message;
    }
  }

  function setIcon() {}

  const plugin = new (create({ ItemView, Notice, Plugin, PluginSettingTab, Setting, setIcon }))();
  await plugin.onload();
  await plugin.openLiveGraph();

  if (!openedState || openedState.type !== 'graph') {
    throw new Error(`Expected native graph, got ${JSON.stringify(openedState)}`);
  }

  process.stdout.write('native-graph:ok\n');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'live-graph-native-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'native-graph:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'persists live-graph recovery batches outside the main state file' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
  const fs = require('fs');
  const root = __REPO_ROOT__;
  const create = require(path.join(root, 'Scripts/ObsidianPlugins/live-graph/builtin-graph.js'));

  class ItemView {
    constructor() {
      this.containerEl = { createDiv() { return this; }, createEl() { return this; } };
    }
  }

  global.document = {
    getElementById() { return null; },
    createElement() {
      return {
        style: {},
        classList: { add() {} },
        setAttribute() {},
        appendChild() {},
        addEventListener() {},
        createDiv() { return this; },
        createEl() { return this; },
        setText() {},
      };
    },
    createElementNS() {
      return {
        setAttribute() {},
      };
    },
    body: { appendChild() {} },
    head: { appendChild() {} },
  };
  global.window = {
    setTimeout,
    clearTimeout,
    setInterval,
    clearInterval,
    requestAnimationFrame(cb) { return setTimeout(cb, 0); },
    cancelAnimationFrame(id) { clearTimeout(id); },
    devicePixelRatio: 1,
  };

  let savedState = null;
  const vaultRoot = path.join(root, 'vault');
  const recoveryDir = path.join(vaultRoot, '.obsidian', 'plugins', 'live-graph', 'live-graph-recovery');
  fs.mkdirSync(recoveryDir, { recursive: true });
  const fileStore = new Map();
  const original = 'Alpha beta '.repeat(2000);
  const detached = original + 'x';

  class Plugin {
    constructor() {
      this.app = {
        workspace: {
          onLayoutReady(cb) { cb(); },
          getLeavesOfType() { return []; },
          getRightLeaf() { return null; },
          revealLeaf() {},
        },
        vault: {
          adapter: { basePath: vaultRoot },
          read: async (file) => fileStore.get(file.path) || '',
          modify: async (file, content) => { fileStore.set(file.path, content); },
          getAbstractFileByPath: (filePath) => ({ path: filePath }),
        },
        metadataCache: { getFirstLinkpathDest: () => true },
      };
    }

    async loadData() { return { settings: { autoCycleLinks: false } }; }
    async saveData(data) { savedState = data; }
    registerView() {}
    addCommand() {}
    addRibbonIcon() { return null; }
    addSettingTab() {}
    registerEvent() {}
  }

  class PluginSettingTab { constructor() {} }
  class Setting {
    setName() { return this; }
    setDesc() { return this; }
    addToggle() { return this; }
    addDropdown() { return this; }
    addSlider() { return this; }
  }
  class Notice { constructor() {} }
  function setIcon() {}

  const plugin = new (create({ ItemView, Notice, Plugin, PluginSettingTab, Setting, setIcon }))();
  await plugin.onload();

  plugin.activeBatch = {
    cycleId: 'cycle-1',
    files: [
      { path: 'A.md', original, detached },
      { path: 'B.md', original: `${original}y`, detached: `${detached}z` },
    ],
  };
  plugin.safetyBuffer = [
    {
      id: 'entry-1',
      createdAt: '2026-06-10T00:00:00.000Z',
      status: 'detached',
      files: [
        { path: 'A.md', original, detached },
        { path: 'B.md', original: `${original}y`, detached: `${detached}z` },
      ],
    },
  ];

  await plugin.saveState();

  if (!savedState || !savedState.persistedDetached || !savedState.persistedDetached.length) {
    throw new Error('State was not saved');
  }

  const savedSize = Buffer.byteLength(JSON.stringify(savedState), 'utf8');
  if (savedSize > 2000) {
    throw new Error(`Expected compact state, got ${savedSize} bytes`);
  }

  const recoveryFile = path.join(recoveryDir, 'entry-1.json');
  if (!fs.existsSync(recoveryFile)) {
    throw new Error('Recovery cache file was not written');
  }

  const createReloaded = require(path.join(root, 'Scripts/ObsidianPlugins/live-graph/builtin-graph.js'));
  let reloadedData = savedState;
  class ReloadPlugin extends Plugin {
    async loadData() { return reloadedData; }
    async saveData(data) { reloadedData = data; }
  }

  const reloaded = new (createReloaded({ ItemView, Notice, Plugin: ReloadPlugin, PluginSettingTab, Setting, setIcon }))();
  await reloaded.onload();

  if (reloaded.activeBatch !== null) {
    throw new Error('Active batch should stay unloaded until recovery');
  }

  if (reloaded.safetyBuffer.length !== 1 || reloaded.safetyBuffer[0].fileRef !== 'live-graph-recovery/entry-1.json') {
    throw new Error('Safety buffer metadata was not restored');
  }

  fileStore.set('A.md', detached);
  fileStore.set('B.md', `${detached}z`);
  await reloaded.recoverFromBuffer(true);

  if (fileStore.get('A.md') !== original || fileStore.get('B.md') !== `${original}y`) {
    throw new Error('Recovery cache did not restore the original file contents');
  }

  process.stdout.write('recovery-cache:ok\\n');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'live-graph-recovery-cache-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'recovery-cache:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
