# Decisions Log: DEV: Remove full vault traversal from Live Graph render loop

## Decision 1: Precompute off Render Thread
- **Date:** 2026-06-27
- **Decision:** Move vault traversal to a separate precompute phase triggered by vault change events
- **Rationale:** Separates data preparation from rendering, allowing frame budget to focus on drawing
- **Alternatives Considered:**
  - Incremental in-frame traversal — still consumes frame time

## Decision 2: Snapshot-Based Data Handoff
- **Date:** 2026-06-27
- **Decision:** Use immutable snapshots for data handoff between precompute and renderer
- **Rationale:** Immutable snapshots prevent race conditions and ensure consistency
- **Alternatives Considered:**
  - Shared mutable state — risk of data races

## Decision 3: Timing Monitor as Passive Observer
- **Date:** 2026-06-27
- **Decision:** Timing monitor logs frame durations without affecting render pipeline
- **Rationale:** Observability without performance overhead
- **Alternatives Considered:**
  - Inline timing — adds overhead to hot path
