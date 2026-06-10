$repoRoot = Split-Path -Parent $PSScriptRoot

function New-TempRoot {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

Describe 'Scripts' {
    It 'daily-push invokes git steps in order and writes a success log' {
        $root = New-TempRoot
        try {
            $repo = Join-Path $root 'repo'
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            $fakeGit = Join-Path $root 'fake-git.ps1'
            $gitCalls = Join-Path $root 'git-calls.txt'
            $logPath = Join-Path $repo 'Scripts\Logs\daily-push.log'

            Write-Utf8File $fakeGit @"
param([string[]]`$Args)
Add-Content -LiteralPath '$gitCalls' -Value (`$Args -join ' ')
exit 0
"@

            & (Join-Path $repoRoot 'Scripts\Git\daily-push.ps1') -RepoPath $repo -Branch 'develop' -GitPath $fakeGit -LogPath $logPath

            $calls = Get-Content -LiteralPath $gitCalls
            $calls.Count | Should Be 3
            $calls[0] | Should Match '^fetch '
            $calls[1] | Should Match '^pull '
            $calls[2] | Should Match '^push origin develop$'
            (Get-Content -LiteralPath $logPath -Raw) | Should Match 'Push completed successfully\.'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
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
            Write-Utf8File $file @"
## Запланировано

- [ ] Сделать тест @{2026-06-10}
- [ ] Остаться здесь @{2026-06-11}

## Сегодня

- [ ] Уже есть задача
"@

            & (Join-Path $repoRoot 'Scripts\Vault\Move-TodayTasks.ps1') -Date '2026-06-10' -KanbanDir $plan

            $content = Get-Content -LiteralPath $file -Raw
            $content | Should Match '## Сегодня[\s\S]*Сделать тест @\{2026-06-10\}'
            $content | Should Not Match '## Запланировано[\s\S]*Сделать тест @\{2026-06-10\}'
            $content | Should Match '## Запланировано[\s\S]*Остаться здесь @\{2026-06-11\}'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
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
            Write-Utf8File $june @"
## Запланировано

- [ ] Перенести в июль @{2026-07-01}

## Сегодня
"@
            Write-Utf8File $july @"
## Запланировано

## Сегодня
"@

            & (Join-Path $repoRoot 'Scripts\Vault\Sort-BoardTasks.ps1') -KanbanDir $plan

            (Get-Content -LiteralPath $june -Raw) | Should Not Match 'Перенести в июль'
            (Get-Content -LiteralPath $july -Raw) | Should Match 'Перенести в июль @\{2026-07-01\}'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
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

            Write-Utf8File $diaryFile @"
# Дневник

Сегодня видел [[John]] на улице #Обычный
"@
            Write-Utf8File $personFile @"
---
name: John
---
"@

            & (Join-Path $repoRoot 'Scripts\Vault\collect-mentions.ps1') -VaultPath $root -DiaryRoot $diaryRoot -SocialCapitalRoot $socialRoot

            $personContent = Get-Content -LiteralPath $personFile -Raw
            $personContent | Should Match '## Упоминания в дневниках'
            $personContent | Should Match '\*\*2026/Июнь/01-06-26\.md\*\*'
            $personContent | Should Not Match '#Обычный'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
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

            Write-Utf8File $mainNote 'main'
            Write-Utf8File $numberedNote 'numbered'
            Write-Utf8File $refs 'link: 1.1-6-26.md'

            & (Join-Path $repoRoot 'Scripts\Vault\Normalize-DayNoteNumbers.ps1') -VaultPath $root -DiaryRoot $diaryRoot

            Test-Path -LiteralPath (Join-Path $monthDir '02.1-6-26.md') | Should Be $true
            Test-Path -LiteralPath $numberedNote | Should Be $false
            (Get-Content -LiteralPath $refs -Raw) | Should Match 'link: 02\.1-6-26\.md'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
            }
        }
    }

    It 'generate_terms_v2 creates term files in a test vault' {
        $root = New-TempRoot
        try {
            & (Join-Path $repoRoot 'Scripts\Vault\generate_terms_v2.ps1') -VaultPath $root -MaxWords 3

            $files = Get-ChildItem -LiteralPath $root -File -Filter '*.md'
            $files.Count | Should Be 3
            $sample = Get-Content -LiteralPath $files[0].FullName -Raw
            $sample | Should Match 'type: term'
            $sample | Should Match '## Abstractions'
            $sample | Should Match '\[\[.+\]\]'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
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
            Write-Utf8File $cachePath $cache

            & (Join-Path $repoRoot 'Scripts\Vault\sync_leetcode.ps1') -VaultPath $root -ProblemsDir $problemsDir -CachePath $cachePath -ExistingDir $existingDir -SolvedSlugs @('two-sum')

            $problemFile = Join-Path $problemsDir '1. Two Sum.md'
            Test-Path -LiteralPath $problemFile | Should Be $true
            $content = Get-Content -LiteralPath $problemFile -Raw
            $content | Should Match 'type: problem'
            $content | Should Match 'leetcode_id: 1'
            $content | Should Match '\*\*Status:\*\* Solved'
            $content | Should Match '\[\[Array\]\]'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force
            }
        }
    }
}
