# Step 3: Backend

## Действия
1. Реализован REST API (8 endpoints)
2. Создан Conflict Engine (version vector, detection, merge)
3. Спроектирован Data Model (Task, VersionEntry, SyncAction)
4. In-memory storage (Map<String, Task>)
5. Sync endpoints (pull + push)

## Key Features
- Version check на каждом PUT
- 409 Conflict с детальной информацией
- POST /merge для ручного разрешения
- Sync log для offline pull
- Batch push для offline queue

## Результат
Backend готов. Conflict resolution реализован логически.
