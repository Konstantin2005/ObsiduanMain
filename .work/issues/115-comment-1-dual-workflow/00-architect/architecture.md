# Architecture: Dual-Workflow Integration

## Финальная структура папок
```
C:/obsidian/
├── agent-core/                    ← LINE A (execution)
│   ├── src/
│   │   ├── core/                  — orchestrator, pipeline, agent
│   │   ├── agents/                — 5 role agents
│   │   ├── templates/             — engine, loader, registry
│   │   ├── bridge/                ← NEW: Bridge Layer
│   │   │   ├── agent-mapper.js    — mapping agent-core → reference
│   │   │   ├── pipeline-mapper.js — mapping pipeline stages
│   │   │   └── template-adapter.js— адаптер шаблонов
│   │   ├── shared/
│   │   └── logs/
│   ├── templates/
│   └── config/
│
├── ai-dev-orchestration-system/   ← LINE B (reference, read-only)
│   ├── patterns/                  — reference patterns
│   ├── architecture/              — reference architecture
│   └── README.md
│
└── Main/
    ├── agent-core/                ← symlink or copy? → NO, readonly reference
    └── .work/issues/
```

## Bridge Layer Mapping

### Agent Mapping
| agent-core | ai-dev-orchestration-system |
|------------|----------------------------|
| ArchitectAgent | AgentArchitect pattern |
| BackendAgent | AgentBackend pattern |
| FrontendAgent | AgentFrontend pattern |
| QAAgent | AgentQA pattern |
| ReviewerAgent | AgentReviewer pattern |

### Pipeline Mapping
| agent-core stage | reference pattern |
|-----------------|-------------------|
| architect (serial) | PipelineStep.ANALYSIS |
| backend + frontend (parallel) | PipelineStep.DEVELOPMENT |
| qa (serial) | PipelineStep.TESTING |
| reviewer (serial) | PipelineStep.REVIEW |

## Границы ответственности
| Компонент | agent-core | reference system |
|-----------|------------|------------------|
| Pipeline execution | ✅ runtime | ❌ design only |
| Agent logic | ✅ runtime | ❌ pattern only |
| Templates | ✅ render | ❌ examples only |
| Logging | ✅ execution logs | ❌ not used |
| Error handling | ✅ runtime | ❌ not used |
| CI/CD | ✅ active | ❌ not needed |

## Правила изоляции
1. **agent-core** → OpenCode indexing: FULL
2. **ai-dev-orchestration-system** → OpenCode indexing: EXCLUDED (.opencodeignore)
3. **Bridge layer** → OpenCode indexing: FULL
4. **agent-core runtime output** (.work/issues/) → EXCLUDED
5. **logs/ → EXCLUDED**
