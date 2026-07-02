# Error Telemetry Architecture

## Components

```
agent-core runtime
    │
    ├── Agent 1 ──┐
    ├── Agent 2 ──┤
    ├── Agent 3 ──┤  try/catch → ErrorCollector (buffer queue)
    ├── Agent 4 ──┤                  │
    ├── Agent 5 ──┘                  │
    │                                │
    ├── Pipeline ────────────────────┘
    ├── Template Engine ─────────────┘
    │
    ▼
ErrorCollector (BufferQueue)
    │  async flush every 5s / 50 items
    ▼
Transport
    │  write JSONL → git commit + push
    ▼
error-telemetry/
  logs/
    2026-06-26/
      agent-errors.jsonl
      pipeline-failures.jsonl
      system-warnings.jsonl
```

## Flow
```
Error → try/catch wrapper → ErrorCollector.buffer(error)
  → [buffer queue] → flush() → Transport.write(jsonl)
  → git add → git commit → git push (background)
  → fallback local file if git fails
```
