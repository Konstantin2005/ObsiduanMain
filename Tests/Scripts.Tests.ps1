$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'Scripts\Vault\VaultHelpers.ps1')

function New-TempRoot {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

Describe 'Scripts' {
    Describe 'VaultHelpers' {
        It 'maps month numbers to Russian names' {
            Get-MonthName -Month 6 | Should Be 'Июнь'
        }

        It 'returns null when a section heading is missing' {
            (Get-SectionRange -Lines @('alpha', 'beta') -Heading 'Сегодня') | Should Be $null
        }

        It 'detects trailing newline style' {
            Get-TrailingNewline "hello`r`n" | Should Be "`r`n"
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
            Write-Utf8Text -Path $conflict -Content 'conflict'

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
