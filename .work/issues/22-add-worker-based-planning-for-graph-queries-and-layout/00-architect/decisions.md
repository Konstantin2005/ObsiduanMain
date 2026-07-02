# Key Architectural Decisions

## ADR-1: Fixed Worker Pool
- **Context:** Worker creation overhead must be minimized
- **Decision:** Pre-allocate worker pool at startup, reuse workers
- **Consequence:** Predictable resource usage, no latency from spawning

## ADR-2: Deterministic Result Merging
- **Context:** Results must be reproducible for testing
- **Decision:** Merge by deterministic ordering (node ID, then query ID)
- **Consequence:** Slightly more complex merge, but fully reproducible

## ADR-3: Cancellation Token with Timeout
- **Context:** Workers may hang or exceed time budget
- **Decision:** Timeout-based cancellation with forced cleanup
- **Consequence:** Safe resource cleanup, no orphaned workers
