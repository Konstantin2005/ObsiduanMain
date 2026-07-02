# Architecture: Distributed Task Management System

## Выбранное решение: Version Vector + Merge (Альтернатива B)

### 3 альтернативы
| Альтернатива | Pros | Cons | Решение |
|---|---|---|---|
| A: Event Sourcing + CQRS | Полная история, сильная консистентность | Избыточно для mock | ❌ |
| B: Version Vector + Merge | Детектирование конфликтов, ручной merge, CRDT-подобный | Сложный merge UI | ✅ |
| C: Simple Lock + Timestamp | Простота, понятный UX | Не масштабируется | ❌ |

### Data Flow
```
Frontend (Dashboard)
  → Optimistic UI update
  → PUT /api/tasks/{id} (with version)
  → Backend (Conflict Engine)
    → Version match → 200, обновление
    → Version mismatch → 409, conflict info
    → User resolve → POST /merge
  → Sync (GET /api/sync?since=timestamp)
```

### Conflict Resolution Strategy
1. Version vector: { userId: version } per task
2. PUT с version < current → 409 conflict
3. User получает обе версии → выбирает
4. POST /merge → resolved version
5. History сохраняет все версии

### Sync Strategy
- Polling-based (каждые 3 секунды)
- Offline queue (localStorage)
- Push on reconnect
- Optimistic UI + rollback
