# Decisions Log: Incremental Graph Update

## ADR-1: Batch-based diff (500ms window)
Decided to collect events and batch-process to avoid per-event overhead.

## ADR-2: Manifest snapshot as baseline
Persisted snapshot for reliable diff computation despite unreliable FS events.

## ADR-3: 20% fallback threshold
When >20% nodes affected, full rebuild is more efficient.

## ADR-4: Atomic batch commits
Transactional updates to prevent inconsistent graph state.

## ADR-5: Stable node IDs across renames
Content-hash-based IDs survive file renames, preserving edges.
