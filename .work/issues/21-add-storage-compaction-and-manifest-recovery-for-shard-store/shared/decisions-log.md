# Decisions Log: DEV: Add storage compaction and manifest recovery for shard store

## Decision 1: Copy-on-Write Compaction Strategy
- **Date:** 2026-06-27
- **Decision:** Use copy-on-write (CoW) for compaction to avoid data loss during failures
- **Rationale:** CoW ensures atomicity — if compaction fails, original data remains intact
- **Alternatives Considered:**
  - In-place compaction — risky if process crashes mid-operation

## Decision 2: Manifest Recovery via Checksum Validation
- **Date:** 2026-06-27
- **Decision:** Use checksum-verified manifest recovery with automatic repair suggestions
- **Rationale:** Checksums detect corruption; auto-repair restores usable state without manual intervention
- **Alternatives Considered:**
  - Manual recovery only — too slow for production

## Decision 3: Diagnostics as Structured Logs
- **Date:** 2026-06-27
- **Decision:** All cleanup and repair actions logged with structured context (action, shard, duration)
- **Rationale:** Enables automated monitoring and post-mortem analysis
