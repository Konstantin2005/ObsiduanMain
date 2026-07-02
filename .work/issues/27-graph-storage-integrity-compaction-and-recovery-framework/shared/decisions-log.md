# Decisions Log

## ADR-1: WAL + atomic rename over journaling
- **Decision:** WAL + atomic file rename
- **Rationale:** Simpler than full journal; atomic on ext4/NTFS
- **Date:** 2026-06-27

## ADR-2: Tombstone-based deletion
- **Decision:** Mark deleted, purge on compaction
- **Rationale:** Simple recovery; no fragmentation
- **Date:** 2026-06-27

## ADR-3: Idle-triggered compaction
- **Decision:** Run during low activity on thresholds
- **Rationale:** Avoid impact during interactive use
- **Date:** 2026-06-27

## ADR-4: Checksum-verified recovery
- **Decision:** Every entry carries checksum
- **Rationale:** Detect silent corruption
- **Date:** 2026-06-27
