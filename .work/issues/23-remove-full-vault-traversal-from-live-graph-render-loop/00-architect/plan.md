# Implementation Plan: Remove Full Vault Traversal from Live Graph Render Loop

## Overview
Separate graph data preparation from rendering so frame work only consumes already-prepared inputs, improving render performance.

## Phases

### Phase 1: Identify In-Frame Vault Traversal
1. Audit current Live Graph render loop code
2. Pinpoint all vault traversal calls in the render path
3. Create timing traces to measure current cost

### Phase 2: Precompute Layer
1. Implement vault traversal as separate precompute phase
2. Trigger precompute on vault change events (file changes, metadata updates)
3. Store prepared graph data in intermediate representation

### Phase 3: Snapshot Manager
1. Implement immutable snapshot creation from precompute output
2. Add snapshot versioning for consistency
3. Implement snapshot swapping (atomic read-update)

### Phase 4: Update Renderer
1. Modify renderer to consume snapshots instead of raw vault data
2. Ensure renderer works with prepared IR, not raw vault structure
3. Add fallback for snapshot unavailability

### Phase 5: Timing and Validation
1. Add timing monitor to track frame durations
2. Compare before/after metrics
3. Validate output correctness against baseline

## Deliverables
- `src/live-graph/precompute.rs` — Precompute engine
- `src/live-graph/snapshot.rs` — Snapshot manager
- `src/live-graph/renderer.rs` — Updated renderer (snapshot consumer)
- `src/live-graph/timing.rs` — Timing monitor
- Tests in `tests/live-graph/`
