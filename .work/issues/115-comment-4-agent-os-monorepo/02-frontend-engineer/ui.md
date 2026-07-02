# Agent OS — Monorepo Structure

```
agent-os/
├── core/                     ← Execution (indexed)
├── orchestration/            ← Reference (NOT indexed)
├── telemetry/                ← Error logging (indexed)
├── task-queue/               ← Task execution (indexed)
├── bridge/                   ← Integration (indexed)
├── config/                   ← Configs
├── docs/                     ← Documentation
├── package.json
├── README.md
└── (orchestration/ → excluded from indexing)
```

## OpenCode Indexing

| Path | Indexed | Reason |
|------|---------|--------|
| core/ | ✅ | Runtime code |
| bridge/ | ✅ | Integration code |
| telemetry/src/ | ✅ | Active code |
| task-queue/src/ | ✅ | Active code |
| orchestration/ | ❌ | Read-only reference |
| **/data/ | ❌ | Runtime output |
| **/logs/ | ❌ | Runtime output |
| *.log, *.jsonl | ❌ | Log files |
