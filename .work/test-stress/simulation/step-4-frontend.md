# Step 4: Frontend

## Действия
1. Создан TaskDashboard (список задач + sync status)
2. Создан TaskEditor (редактирование с version info)
3. Создан ConflictResolver (диалог выбора версии)
4. Создан SyncIndicator (synced/syncing/error/offline)
5. Создан OfflineBanner

## UI State Model
- tasks: Map<id, Task>
- syncStatus: synced | syncing | error | offline
- offlineQueue: SyncAction[]
- conflicts: Map<id, ConflictInfo>

## Key Features
- Optimistic UI update (мгновенное обновление + rollback)
- Offline queue (localStorage, max 100)
- Auto-sync on reconnect (3 retries)
- Conflict dialog на 409

## Результат
Frontend готов. Offline mode и optimistic UI реализованы.
