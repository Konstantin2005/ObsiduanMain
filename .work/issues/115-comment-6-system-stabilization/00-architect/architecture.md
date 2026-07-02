# Detected Bugs & Fixes

## BUG-1: StateManager writes to disk on every set()
**File:** `runtime/control-plane/state-manager.js:39`
**Root cause:** `set()` calls `#persist()` which writes global-context.json synchronously.
**Amplification:** orchestrator.set() called per issue routing, agent selection, execution step.
**Fix:** Batch writes — flush every 30s / 100 changes, not per call.

## BUG-2: Orchestrator does everything
**File:** `runtime/control-plane/orchestrator.js`
**Root cause:** orchestrator handles routing, execution, validation, PR creation, logging.
**Fix:** Split: orchestrator decides ONLY → delegates to data plane → observability plane logs.

## BUG-3: Router is stateful
**File:** `runtime/router/multi-repo-router.js:16`
**Root cause:** `this.adapters` is instance state. If router is shared, adapters mutate.
**Fix:** Pass adapters as method param, not constructor state.

## BUG-4: ErrorCaptureLayer can create recursive loop
**File:** `agent-core/src/task-queue/error-capture.js:17`
**Root cause:** capture() calls normalizer.normalize() which can throw → re-enters capture.
**Fix:** Circuit breaker — max 10 errors/sec from same source, then drop.

## BUG-5: CentralLogger has no backpressure
**File:** `runtime/control-plane/central-logger.js:14`
**Root cause:** log() writes to disk on every call. In high-error scenario → IO saturation.
**Fix:** Buffer writes, flush every 5s. Async only.

## BUG-6: global-context.json stores full history
**File:** `shared/global-context.json`
**Root cause:** StateManager stores ALL keys forever → file grows unbounded.
**Fix:** Store only active issues + summary. Archive old entries to central-logs.

## BUG-7: Adapters import execSync (blocking)
**File:** `adapters/github-repo-adapter.js:6`
**Root cause:** execSync blocks event loop during git operations.
**Fix:** Use exec (async) or spawn.

## BUG-8: Lifecycle.handleError has no dedup
**File:** `agent-os/bridge/src/lifecycle.js:28`
**Root cause:** Same error can be captured multiple times → duplicate tasks.
**Fix:** Dedup by error hash + source before queuing.

## BUG-9: No task queue depth limit
**File:** `agent-core/src/task-queue/task-runner.js`
**Root cause:** tasks accumulate in /tasks/ forever.
**Fix:** Max 1000 pending tasks, oldest dropped.

## BUG-10: Scheduler priority sort is O(n log n) per enqueue
**File:** `runtime/control-plane/scheduler.js:16`
**Root cause:** #sort() called on every enqueue. At scale → CPU waste.
**Fix:** Use binary insertion or limit queue to 100 max.
