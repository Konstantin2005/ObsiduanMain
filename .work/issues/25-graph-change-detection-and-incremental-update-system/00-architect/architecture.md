# Architecture: Graph Change Detection and Incremental Update System

## Module Structure
```
src/
  graph/
    change-detection/
      watcher.ts        — File system watcher
      hasher.ts         — Content hash computation
      scanner.ts        — Metadata scanning
      diff-engine.ts    — Change set generation
      types.ts          — ChangeSet, Change, etc.
    incremental/
      node-updater.ts   — Node CRUD operations
      edge-updater.ts   — Edge update operations
      layout-updater.ts — Subgraph layout updates
      manifest-updater.ts — Manifest partial updates
    consistency/
      transaction.ts    — Batch transaction manager
      rollback.ts       — Rollback handler
      validator.ts      — Post-update consistency checks
```

## API Design
```typescript
interface ChangeSet {
  added: FileChange[];
  modified: FileChange[];
  deleted: FileChange[];
  renamed: { oldPath: string; newPath: string }[];
}

interface FileChange {
  path: string;
  hash: string;
  content?: string;
  metadata: FileMetadata;
}

interface IncrementalUpdateResult {
  success: boolean;
  nodesAffected: number;
  edgesAffected: number;
  manifestVersion: string;
  errors?: string[];
}
```
