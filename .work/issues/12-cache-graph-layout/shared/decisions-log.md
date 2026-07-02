# Decisions Log: Cache Graph Layout

## ADR-1: IndexedDB as primary cache store
Persistent storage with in-memory LRU hot cache.

## ADR-2: Float32Array binary serialization
~1.2MB for 50K nodes vs ~5MB for JSON.

## ADR-3: Composite cache key
graphHash + configHash + viewportHash for precise matching.

## ADR-4: Incremental updates for <10% change
Position interpolation for new nodes; skip full re-layout.

## ADR-5: LRU eviction with 100MB budget
Predictable storage; frequent layouts stay cached.
