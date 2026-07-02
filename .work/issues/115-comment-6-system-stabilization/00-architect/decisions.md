# Decisions — System Stabilization

| # | Bug | Fix | Complexity |
|---|-----|-----|------------|
| 1 | StateManager per-call write | Batch flush 30s | Low |
| 2 | Orchestrator too big | Split CP/DP/OP | Medium |
| 3 | Router stateful | Stateless params | Low |
| 4 | ErrorCapture recursive | Circuit breaker | Low |
| 5 | Logger no backpressure | Buffer + async | Low |
| 6 | Context full history | Archive + summary | Low |
| 7 | Adapters blocking | Async exec | Low |
| 8 | Lifecycle no dedup | Error hash dedup | Low |
| 9 | Task queue unbounded | Max 1000 depth | Low |
| 10 | Sorter per enqueue | Binary insert | Medium |
