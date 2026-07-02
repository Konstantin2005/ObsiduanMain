# Decisions Log: DEV: Add worker-based planning for graph queries and layout

## Decision 1: Use Dedicated Worker Pool over Dynamic Spawning
- **Date:** 2026-06-27
- **Decision:** Pre-create a fixed-size worker pool instead of spawning workers on demand
- **Rationale:** Fixed pool avoids startup latency and prevents unbounded resource usage
- **Alternatives Considered:**
  - Dynamic spawning — may introduce latency spikes

## Decision 2: Deterministic Result Merging with Ordering Guarantees
- **Date:** 2026-06-27
- **Decision:** Worker results are merged using deterministic ordering (by graph node ID) to ensure reproducibility
- **Rationale:** Determinism is critical for debugging and testing
- **Alternatives Considered:**
  - Non-deterministic merge (first-come-first-serve) — hard to debug

## Decision 3: Cancellation via Token with Resource Cleanup
- **Date:** 2026-06-27
- **Decision:** Use cancellation tokens that propagate to all workers, with forced cleanup after timeout
- **Rationale:** Ensures no orphaned workers or leaked resources
- **Alternatives Considered:**
  - Abort signals — less structured, harder to trace
