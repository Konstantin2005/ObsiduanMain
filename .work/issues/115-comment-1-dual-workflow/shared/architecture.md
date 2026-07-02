# Dual-Workflow Architecture

## LINE A — Execution Core (agent-core)
- Runtime pipeline execution
- Agents (architect, backend, frontend, qa, reviewer)
- Template engine (render, load, registry)
- Orchestrator + Pipeline
- Shared memory / logging

## LINE B — Orchestration Reference (ai-dev-orchestration-system)
- READ-ONLY reference architecture
- Pattern library для agent workflow
- Research layer (не выполняется)
- Не индексируется OpenCode

## Bridge Layer
```
agent-core                    ai-dev-orchestration-system
    │                                  │
    │   ┌─────────────────────────┐    │
    └───│     Bridge Layer        │────┘
        │  - Agent mapping        │
        │  - Pipeline mapping     │
        │  - Template adapter     │
        │  - Config sync          │
        └─────────────────────────┘
```

## Изоляция
- agent-core НЕ импортирует ai-dev-orchestration-system
- ai-dev-orchestration-system НЕ импортирует agent-core
- Bridge layer читает reference, НО не пишет в него
- .opencodeignore excludes reference system
