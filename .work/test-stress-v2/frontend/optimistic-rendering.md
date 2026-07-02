# Optimistic Rendering Logic

## Core Principle
User sees their action result BEFORE server confirms.

## Flow
```
1. User types "Hello" in block
2. Local CRDT state: { content: "Hello" } IMMEDIATELY
3. UI re-renders with "Hello"
4. Event queued: { type: BLOCK_UPDATE, blockId, content: "Hello", hlc: local }
5. Push to server (async)
6. On success: update local HLC watermark
7. On error: revert to previous state
```

## Rollback
```
const previousState = deepClone(blocks);
applyOptimistic(event);
try {
  await pushEvent(event);
} catch (e) {
  blocks = previousState;  // revert
  showError("Sync failed, changes reverted");
  retryWithBackoff(event);
}
```

## Sync Status per Event
```
pendingEvents: Map<eventId, { event, status: 'pending' | 'syncing' | 'confirmed' | 'failed' }>
```

## Edge Cases
- Multiple rapid edits: debounce 300ms before push
- Edit while offline: queue, render optimistic, sync later
- Conflict on sync: CRDT merge (no user action needed)
