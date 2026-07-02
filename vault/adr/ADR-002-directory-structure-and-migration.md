# ADR-002: Структура каталогов и план миграции

**Статус:** Принят  
**Дата:** 2026-06-25  
**Автор:** Architecture Board  
**Связанные задачи:** #2, #3, #4, #98  

---

## Целевая структура каталогов

```
ObsiduanMain/
│
├── src/                                     # Исходный код (Source of Truth)
│   ├── graph-runtime/                       #   JS рантайм графа
│   │   ├── build-calendula-graph-store.js
│   │   ├── graph-build-runtime.js
│   │   ├── graph-capacity-lease-runtime.js
│   │   ├── graph-deep-validation.js
│   │   ├── graph-evidence-engine.js
│   │   ├── graph-governors.js
│   │   ├── graph-index-compiler.js
│   │   ├── graph-multiscale.js
│   │   ├── graph-query-engine.js
│   │   ├── graph-stability.js
│   │   ├── graph-throughput-governor.js
│   │   └── graph-worker-layer.js
│   │
│   ├── rendering/                           #   Рендеринг графа
│   │   ├── graph-critical-frame.js
│   │   ├── graph-render-plan.js
│   │   ├── graph-renderer-upgrade.js
│   │   ├── graph-scheduler.js
│   │   └── live-graph/
│   │       ├── builtin-graph.js
│   │       └── live-graph-core.js
│   │
│   ├── scripts/                             #   PowerShell-автоматизация
│   │   ├── git/
│   │   │   ├── daily-push.ps1
│   │   │   ├── monitor-daily-push.ps1
│   │   │   ├── threshold-git.ps1
│   │   │   └── update-github-issues.ps1
│   │   ├── vault/
│   │   │   ├── auto-commit.ps1
│   │   │   ├── Collect-Mentions.ps1
│   │   │   ├── Consolidate-PeopleSplit.ps1
│   │   │   ├── Move-TodayTasks.ps1
│   │   │   ├── Normalize-DayNoteNumbers.ps1
│   │   │   ├── Restore-PeopleSplit.ps1
│   │   │   ├── Sort-BoardTasks.ps1
│   │   │   ├── Split-DiaryPeople.ps1
│   │   │   ├── sync_leetcode.ps1
│   │   │   ├── vault-helpers.ps1
│   │   │   └── Watch-Kanban.ps1
│   │   ├── discord/
│   │   │   └── Send-FileToDiscord.ps1
│   │   ├── launchers/
│   │   │   ├── run-daily-push.vbs
│   │   │   ├── run-hidden.vbs
│   │   │   ├── run-hourly.vbs
│   │   │   └── run-watcher.vbs
│   │   └── benchmarks/
│   │       ├── measure-*.js
│   │       └── Measure-CalendulaGraphPerformance.ps1
│   │
│   └── generators/                          #   Генераторы контента
│       ├── generate_all_graphs.py
│       ├── generate_personality_map.ps1     #   Единый скрипт (параметр -Iteration)
│       ├── rebuild_mocs.py
│       ├── update_developer_issue_plans.ps1
│       ├── create_mocs.py
│       ├── generate_decisions.py
│       ├── generate_goals.py
│       ├── generate_knowledge_graph.py
│       ├── generate_projects.py
│       └── generate_reflections.py
│
├── content/                                 # Пользовательский контент (markdown)
│   ├── vault-life/                          #   Life vault (Calendula, Algoritm)
│   │   ├── Calendula/
│   │   ├── Algoritm/
│   │   └── CRM/
│   ├── vault-zetl/                          #   Zettelkasten vault
│   │   ├── BiasGraph/
│   │   ├── PersonalityGraph/
│   │   ├── KnowledgeGraphs/
│   │   ├── IdeaEcosystem/
│   │   ├── QuestionFractal/
│   │   ├── DecisionMakingGraph/
│   │   └── ... (все подграфы)
│   ├── vault-angl/                          #   English vault
│   │   ├── Асоциации/
│   │   └── Слова/
│   └── technical/                           #   Technical vault
│       └── .obsidian/
│
├── docs/                                    # Документация
│   ├── adr/
│   │   ├── ADR-001-architecture-consolidation.md
│   │   └── ADR-002-directory-structure-and-migration.md
│   ├── architecture/
│   │   └── graph-platform-architecture.md
│   ├── engineering-blueprint-2026.md
│   └── vault-blueprint-v1.md
│
├── tests/                                   # Тесты
│   ├── Scripts.Tests.ps1
│   └── test-legacy.ps1
│
├── archive/                                 # Архивированные данные (ex-Старое/)
│   ├── Calendula-20K/
│   ├── Calendula-30K/
│   ├── Calendula-People-Graph/
│   ├── newCalendula/
│   ├── Tasks/
│   ├── GO/
│   ├── Problems/
│   ├── Prog/
│   └── ...
│
├── .github/                                 # GitHub CI/CD
│   ├── workflows/ci.yml
│   ├── ISSUE_TEMPLATE/
│   └── dependabot.yml
│
├── .gitignore
├── SECURITY.md
└── README.md
```

