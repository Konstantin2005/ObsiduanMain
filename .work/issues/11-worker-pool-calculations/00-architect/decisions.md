# Architectural Decisions: Worker Pool Calculations

## ADR-1: Web Workers API instead of Node.js worker_threads
**Status**: Accepted
**Context**: The application runs primarily in Electron/Obsidian plugin context with browser APIs available.
**Decision**: Use Web Workers API for portability; fallback to main-thread execution if Workers unavailable.
**Consequence**: Browser-compatible; structured clone overhead; no shared memory (SharedArrayBuffer if needed).

## ADR-2: Priority queue with preemption for critical tasks
**Status**: Accepted
**Context**: Not all computations are equal — UI-affecting tasks must complete quickly.
**Decision**: 4-level priority queue where Critical/High tasks can preempt Normal/Low running tasks.
**Consequence**: Better UX responsiveness; complexity in task cancellation and resumption.

## ADR-3: Versioned graph snapshots for state consistency
**Status**: Accepted
**Context**: Workers may receive stale data if graph changes while task is queued.
**Decision**: Each graph snapshot carries a version. Workers check version on completion; if stale, result is discarded.
**Consequence**: Guarantees consistency; some wasted computation on stale tasks.

## ADR-4: Pool size = CPU cores - 1
**Status**: Accepted
**Context**: Using all cores starves the UI thread of CPU time.
**Decision**: Reserve one core for UI/main thread. Minimum pool size = 2.
**Consequence**: Balanced responsiveness vs throughput.

## ADR-5: Structured clone with Transferable objects for large payloads
**Status**: Accepted
**Context**: Serializing 20K+ nodes for layout computation is expensive.
**Decision**: Use Transferable objects (ArrayBuffer, OffscreenCanvas) for zero-copy transfer where possible.
**Consequence**: Reduced serialization overhead; more complex memory management.
