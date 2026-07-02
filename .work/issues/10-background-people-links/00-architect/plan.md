# Plan: Background People Links Generation (Issue #10)

## Objective
Move expensive people-link generation out of the foreground path into a background worker with caching.

## Key Requirements
1. Generate people links (aliases, mentions, co-occurrence) asynchronously
2. Cache generated links for reuse
3. Avoid race conditions between generation and live edits
4. Handle cache invalidation on vault changes

## Implementation Steps

### Phase 1: Background Worker Infrastructure
- Create `PeopleLinkWorker` that runs in a dedicated thread/Web Worker
- Design `LinkGenerationTask` data structure
- Implement work queue with priority (foreground edits > background generation)

### Phase 2: Link Generation Engine
- Extract people mention patterns from notes
- Resolve aliases to canonical person IDs
- Generate weighted edges between people based on co-occurrence
- Produce `PeopleLinkGraph` structure

### Phase 3: Cache Layer
- Design cache key from vault manifest hash + people config version
- Store serialized `PeopleLinkGraph` in cache store
- Implement invalidation on note changes affecting people edges
- Add TTL-based re-generation for staleness control

### Phase 4: Foreground Integration
- Foreground reads from cache; if miss, returns empty graph + triggers generation
- Subscribe to generation completion events for cache update
- Add loading/partial states in UI

## Success Criteria
- Foreground graph load does NOT include link generation time
- Links appear within <2s of vault load (generated in background)
- Cache hit rate >90% for repeated opens
