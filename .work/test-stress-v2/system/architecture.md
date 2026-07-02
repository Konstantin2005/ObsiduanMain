# Architecture: Collaborative Workspace Platform

## 3 Architecture Alternatives

| Критерий | Event-Driven ❌ | CRDT-Based ✅ | Lock-Based ❌ |
|---|---|---|---|
| Conflict resolution | Last-write-wins | Mathematical guarantee | No conflicts (lock) |
| Offline support | Нет (order matters) | First-class | Невозможен |
| Scalability | Total order bottleneck | Fully distributed | Single lock bottleneck |
| Complexity | Medium | High | Low |
| UX for collab | Bad (data loss) | Perfect | Bad (waiting) |
| Audit trail | ✅ Full | ❌ Tombstone GC | ✅ Full |

## CRDT Architecture (Selected)
```
User Action → Local CRDT Op → Apply locally → Push event → Server merges → Sync to others
```

## Data Model
```
Workspace → Blocks[] → Block { id, position, content, version, hlc }
Tenant → Users[] → User { id, role }
Event → { type, blockId, data, hlc, userId }
```

## Sync Strategy
- Pull: GET /sync?since={hlc}
- Push: POST /events (batch)
- CRDT guarantees eventual consistency
- Offline queue with idempotent replay

## Permission Model
- Owner: full access + manage users
- Editor: read + write
- Viewer: read only
- Isolation: workspace-scoped queries, API validation
