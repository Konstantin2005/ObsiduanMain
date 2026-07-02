# Shared Architecture: Background People Links

## Overview
Move expensive people-link generation to background worker with caching.

## Key Components
- **PeopleLinkGenerator**: Scans notes, resolves aliases, computes co-occurrence
- **PeopleLinkCache**: Persists generated links with manifest-hash key
- **BackgroundWorker**: Dedicated thread for link generation
- **ForegroundIntegration**: Returns cached/empty graph, subscribes to updates

## Data Flow
1. Vault loads → cache check → cache miss → empty graph + enqueue generation
2. BackgroundWorker runs generator → produces PeopleLinkGraph
3. Result cached → foreground notified → UI updates
4. On edit → cache invalidated → debounced re-generation (2s)

## Key Interfaces
See `00-architect/architecture.md` for detailed interfaces.
