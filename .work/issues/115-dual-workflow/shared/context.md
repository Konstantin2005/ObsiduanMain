# Issue Context: #115 - Comment-1 Dual Workflow

## Issue Metadata
- **Issue Number**: 115
- **Title**: Commit 114: agent-core + templates system
- **Priority**: N/A (Documentation/Reference)
- **Type**: feature
- **Labels**: None
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-26T04:46:43Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/115

## Issue Body
```
## Что сделано

### agent-core/ — новый JS репозиторий
Создан отдельный репозиторий `agent-core/` с кастомной Agent Core системой на JavaScript (ES modules).

#### src/templates/ — Template Engine
- **engine.js** — рендеринг: `[var]`, `{% if %}`, `{% each as %}`
- **loader.js** — загрузка .md из templates/
- **registry.js** — Facade: engine + loader

#### src/agents/ — 5 агентов (рефакторинг)
Все агенты переписаны: вместо хардкода используют `renderTemplate(name, vars)`:
- architect → plan.md, architecture.md, decisions.md
- backend → backend-api.md
- frontend → frontend-ui.md
- qa → qa-tests.md
- reviewer → review.md

#### templates/ — 8 markdown шаблонов
Портированы из Main/.work/templates/ и расширены:
- plan.md, architecture.md, decisions.md, context.md
- backend-api.md, frontend-ui.md, qa-tests.md, review.md

#### Pipeline
Pipeline автоматически injectит TemplateRegistry в агентов через `setTemplateRegistry()`.

### Документация
- **Issues.md** — документация всех завершённых Issues (#108, #111, #112, #114)
- **.work/issues/114-agent-core-templates/** — полный pipeline (architect → backend+frontend → qa → review)

### Tests
13 тестов — все проходят:
- TemplateEngine: переменные, conditionals, loops
- TemplateLoader: загрузка, кэш, ошибки
- TemplateRegistry: интеграция
- Orchestrator + pipeline: полный цикл

### Pipeline Status
| Роль | Статус |
|------|--------|
| 🧭 Architect | ✅ |
| ⚙️ Backend | ✅ |
| 🎨 Frontend | ✅ |
| 🧪 QA (13 tests) | ✅ |
| 🔍 Reviewer | ✅ Approve |

### Структура
```
Main/
├── agent-core/
│   ├── src/templates/    — engine, loader, registry
│   ├── src/agents/       — 5 agents
│   ├── src/core/         — orchestrator, pipeline, agent base
│   ├── src/shared/       — memory, context
│   ├── src/logs/         — logger
│   ├── templates/        — 8 .md шаблонов
│   ├── config/           — pipeline.json, agents.json
│   └── tests/            — 13 тестов
├── Issues.md             — все завершённые issues
└── .work/issues/114-agent-core-templates/
    └── 00-architect/, 01-backend-engineer/, ..., shared/, logs/
```

### Файлы
29 новых файлов, +985 строк кода.
```

## Pipeline Status
- **Current Status**: INITIALIZED
- **Created**: 2026-06-27T14:41:00Z
- **Pipeline Steps**:
  - [ ] ARCHITECT (00-architect/)
  - [ ] BACKEND ENGINEER (01-backend-engineer/)
  - [ ] FRONTEND ENGINEER (02-frontend-engineer/)
  - [ ] QA ENGINEER (03-qa-engineer/)
  - [ ] CODE REVIEWER (04-code-reviewer/)

## Tracking Issues
- Architect: TBD
- Backend: TBD
- Frontend: TBD
- QA: TBD
- Reviewer: TBD

## Shared Files
- architecture.md: TBD
- decisions-log.md: TBD