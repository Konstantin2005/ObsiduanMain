# Unified AI Development OS — Final Architecture

## 1. Final Unified Architecture
```
C:/obsidian/
├── runtime/                      ← NEW: Unified Control Plane
│   ├── control-plane/
│   │   ├── orchestrator.js       — единый Orchestrator для всех репо
│   │   ├── scheduler.js          — TaskScheduler (priority, queue)
│   │   └── state-manager.js      — глобальное состояние всех репо
│   ├── router/
│   │   └── multi-repo-router.js  — определяет source → target repo
│   ├── agents/                   — глобальные агенты (5 ролей)
│   │   ├── architect.js
│   │   ├── backend.js
│   │   ├── frontend.js
│   │   ├── qa.js
│   │   └── reviewer.js
│   └── validation/
│       └── zero-trust.js         — validate все вводы/выводы
│
├── adapters/                     ← NEW: Repository Adapters
│   ├── github-repo-adapter.js    — для GitHub репозиториев
│   ├── obsidian-repo-adapter.js  — для Obsidian/Main
│   └── generic-repo-adapter.js   — fallback
│
├── shared/
│   └── global-context.json       — единый state всех репо
│
├── central-logs/                 ← NEW: unified logging
│   ├── execution-trace.log
│   ├── agent-performance.log
│   └── repo-routing.log
│
├── agent-os/                     ← существующий monorepo (превращается в плагин)
├── agent-core/                   ← существующий (plugin)
├── error-telemetry/              ← существующий (plugin)
├── error-task-queue/             ← существующий (plugin)
├── ai-dev-orchestration-system/  ← существующий (plugin)
└── Main/                         ← существующий (plugin)
```

## 2. Control Plane Design
Control Plane — единственный "мозг". Он:
- Принимает Issue из любого репо
- Определяет target_repo для execution
- Выбирает агента
- Запускает execution
- Валидирует результат
- Создаёт PR

## 3. Multi-Repo Router
```
router.route(issue):
  1. Определяет sourceRepo (откуда issue)
  2. Определяет targetRepo (куда писать)
  3. Загружает context из sourceRepo
  4. Возвращает { sourceRepo, targetRepo, context }
```

## 4. Repository Adapter
Каждый adapter реализует интерфейс:
```
readIssue(id) → Issue
fetchContext() → Context
writeFile(path, content) → void
createPR(title, branch) → PR
logExecution(entry) → void
```

## 5. Single Orchestrator Flow
```
Issue → ControlPlane.route() → Adapter.readIssue()
  → AgentSelection → Agent.execute() → Adapter.writeFile()
  → Validation → Adapter.createPR() → CentralLog
```

## 6. Shared Context Model
```json
{
  "repositories": {
    "agent-core": { "active_issues": [], "state": "idle" },
    "ObsidianMain": { "active_issues": ["#115"], "state": "executing" }
  },
  "active_agents": [
    { "id": "architect-1", "repo": "ObsidianMain", "issue": "#115" }
  ],
  "execution_history": [],
  "metrics": {}
}
```
