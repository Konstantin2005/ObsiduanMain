# Implementation Plan: Storage Compaction and Manifest Recovery

## Overview
Apply a storage maintenance flow that is safe, observable, and easy to validate for shard store compaction and manifest repair.

## Phases

### Phase 1: Compaction Engine
1. Define compaction triggers (time-based, size-based, manual)
2. Implement shard scanning for stale/mergeable shards
3. Implement copy-on-write compaction logic
4. Add atomic swap of compacted data

### Phase 2: Manifest Recovery
1. Implement manifest checksum validation
2. Add auto-repair for common corruption patterns
3. Implement recovery diagnostics reporter

### Phase 3: Safety and Validation
1. Add pre/post-operation state validation
2. Implement dry-run mode for safety
3. Add rollback capability for failed compactions

### Phase 4: Testing
1. Unit tests for compaction algorithms
2. Integration tests for manifest recovery
3. Large-scale data validation tests

## Deliverables
- `src/storage/compaction.rs` — CompactionEngine
- `src/storage/manifest.rs` — Manifest recovery logic
- `src/storage/diagnostics.rs` — Operation logging
- Tests in `tests/storage/`
