# Architecture: Cache Graph Layout

## System Overview
```
[Graph Change] → [LayoutCacheManager] → [Cache Store (IndexedDB)]
                      ↓                          ↑
              [CacheKeyGenerator]         [LayoutSerializer]
                      ↓                          ↑
              [IncrementalUpdater] ←── [Layout Engine (fallback)]
```

## Components

### 1. CacheKeyGenerator
- Computes composite hash from graph structure + algorithm config + viewport
- Uses incremental hashing to avoid full re-hash on small changes
- Output: `CacheKey { graphHash, configHash, viewportHash, version }`

### 2. LayoutCacheManager
- Orchestrates cache read/write/eviction
- On graph load: check cache → hit → deserialize positions → render
- On cache miss: run layout engine → cache result → render
- On graph change: check if incremental update sufficient → update cache
- LRU eviction when cache exceeds budget

### 3. CacheStore
- Backend: IndexedDB (primary) + in-memory LRU (hot cache)
- Schema:
  ```
  layout_cache:
    key: string (composite hash)
    value: ArrayBuffer (serialized positions)
    size: number (bytes)
    lastAccess: timestamp
    version: number
  ```
- Batch reads for warm-up
- Lazy writes (debounced, coalesced)

### 4. LayoutSerializer
- Serializes Map<nodeId, {x,y}> to Float32Array
- Format: [nodeId_count, id_1, x_1, y_1, id_2, x_2, y_2, ...]
- Compresses with delta-encoding for adjacent nodes
- Target: ~24 bytes per node (8 bytes id + 2x float32 for position)

### 5. IncrementalUpdater
- When graph changes by <10% of nodes:
  - New nodes → place at centroid of neighbors
  - Removed nodes → delete from cache
  - Modified nodes → keep position, update metadata
- Full re-layout when >10% changed

## Cache Key Calculation
```typescript
interface CacheKey {
  graphHash: string;    // SHA-256 of sorted node IDs + edge pairs
  configHash: string;   // SHA-256 of layout params (gravity, repulsion, etc.)
  viewportHash: string; // `${width}x${height}` (viewport agnostic if disabled)
  version: number;      // schema version for migration
}
```

## Storage Budget
| Graph Size | Positions Size | Cache Budget | Max Entries |
|-----------|--------------|-------------|-------------|
| 20K nodes | ~480KB       | 100MB       | ~200        |
| 50K nodes | ~1.2MB       | 100MB       | ~80         |
