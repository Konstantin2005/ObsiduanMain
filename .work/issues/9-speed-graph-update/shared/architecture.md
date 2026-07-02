# Shared Architecture: Incremental Graph Update

## Overview
Transition from full graph rebuild to incremental diff-based updates.

## Key Components
- **ChangeWatcher**: Watches vault FS events + periodic reconciliation
- **ManifestSnapshot**: Last-known state of all notes
- **GraphDiff**: Computes delta between old manifest and current state
- **IncrementalUpdater**: Applies changes atomically to graph store
- **ConsistencyChecker**: Validates graph integrity post-update

## Data Flow
1. Collect FS events (500ms window) → compute diff
2. If diff >20% threshold → fallback to full rebuild
3. Apply delta: remove → update → add → handle renames
4. Run consistency check → commit manifest snapshot

## Key Interfaces
See `00-architect/architecture.md` for detailed interfaces.

## Integration Points
- GraphStore: adds `applyIncremental(delta)` method
- Manifest: persists snapshot after each successful update
- UI: receives partial update notifications (not full reload)
