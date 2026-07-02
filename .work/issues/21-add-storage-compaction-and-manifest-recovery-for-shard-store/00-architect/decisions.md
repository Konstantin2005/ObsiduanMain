# Key Architectural Decisions

## ADR-1: Copy-on-Write Compaction
- **Context:** Compaction must be safe if process crashes
- **Decision:** Use CoW to create new compacted shards, then atomically swap
- **Consequence:** Safe failure mode, double disk space during compaction

## ADR-2: Checksum-Verified Manifest Recovery
- **Context:** Manifest corruption can make storage unusable
- **Decision:** Auto-detection via checksums, auto-repair with recovery logs
- **Consequence:** Minimizes downtime, but requires checksum storage overhead

## ADR-3: Structured Diagnostics
- **Context:** Operations must be observable
- **Decision:** All actions logged as structured events with context
- **Consequence:** Enables automated analysis and alerting
