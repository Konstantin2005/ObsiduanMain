# SAFE MODE Architecture

## Три плоскости
```
CONTROL PLANE (decisions only)
  └── orchestrator (thin)
      └── router (stateless)

DATA PLANE (execution only)
  └── agents
  └── adapters
  └── task-queue

OBSERVABILITY PLANE (logs only, never triggers execution)
  └── logger (append-only)
  └── state (minimal, on-demand)
```

## 10 Hard Constraints
1. Logs NEVER trigger orchestration
2. State NEVER triggers routing
3. File writes NEVER re-enter control plane
4. Router is stateless (no `this.adapters`, no cache)
5. StateManager is lazy (writes only on explicit save, not per-set)
6. CentralLogger is append-only file, no callbacks
7. ErrorCaptureLayer has circuit breaker (max N errors/min)
8. No JSON persistence in hot path (state flush every 30s, not per-call)
9. Adapters do NOT call back to control plane
10. Task queue has max depth (1000 tasks, oldest dropped)
