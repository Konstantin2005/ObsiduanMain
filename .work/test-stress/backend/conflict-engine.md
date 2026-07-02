# Conflict Engine

## Version Vector
Каждая задача имеет:
```json
{
  "version": 3,
  "versions": { "user-a": 2, "user-b": 3 },
  "history": [
    { "version": 1, "by": "user-a", "timestamp": "...", "data": {...} },
    { "version": 2, "by": "user-b", "timestamp": "...", "data": {...} }
  ]
}
```

## Conflict Detection
```
PUT /api/tasks/{id} с version = 2
Текущая version = 3 (user-b сделал update)
→ 409 Conflict

Response:
{
  "conflict": true,
  "current": { ... version: 3, versions: {...} },
  "yours": { ... version: 2 },
  "history": [ { version: 2, by: "user-b", data: {...} } ]
}
```

## Merge Strategy
1. User видит обе версии (current + his)
2. User выбирает: использовать current, использовать свою, или merge per field
3. POST /merge с resolved data
4. Новая version = max(current, user) + 1
5. versions обновляется: { ...versions, userId: newVersion }

## Race Condition Handling
- Два PUT одновременно:
  - Первый → success (version 2 → 3)
  - Второй → 409 conflict (всё ещё версия 2)
  - Второй получает актуальную версию → merge или retry
