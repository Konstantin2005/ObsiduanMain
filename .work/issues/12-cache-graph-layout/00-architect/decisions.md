# Architectural Decisions: Cache Graph Layout

## ADR-1: IndexedDB as primary cache store
**Status**: Accepted
**Context**: Layout snapshots can be ~1.2MB for 50K nodes. Need persistent storage with random access.
**Decision**: Use IndexedDB with in-memory LRU hot cache for frequently accessed layouts.
**Consequence**: Persistent across sessions; async I/O overhead mitigated by hot cache.

## ADR-2: Float32Array serialization for compact storage
**Status**: Accepted
**Context**: Map<string, {x:number, y:number}> in JSON is ~100 bytes/node. For 50K nodes that's 5MB.
**Decision**: Serialize as binary Float32Array with packed nodeId+xy format.
**Consequence**: ~1.2MB for 50K nodes (24 bytes/node); requires binary deserialization.

## ADR-3: Composite cache key (graph + config + viewport)
**Status**: Accepted
**Context**: Layout depends on graph structure, algorithm params, and optionally viewport size.
**Decision**: Three-part hash key. Viewport part is optional (disabled for stable layouts).
**Consequence**: Precise cache matching; slightly more complex key management.

## ADR-4: Incremental cache updates for <10% graph change
**Status**: Accepted
**Context**: Full re-computation is wasteful when only a few nodes change.
**Decision**: For changes affecting <10% of nodes, update cache positions incrementally.
**Consequence**: Faster updates for small changes; complexity in position interpolation.

## ADR-5: LRU eviction with 100MB budget
**Status**: Accepted
**Context**: Unlimited cache growth would consume excessive disk space.
**Decision**: LRU eviction when total cache size exceeds 100MB.
**Consequence**: Predictable storage usage; frequently used layouts remain cached.
