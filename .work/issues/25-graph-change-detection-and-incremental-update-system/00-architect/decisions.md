# Key Decisions: Graph Change Detection and Incremental Update System

## ADR-1: Hash-based change detection over timestamp-based
- **Decision:** Use SHA-256 content hashing instead of mtime
- **Rationale:** mtime can be unreliable (git checkout restores old mtime); hash guarantees correctness
- **Trade-off:** Slightly higher CPU cost on initial scan

## ADR-2: Debounced watcher with CoW batch
- **Decision:** 300ms debounce window, collect changes into atomic batch
- **Rationale:** Prevents thrashing during bulk operations; atomic batches ensure consistency
- **Trade-off:** 300ms latency on rapid changes

## ADR-3: Subgraph layout preservation
- **Decision:** Only re-layout nodes connected to changed files
- **Rationale:** Preserves user's mental map; dramatically cheaper than full layout
- **Trade-off:** May produce slightly suboptimal global layout over time

## ADR-4: Full rebuild fallback
- **Decision:** Keep full rebuild code path as fallback
- **Rationale:** If incremental state gets corrupted, we need a recovery path
- **Trade-off:** Code maintenance burden for two paths
