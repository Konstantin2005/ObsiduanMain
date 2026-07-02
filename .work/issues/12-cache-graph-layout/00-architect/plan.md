# Plan: Cache Graph Layout for 20K-50K Nodes (Issue #12)

## Objective
Cache computed graph layouts to avoid expensive re-computation on repeated opens.

## Key Requirements
1. Design cache key strategy that accurately reflects graph state
2. Store layout snapshots (node positions) persistently
3. Handle graph changes without full re-computation
4. Manage cache size for large graphs (20K-50K nodes)

## Implementation Steps

### Phase 1: Cache Key Strategy
- Design composite key: `layout:{graphHash}:{configHash}:{viewportHash}`
- graphHash = hash of node IDs + edge structure
- configHash = hash of layout algorithm parameters
- viewportHash = viewport dimensions (for adaptive layouts)

### Phase 2: Layout Snapshot Storage
- Serialize node positions as Float32Array for compact storage
- Store in IndexedDB / local file cache
- Implement LRU eviction for cache size management
- Target: <100MB cache budget

### Phase 3: Incremental Cache Updates
- When graph changes minimally, update cached layout incrementally
- Use simulated annealing: new nodes get interpolated positions
- Removed nodes are simply dropped from cache
- Full re-layout only when change exceeds threshold

### Phase 4: Cache Warm-up & Prefetch
- On vault load, check cache before computing layout
- Prefetch/batch cache writes to avoid disk thrashing
- Async cache loading with fallback to computation

## Success Criteria
- Cache hit → layout ready in <200ms (vs 2-5s computation)
- Cache miss → layout computed and stored for next time
- Cache size <100MB for 50K node layouts
- Cache invalidation correctly triggers re-layout on graph changes
