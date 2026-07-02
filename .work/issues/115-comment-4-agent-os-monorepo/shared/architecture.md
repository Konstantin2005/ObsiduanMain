# Agent OS: Monorepo Architecture

## Финальная структура
```
agent-os/
├── core/                    ← Execution engine
│   └── src/
│       ├── orchestrator.js
│       ├── pipeline.js
│       ├── agent.js
│       ├── agents/          — 5 role agents
│       ├── templates/       — engine, loader, registry
│       └── shared/          — memory, context, logger
│
├── orchestration/           ← Reference (read-only)
│   └── patterns/
│       ├── agents/
│       ├── pipeline/
│       └── templates/
│
├── telemetry/               ← Error logging
│   └── src/
│       ├── error-logger.js
│       ├── error-collector.js
│       ├── transport.js
│       └── fallback-storage.js
│
├── task-queue/              ← Error → Task → Execution
│   └── src/
│       ├── error-capture.js
│       ├── task-normalizer.js
│       ├── task-runner.js
│       └── task-schema.js
│
├── bridge/                  ← Integration layer
│   └── src/
│       ├── agent-mapper.js
│       ├── pipeline-mapper.js
│       ├── template-adapter.js
│       └── lifecycle.js     ← NEW: orchestrates full error→task→execution flow
│
├── config/
│   ├── opencode.jsonc
│   ├── .opencodeignore
│   └── .gitignore
│
└── docs/
    └── lifecycle.md
```

## Pipeline flow
```
core: error → bridge:lifecycle → telemetry:log + task-queue:capture
  → task-queue:normalize → task-queue:runner → core:execute fix → telemetry:result
```

## Ignore strategy
| Path | Indexed | Reason |
|------|---------|--------|
| core/src/ | ✅ FULL | Runtime execution |
| orchestration/ | ❌ NO | Read-only reference |
| telemetry/src/ | ✅ FULL | Active logging code |
| task-queue/src/ | ✅ FULL | Active execution code |
| bridge/src/ | ✅ FULL | Integration layer |
| telemetry/logs/ | ❌ NO | Runtime data |
| task-queue/data/ | ❌ NO | Runtime data |
