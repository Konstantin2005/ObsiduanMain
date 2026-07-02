# Architecture: Incremental Graph Update

## System Overview
```
[Vault FS Events] → [ChangeWatcher] → [GraphDiff] → [IncrementalUpdater] → [GraphStore]
                          ↓                    ↑                  ↓
                     [Manifest Snapshot] ───────┘          [Consistency Checker]
```

## Components

### 1. ChangeWatcher
- Watches vault directory for file changes (create/modify/delete/rename)
- Uses OS file system notifications + periodic reconciliation
- Outputs `ChangeSet` with categorized events

### 2. ManifestSnapshot
- Stores last-known state of all notes (path, hash, modified time)
- Used to compute diff when FS events are insufficient
- Persisted to disk for crash recovery

### 3. GraphDiff
- Compares old manifest vs new state
- Produces `GraphDelta`: {added: Node[], removed: Node[], modified: Node[], moved: {oldPath, newPath}[]}
- Handles cascading effects (e.g., removed node → remove all its edges)

### 4. IncrementalUpdater
- Receives `GraphDelta` and applies changes to in-memory graph
- Updates node registry: insert/update/delete nodes
- Updates edge registry: only edges touching changed nodes
- Operations are atomic per batch

### 5. ConsistencyChecker
- Runs post-update validation: no dangling edges, all nodes referenced exist
- Reports inconsistencies and triggers full rebuild if needed

### 6. GraphStore
- Existing graph storage layer
- Extended with incremental update entry point

## Data Flow
```
1. File change detected → collect events (batch window 500ms)
2. Compute diff against manifest snapshot
3. If diff > 20% of total nodes → fall back to full rebuild
4. Apply diff to graph:
   a. Remove deleted nodes + their edges
   b. Update modified nodes (re-parse, update edges)
   c. Add new nodes (full parse, create edges)
   d. Handle renames (update node path, keep ID)
5. Run consistency check
6. Commit new manifest snapshot
7. Notify UI of incremental change
```

## Key Interfaces
```typescript
interface GraphDelta {
  added: NodeRecord[];
  removed: NodeRecord[];
  modified: NodeRecord[];
  moved: MoveRecord[];
}

interface MoveRecord {
  nodeId: string;
  oldPath: string;
  newPath: string;
}

interface IncrementalUpdateResult {
  applied: boolean;
  nodesAffected: number;
  edgesAffected: number;
  consistencyPassed: boolean;
  fallbackToFull: boolean;
}
```
