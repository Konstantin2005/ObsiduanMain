# Architecture: Error → Task → Execution Pipeline

## Task Schema (JSON)
```json
{
  "id": "task-<uuid>",
  "title": "BackendAgent: TypeError in plan.md generation",
  "problem": "Cannot read properties of undefined (reading 'title')",
  "context": {
    "source": "agent.backend",
    "error_type": "TypeError",
    "stack": "...",
    "workspace": ".work/issues/115-...",
    "severity": "error"
  },
  "reproduction": [
    "1. Run orchestrator with issue #115",
    "2. BackendAgent.execute() reads memory.get('issue')",
    "3. Issue object has no title property"
  ],
  "expected_fix": "Add default title fallback when memory.get('issue').title is undefined",
  "constraints": ["No external deps", "Must be async"],
  "severity": "error",
  "readiness_score": 0.85,
  "state": "normalized",
  "created_at": "2026-06-26T15:00:00.000Z",
  "retry_count": 0,
  "dedup_key": "agent.backend:TypeError:title"
}
```

## Components

### ErrorCaptureLayer
- Intercepts errors from agents, pipeline, template engine
- Async, non-blocking
- Sends to TaskNormalizer + ErrorTelemetry simultaneously

### TaskNormalizer
- Transforms raw error → structured task
- Computes dedup_key
- Assigns readiness_score
- Writes to /tasks/

### TaskPicker
- Picks highest readiness_score task
- Considers retry_count, severity
- Moves task → PICKED state

### TaskRunner
- Reads task
- Executes expected_fix logic
- Runs validation
- Moves to DONE or FAILED

### TaskStatusManager
- State machine transitions
- Dedup cache in /meta/
- Retry logic (max 3 retries)
