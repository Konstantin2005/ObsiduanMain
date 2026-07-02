# Key Decisions: Graph Storage Integrity, Compaction and Recovery Framework

## ADR-1: WAL + atomic rename over journaling
- **Decision:** Use write-ahead log with atomic file rename for commits
- **Rationale:** Simpler than full journal; atomic rename guarantees consistency on ext4/NTFS
- **Trade-off:** Only atomic at single-file level; cross-shard operations need coordination

## ADR-2: Tombstone-based deletion over in-place removal
- **Decision:** Mark deleted, purge during compaction
- **Rationale:** Simpler recovery; avoids fragmentation from random deletes
- **Trade-off:** Temporary space amplification until compaction runs

## ADR-3: Idle-triggered compaction with size/tombstone thresholds
- **Decision:** Run compaction during low activity, triggered by thresholds
- **Rationale:** Avoids performance impact during interactive use; still guarantees bounded growth
- **Trade-off:** Under sustained write load, compaction may never get a window

## ADR-4: Checksum-verified recovery
- **Decision:** Every entry in WAL and shard carries a checksum
- **Rationale:** Detects silent corruption from bit rot or partial writes
- **Trade-off:** ~4% storage overhead for checksums
