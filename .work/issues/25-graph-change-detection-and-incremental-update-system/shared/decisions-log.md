# Decisions Log

## ADR-1: Hash-based change detection over timestamp-based
- **Decision:** SHA-256 content hashing
- **Rationale:** mtime unreliability; hash guarantees correctness
- **Date:** 2026-06-27

## ADR-2: Debounced watcher with CoW batch
- **Decision:** 300ms debounce; atomic batch
- **Rationale:** Prevent thrashing; ensure consistency
- **Date:** 2026-06-27

## ADR-3: Subgraph layout preservation
- **Decision:** Only re-layout connected nodes
- **Rationale:** Preserve user's mental map; cheaper
- **Date:** 2026-06-27

## ADR-4: Full rebuild fallback
- **Decision:** Keep full rebuild code path
- **Rationale:** Recovery path for corrupted incremental state
- **Date:** 2026-06-27
