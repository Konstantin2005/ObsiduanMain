# Frontend: Project Structure

## Финальная структура
```
C:/obsidian/
├── agent-core/                     ← LINE A (runtime, indexed)
│   ├── src/
│   │   ├── core/
│   │   ├── agents/
│   │   ├── templates/
│   │   ├── bridge/                 ← NEW: Bridge Layer
│   │   ├── shared/
│   │   └── logs/
│   ├── templates/
│   ├── config/
│   ├── .opencodeignore
│   └── opencode.jsonc
│
├── ai-dev-orchestration-system/    ← LINE B (reference, NOT indexed)
│   ├── patterns/agents/
│   ├── patterns/pipeline/
│   ├── patterns/templates/
│   ├── architecture/
│   ├── docs/
│   └── .opencodeignore (exclude all)
│
└── Main/
    ├── agent-core/                 ← Git submodule / folder
    ├── .work/issues/
    ├── .opencodeignore
    └── opencode.jsonc
```

## Изоляция
| Path | Indexed | Notes |
|------|---------|-------|
| agent-core/src/ | ✅ FULL | Runtime code |
| agent-core/.work/issues/*/logs/ | ❌ EXCLUDED | Runtime noise |
| agent-core/**/*.log | ❌ EXCLUDED | Log files |
| ai-dev-orchestration-system/ | ❌ EXCLUDED | Read-only reference |
| Main/.work/issues/ | ✅ | Issue documentation |