## План миграции (7 этапов)

### Этап 1: Подготовка (быстро, без риска)
- [ ] Создать `src/`, `content/`, `archive/`, `tests/`, `docs/architecture/` директории
- [ ] Скопировать ADR-документы в `docs/adr/`
- [ ] Обновить `.gitignore` для новых путей

### Этап 2: Перенос исходного кода (низкий риск)
- [ ] `git mv Technical/Scripts/Obsidian/*.js src/graph-runtime/`
- [ ] `git mv Technical/Scripts/Rendering/* src/rendering/`
- [ ] `git mv Technical/Scripts/Git/*.ps1 src/scripts/git/`
- [ ] `git mv Technical/Scripts/Vault/*.ps1 src/scripts/vault/`
- [ ] `git mv Technical/Scripts/Discord/*.ps1 src/scripts/discord/`
- [ ] `git mv Technical/Scripts/Launchers/* src/scripts/launchers/`
- [ ] `git mv Technical/Scripts/Obsidian/measure-*.js src/scripts/benchmarks/`
- [ ] `git mv rebuild_mocs.py src/generators/`
- [ ] `git mv update_developer_issue_plans.ps1 src/generators/`
- [ ] `git mv Zetl/create_mocs.py src/generators/`
- [ ] `git mv Zetl/generate_*.py src/generators/`
- [ ] `git mv Zetl/organize_zetl.py src/generators/`

### Этап 3: Перенос тестов
- [ ] `git mv Technical/Tests/* tests/`

### Этап 4: Перенос контента
- [ ] `git mv Life/ content/vault-life/`
- [ ] `git mv Zetl/ content/vault-zetl/`
- [ ] `git mv Angl/ content/vault-angl/`
- [ ] `git mv Technical/vault/ content/technical/`
- [ ] Перенести .obsidian/ конфиги vault-ов

### Этап 5: Архивирование
- [ ] `git mv Старое/ archive/`
- [ ] Обновить все внутренние ссылки (если есть)

### Этап 6: Удаление дубликатов
- [ ] **Live Graph копии:** заменить `Life/Calendula/.obsidian/plugins/live-graph/`, `Life/Algoritm/.obsidian/plugins/live-graph/`, `Zetl/.obsidian/plugins/live-graph/` на символические ссылки на `src/rendering/live-graph/`
- [ ] **KnowledgeGraphs_Core:** удалить `Zetl/KnowledgeGraphs_Core/` (копия `KnowledgeGraphs/`)
- [ ] **generate_personality_map_final*.ps1:** удалить 15 копий, оставить один параметризованный скрипт
- [ ] **generate.ps1 в подграфах:** удалить, оставить только `generate_all_graphs.py`
- [ ] **Корневые .ps1:** удалить `vault/auto-commit.ps1`, `vault/snapshot.ps1` и т.д. (они продублированы в `src/scripts/`)

### Этап 7: Обновление документации и CI
- [ ] Обновить `docs/engineering-blueprint-2026.md` с новой структурой
- [ ] Обновить `.github/workflows/ci.yml` для новых путей
- [ ] Обновить пути в Scheduled Tasks (Windows)
- [ ] Финальная проверка `git status` на наличие generated артефактов

## График миграции

| Этап | Длительность | Зависимости | Риск |
|---|---|---|---|
| 1. Подготовка | 1 день | — | Низкий |
| 2. Перенос кода | 2 дня | Этап 1 | Средний |
| 3. Перенос тестов | 0.5 дня | Этап 2 | Низкий |
| 4. Перенос контента | 1 день | Этап 2 | Средний |
| 5. Архивирование | 0.5 дня | — | Низкий |
| 6. Удаление дубликатов | 1 день | Этапы 2-5 | Высокий |
| 7. Обновление CI/CD | 1 день | Этапы 2-6 | Средний |

**Общая длительность:** ~7 дней при последовательном выполнении

## Откат

При проблемах на любом этапе:
1. `git stash` всех незакоммиченных изменений
2. `git checkout .` для отката файлов
3. Если уже закоммичено — `git revert <commit>` для конкретного этапа
4. Если `git mv` сделан — `git mv --reverse` не работает, используйте `git reset --soft HEAD~1`
