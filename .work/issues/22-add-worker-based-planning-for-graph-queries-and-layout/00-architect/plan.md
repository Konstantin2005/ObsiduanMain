# Implementation Plan: Worker-Based Planning for Graph Queries and Layout

## Overview
Move expensive graph planning and layout computation into workers to keep the main thread free for UI responsiveness.

## Phases

### Phase 1: Worker Pool Infrastructure
1. Define WorkerPool interface with lifecycle management
2. Implement worker spawning and reuse
3. Add task queue and scheduling

### Phase 2: Planner Worker
1. Extract query planning logic into separate worker task
2. Implement deterministic plan output
3. Add plan caching for repeated queries

### Phase 3: Layout Worker
1. Extract graph layout computation into worker
2. Implement deterministic layout output
3. Add layout increment/decrement for changes

### Phase 4: Result Merging and Safety
1. Implement deterministic result merger
2. Add cancellation token propagation
3. Add timeout and forced cleanup

### Phase 5: Testing and Benchmarking
1. Unit tests for worker pool
2. Integration tests for planning+layout pipeline
3. Benchmark: UI responsiveness before/after

## Deliverables
- `src/workers/pool.rs` — WorkerPool
- `src/workers/planner.rs` — PlannerWorker
- `src/workers/layout.rs` — LayoutWorker
- `src/workers/merger.rs` — ResultMerger
- `src/workers/cancellation.rs` — CancellationToken
- Tests in `tests/workers/`
