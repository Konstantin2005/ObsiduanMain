# API Reference

## Endpoints

### GET /api/tasks
Список всех задач
```json
[{ "id": "task-1", "title": "...", "status": "active", "version": 3 }]
```

### POST /api/tasks
Создать задачу
```json
// Request
{ "title": "New Task", "description": "..." }
// Response 201
{ "id": "task-1", "title": "...", "version": 1 }
```

### PUT /api/tasks/{id}
Обновить задачу (с проверкой версии)
```json
// Request
{ "title": "Updated", "version": 2 }
// Success 200
{ "id": "task-1", "title": "Updated", "version": 3 }
// Conflict 409
{ "conflict": true, "current": { "title": "...", "version": 3 }, "yours": { "title": "...", "version": 2 } }
```

### POST /api/tasks/{id}/merge
Разрешить конфликт
```json
// Request
{ "resolved": { "title": "Merged Title" }, "versions": { "user1": 3, "user2": 2 } }
// Response 200
{ "id": "task-1", "title": "Merged Title", "version": 4 }
```

### GET /api/sync?since=<timestamp>
Получить изменения с timestamp
```json
{ "changes": [{ "type": "update", "task": {...} }], "timestamp": 1719388800 }
```

### POST /api/sync/push
Отправить offline изменения
```json
// Request
{ "actions": [{ "type": "update", "taskId": "task-1", "data": {...}, "timestamp": 1719388700 }] }
// Response
{ "applied": 3, "conflicts": [{ "taskId": "task-1", "info": {...} }] }
```
