# Decisions Log

## ADR-1: Adaptive thresholds over fixed limits
- **Decision:** Dynamically scale limits
- **Rationale:** Fixed limits poorly across hardware; adaptive = consistent UX
- **Date:** 2026-06-27

## ADR-2: Priority preemptive scheduling
- **Decision:** Interactive preempts background
- **Rationale:** UI responsiveness is paramount
- **Date:** 2026-06-27

## ADR-3: Backpressure via Promise-based signaling
- **Decision:** Async backpressure signal
- **Rationale:** Callers react gracefully
- **Date:** 2026-06-27

## ADR-4: Marker-based resource tracking
- **Decision:** performance.memory + process.cpuUsage
- **Rationale:** Lightweight, cross-platform
- **Date:** 2026-06-27
