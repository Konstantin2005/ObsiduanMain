# Error → Task → Execution Pipeline

## Flow
```
Error → ErrorCaptureLayer → TaskNormalizer → TaskQueue → TaskPicker → TaskRunner → Validate
  │                            │                │            │             │
  │                            │                │            │             └→ Archive / Failed
  │                            │                │            │
  │                            │                └────────────┘
  │                            └─ Dedup check
  └─ Async log (telemetry)
```

## Repository: error-task-queue/
```
/incoming/     — raw errors (JSONL)
/tasks/        — normalized tasks (JSON)
/archive/      — completed tasks
/failed/       — failed tasks
/meta/         — dedup cache, state
```

## Task State Machine
```
ERROR → NORMALIZED → QUEUED → PICKED → EXECUTING → VALIDATING → DONE
                                                          ↓
                                                       FAILED → RETRY → QUEUED
                                                                     ↓
                                                                  ARCHIVED
```
