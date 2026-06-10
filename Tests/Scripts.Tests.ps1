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

    It 'compresses live-graph snapshots before persisting them' {
        $root = New-TempRoot
        try {
            $repoRootJson = $repoRoot | ConvertTo-Json -Compress
            $scriptContent = @'
(async () => {
  const path = require('path');
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
          read: async () => '',
          modify: async () => {},
          getAbstractFileByPath: () => null,
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

  const big = 'Alpha beta '.repeat(2000);
  plugin.activeBatch = {
    cycleId: 'cycle-1',
    files: [
      { path: 'A.md', original: big, detached: big + 'x' },
      { path: 'B.md', original: big + 'y', detached: big + 'z' },
    ],
  };
  plugin.safetyBuffer = [
    {
      id: 'entry-1',
      createdAt: '2026-06-10T00:00:00.000Z',
      status: 'detached',
      files: [
        { path: 'A.md', original: big, detached: big + 'x' },
        { path: 'B.md', original: big + 'y', detached: big + 'z' },
      ],
    },
  ];

  await plugin.saveState();

  if (!savedState || !savedState.activeBatch) {
    throw new Error('State was not saved');
  }

  const rawSize = Buffer.byteLength(JSON.stringify({
    activeBatch: {
      cycleId: 'cycle-1',
      files: [
        { path: 'A.md', original: big, detached: big + 'x' },
        { path: 'B.md', original: big + 'y', detached: big + 'z' },
      ],
    },
  }), 'utf8');
  const savedSize = Buffer.byteLength(JSON.stringify(savedState), 'utf8');

  if (savedSize >= rawSize / 4) {
    throw new Error(`Expected compact state, raw=${rawSize}, saved=${savedSize}`);
  }

  if (typeof savedState.activeBatch.files[0].original !== 'string' || !savedState.activeBatch.files[0].original.startsWith('~z~')) {
    throw new Error('Active batch original was not compressed');
  }

  const createReloaded = require(path.join(root, 'Scripts/ObsidianPlugins/live-graph/builtin-graph.js'));
  let reloadedData = savedState;
  class ReloadPlugin extends Plugin {
    async loadData() { return reloadedData; }
    async saveData(data) { reloadedData = data; }
  }

  const reloaded = new (createReloaded({ ItemView, Notice, Plugin: ReloadPlugin, PluginSettingTab, Setting, setIcon }))();
  await reloaded.onload();

  if (reloaded.activeBatch.files[0].original !== big) {
    throw new Error('Active batch did not decompress on load');
  }

  if (reloaded.safetyBuffer.length !== 1 || reloaded.safetyBuffer[0].files[1].detached !== big + 'z') {
    throw new Error('Safety buffer did not initialize from active batch');
  }

  process.stdout.write('compact-state:ok\\n');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
'@
            $scriptContent = $scriptContent.Replace('__REPO_ROOT__', $repoRootJson)
            $scriptPath = Join-Path $root 'live-graph-compact-state-check.js'
            Write-Utf8Text -Path $scriptPath -Content $scriptContent

            $output = & node $scriptPath 2>&1

            $LASTEXITCODE | Should Be 0
            ($output -join [Environment]::NewLine) | Should Match 'compact-state:ok'
        }
        finally {
            if (Test-Path -LiteralPath $root) {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
