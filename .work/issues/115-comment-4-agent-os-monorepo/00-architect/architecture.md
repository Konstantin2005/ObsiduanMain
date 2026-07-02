# Architecture: Agent OS Monorepo

## Module Responsibilities

| Module | Responsibility | Indexed | Type |
|--------|---------------|---------|------|
| core | Pipeline execution, agents, templates | ✅ | Runtime |
| orchestration | Reference patterns, read-only | ❌ | Reference |
| telemetry | Error collection, transport, fallback | ✅ | Runtime |
| task-queue | Error→task, normalizer, runner | ✅ | Runtime |
| bridge | Mappers + lifecycle orchestrator | ✅ | Integration |

## Bridge Lifecycle (lifecycle.js)

```
Error captured
  ↓
bridge.lifecycle.onError(error, source)
  ├──→ telemetry.collect(error, source)     (async log)
  └──→ task-queue.capture(error, source)    (async task creation)
          ↓
      task-queue.normalizer(task)            (dedup + structure)
          ↓
      task-queue.runner.pickNext()           (pick highest priority)
          ↓
      core.pipeline.execute(task)            (execute fix)
          ↓
      task-queue.runner.validate(result)     (validate fix)
          ↓
      telemetry.collect(result, 'fix')       (log result)
```

## Migration Plan
1. Create agent-os/ with 6 directories
2. Copy core/ from agent-core/src/ → agent-os/core/src/
3. Copy orchestration/ from ai-dev-orchestration-system/ → agent-os/orchestration/
4. Copy telemetry/ from agent-core/src/telemetry/ → agent-os/telemetry/src/
5. Copy task-queue/ from agent-core/src/task-queue/ → agent-os/task-queue/src/
6. Create bridge/ with lifecycle.js + mappers
7. Add configs + docs
