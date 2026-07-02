# Event Model

## CRDT Operations
```
BLOCK_INSERT → OR-Set add
BLOCK_UPDATE → LWW-Register merge
BLOCK_DELETE → OR-Set remove (tombstone)
BLOCK_MOVE → Fractional index reassign
```

## Event Structure
```json
{
  "id": "evt-001",
  "type": "BLOCK_UPDATE",
  "workspaceId": "ws-1",
  "blockId": "blk-42",
  "data": { "content": "Hello" },
  "hlc": "2026-06-26T13:00:00Z-42",
  "userId": "user-a"
}
```

## Event Queue
- Per-workspace in-memory queue
- Events are commutative (CRDT property)
- Batch push: up to 50 events
- Idempotent: same event ID → ignored

## HLC Generation
```
HLC = physicalTimestamp + logicalCounter
При каждом событии: max(physical, lastPhysical) + 1
При получении: max(received, local) + 1
```

## Sync Protocol
```
Client → POST /events [event1, event2, ...]
Server → applies each event
Server → returns { appliedCount, newHlc, conflicts[] }
```
