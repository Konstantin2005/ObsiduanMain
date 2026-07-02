# Architectural Decisions: Incremental Graph Update

## ADR-1: Batch-based diff instead of event-per-change
**Status**: Accepted
**Context**: Individual FS events may arrive in bursts; processing each individually is expensive and may cause inconsistency.
**Decision**: Collect events in a 500ms window, then compute one diff.
**Consequence**: Slight delay (500ms) in update propagation but significantly fewer recomputations.

## ADR-2: Manifest snapshot as diff baseline
**Status**: Accepted
**Context**: FS events alone are unreliable (missed events, out-of-order delivery).
**Decision**: Maintain a persisted manifest snapshot. Compute diff by comparing current state against snapshot.
**Consequence**: More reliable diff computation, but manifest storage cost grows with vault size.

## ADR-3: 20% threshold for fallback to full rebuild
**Status**: Accepted
**Context**: When changes affect most of the graph, incremental update provides little benefit.
**Decision**: If delta affects >20% of total nodes, fall back to full rebuild.
**Consequence**: Simpler code path for large-scale changes; slight overhead in threshold check.

## ADR-4: Atomic batch commits for consistency
**Status**: Accepted
**Context**: Partial updates could leave graph in inconsistent state (dangling edges, missing nodes).
**Decision**: Wrap each incremental update in an atomic transaction. Either all changes apply, or none.
**Consequence**: Guarantees consistency at the cost of memory overhead for rollback data.

## ADR-5: Node ID stability across renames
**Status**: Accepted
**Context**: When a file is renamed, node ID should remain constant to preserve existing edges and references.
**Decision**: Use a content-hash-based ID that survives renames. Track path separately.
**Consequence**: Complex rename detection but stable graph topology across renames.
