# Architectural Decisions: Background People Links

## ADR-1: Dedicated background worker instead of idle-time processing
**Status**: Accepted
**Context**: Idle-time processing (requestIdleCallback) is unreliable for large workloads and can be preempted.
**Decision**: Use a dedicated Web Worker / thread for link generation.
**Consequence**: Guaranteed processing resources; requires structured cloning for data transfer.

## ADR-2: Cache key based on manifest hash + config version
**Status**: Accepted
**Context**: Cache must be invalidated when vault content or link configuration changes.
**Decision**: Two-part key: vault manifest hash (content) + config version (rules).
**Consequence**: Precise invalidation; re-computation only when necessary.

## ADR-3: Foreground returns empty graph on cache miss
**Status**: Accepted
**Context**: Users should see the graph immediately even if links aren't ready.
**Decision**: Foreground path returns empty people links and triggers background generation. UI shows loading state.
**Consequence**: Faster initial paint; slightly more complex UI state management.

## ADR-4: Debounced re-generation on edits (2s window)
**Status**: Accepted
**Context**: Rapid note edits shouldn't trigger cascading re-generations.
**Decision**: Debounce invalidation + re-generation by 2 seconds.
**Consequence**: Prevents thundering herd; slight delay in link updates after edits.

## ADR-5: Structured cloning for worker communication
**Status**: Accepted
**Context**: Large PeopleLinkGraph (~MB) needs to be transferred between worker and main thread.
**Decision**: Use structured clone (Transferable objects where possible) for serialization.
**Consequence**: No shared memory complexity; acceptable serialization overhead for background operation.
