# Implementation Plan: Graph Storage Integrity, Compaction and Recovery Framework

## Phase 1: Atomic Write Layer
1. Write-ahead log (WAL) implementation
   - Sequential append-only log
   - Commit marker after successful write
2. Atomic manifest updates
   - Rename-based atomic file replacement
   - Checksum verification on read
3. Shard-based storage layout
   - Partition graph data into manageable shards
   - Each shard has its own manifest

## Phase 2: Compaction Engine
1. Tombstone-based deletion tracking
   - Mark deleted entries, purge during compaction
2. Compaction trigger conditions
   - Threshold: shard size > limit, tombstone ratio > 30%
   - Idle-triggered: schedule during low activity
3. Compaction process
   - Read shard → filter live entries → write new shard → atomic swap
   - Old shard kept until compaction verified

## Phase 3: Recovery Framework
1. Crash recovery
   - Replay WAL on startup
   - Detect incomplete writes via checksums
2. Shard repair
   - Verify manifest against actual data
   - Rebuild corrupted shards from WAL
3. Consistency checker
   - Cross-shard reference validation
   - Periodic background verification
