# Sync Strategy

## Pull Sync
```
GET /api/workspaces/{id}/sync?since=hlc_value
Response: { events: [], newHlc: "..." }
```

## Push Sync
```
POST /api/workspaces/{id}/events
Body: { events: [CRDTOp, ...] }
Response: { applied: 5, newHlc: "...", conflicts: [] }
```

## Offline Queue
```
localStorage key: 'offline_events_<workspaceId>'
Max: 200 events
Flush on reconnect: batch of 20
Retry: exponential backoff (1s, 2s, 4s, max 30s)
```

## Conflict Resolution
CRDT handles all conflicts mathematically:
- LWW for content
- OR-Set for block membership
- Fractional index for position

## Consistency Model
Eventual consistency (CRDT guarantee)
- Все клиенты сойдутся к одинаковому состоянию
- Временные расхождения возможны до sync
- No rollback needed (CRDT)
