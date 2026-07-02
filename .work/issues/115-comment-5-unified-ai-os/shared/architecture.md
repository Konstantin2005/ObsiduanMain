# Unified AI Development OS — Architecture

## Control Plane Design
```
UNIFIED AI DEV OS
│
├── Control Plane              ← NEW (central brain)
│   ├── /runtime/
│   │   ├── control-plane/
│   │   │   ├── orchestrator.js   — единый оркестратор
│   │   │   ├── scheduler.js      — планировщик задач
│   │   │   └── state-manager.js  — глобальное состояние
│   │   ├── router/
│   │   │   └── multi-repo-router.js — маршрутизация между репо
│   │   ├── agents/               — глобальные агенты (5 ролей)
│   │   └── validation/           — zero-trust validation
│   │
│   ├── adapters/                 ← NEW (repo connectors)
│   │   ├── github-repo-adapter.js
│   │   ├── obsidian-repo-adapter.js
│   │   └── generic-repo-adapter.js
│   │
│   ├── shared/
│   │   └── global-context.json   — единый контекст
│   │
│   └── central-logs/
│       ├── execution-trace.log
│       ├── agent-performance.log
│       └── repo-routing.log
```

## Unified Flow
```
GitHub Issue (any repo)
  → Unified Router (определяет target repo)
  → Repo Context Loader (загружает контекст)
  → Agent Selection Engine (выбирает агента)
  → Execution Engine (LangGraph or fallback)
  → Validation Layer (zero-trust)
  → Write back to TARGET REPO
  → PR creation in SAME repo
  → Central Logging
```

## Global Agent System
Все агенты НЕ привязаны к одному репо:
- Architect → анализ любого issue
- Backend → реализация в любом репо
- Frontend → UI в любом репо
- QA → тестирование cross-repo
- Reviewer → ревью cross-repo
