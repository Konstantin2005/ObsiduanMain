# Key Decisions: Graph Performance Governor and Workload Scheduler

## ADR-1: Adaptive thresholds over fixed limits
- **Decision:** Dynamically scale limits based on observed system behavior
- **Rationale:** Fixed limits work poorly across different hardware; adaptive provides consistent UX
- **Trade-off:** More complex; requires baseline period

## ADR-2: Priority preemptive scheduling
- **Decision:** Interactive work preempts background work at any point
- **Rationale:** UI responsiveness is paramount; background work can wait
- **Trade-off:** Background tasks may starve under sustained interactive load

## ADR-3: Backpressure via Promise-based signaling
- **Decision:** Use async backpressure (return backpressure signal, not throw)
- **Rationale:** Callers can react gracefully by deferring or batching
- **Trade-off:** Requires caller cooperation; cannot enforce hard limits

## ADR-4: Marker-based resource tracking
- **Decision:** Use performance.memory and process.cpuUsage for measurement
- **Rationale:** Lightweight, cross-platform, no native dependencies
- **Trade-off:** Approximate measurements; not real-time
