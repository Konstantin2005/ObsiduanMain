# Shared Architecture: Cache Graph Layout

## Overview
Persist computed graph layouts to avoid re-computation on repeated opens.

## Key Components
- **CacheKeyGenerator**: Composite hash (graph + config + viewport)
- **LayoutCacheManager**: Orchestrates cache R/W/eviction
- **CacheStore**: IndexedDB + in-memory LRU hot cache
- **LayoutSerializer**: Binary Float32Array serialization
- **IncrementalUpdater**: Partial cache updates for small graph changes

## Storage
- Format: Float32Array packed (id, x, y per node)
- 24 bytes/node → ~1.2MB for 50K nodes
- LRU eviction at 100MB budget

## Cache Keys
Composite: `{graphHash}:{configHash}:{viewportHash}`

## Key Interfaces
See `00-architect/architecture.md` for detailed interfaces.
