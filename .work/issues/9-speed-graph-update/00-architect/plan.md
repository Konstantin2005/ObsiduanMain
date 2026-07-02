# Plan: Incremental Graph Update (Issue #9)

## Objective
Transition from full graph rebuild to incremental update to reduce latency and improve scalability.

## Key Requirements
1. Detect changes (diff model) without full rescan
2. Apply updates to nodes/edges incrementally
3. Handle rename, move, delete correctly
4. Maintain index consistency

## Implementation Steps

### Phase 1: Diff Detection
- Implement `GraphDiff` class that captures changed/added/removed notes
- Watch file system events (Obsidian vault changes)
- Compare with previous manifest to compute delta

### Phase 2: Incremental Update Pipeline
- Create `IncrementalUpdater` that processes diffs
- Update node registry with only changed entries
- Update edge registry — add/remove affected edges only
- Skip unchanged subgraphs entirely

### Phase 3: Consistency & Edge Cases
- Handle file renames (node ID changes)
- Handle deletes (cascade edge removal)
- Handle moves (update paths, keep node ID)
- Atomic commit of changes

### Phase 4: Integration
- Wire into existing `GraphProvider` or `GraphStore`
- Add fallback to full rebuild if diff is too large
- Add metrics/logging for incremental vs full ratio

## Success Criteria
- Graph update completes in <500ms for <1000 changed notes
- No full rebuild for changes affecting <20% of graph
- Consistency checks pass after each incremental update
