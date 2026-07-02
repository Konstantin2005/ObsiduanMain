# Key Architectural Decisions

## ADR-1: Off-Thread Precompute via Event Trigger
- **Context:** Vault traversal must be removed from render hot path
- **Decision:** Precompute runs in separate thread, triggered by vault change events
- **Consequence:** No traversal cost in frame budget, but stale data possible until precompute finishes

## ADR-2: Immutable Snapshots for Thread Safety
- **Context:** Renderer and precompute may run concurrently
- **Decision:** Use immutable snapshots with atomic reference swapping
- **Consequence:** No lock contention, safe concurrent access, memory overhead for double buffering

## ADR-3: Passive Timing Monitor
- **Context:** Need before/after metrics without impacting render performance
- **Decision:** Timing monitor reads frame timestamps from GPU/compositor, no inline instrumentation
- **Consequence:** Zero overhead on render path, but less granular timing data
