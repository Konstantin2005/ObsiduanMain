# Architecture: Graph Storage Integrity, Compaction and Recovery Framework

## Module Structure
```
src/
  storage/
    wal/
      writer.ts         — WAL append writer
      reader.ts         — WAL sequential reader
      types.ts          — WAL entry types
    shard/
      manager.ts        — Shard lifecycle management
      layout.ts         — Shard partitioning logic
      manifest.ts       — Per-shard manifest
    compaction/
      engine.ts         — Compaction orchestrator
      filter.ts         — Live entry filter
      scheduler.ts      — Compaction scheduling
    recovery/
      crash-recovery.ts — Startup WAL replay
      shard-repair.ts   — Shard integrity restoration
      consistency.ts    — Cross-shard validation
```

## API Design
```typescript
interface ShardConfig {
  maxSizeBytes: number;
  tombstoneRatio: number; // trigger compaction at this ratio
  compression: boolean;
}

interface WALEntry {
  id: string;
  timestamp: number;
  operation: 'write' | 'delete' | 'update';
  shardId: string;
  data: Uint8Array;
  checksum: string;
}

interface CompactionResult {
  shardId: string;
  entriesBefore: number;
  entriesAfter: number;
  bytesFreed: number;
  duration: number;
}
```
