# Offline Mode

## Detection
- `navigator.onLine === false`
- Любой fetch error (network timeout)
- Sync endpoint недоступен

## Behavior
1. Показываем OfflineBanner: "📴 You are offline. Changes will sync when connection is restored."
2. SyncIndicator → серый
3. Все изменения сохраняются в localStorage queue
4. UI обновляется optimistically
5. Каждые 5 секунд проверяем connection

## Offline Queue
```typescript
interface OfflineQueue {
  actions: SyncAction[];
  timestamp: number;
}

// localStorage key: 'offline_queue'
// Максимум: 100 actions (при превышении → warning)
```

## Sync on Reconnect
```
1. Network restored
2. POST /api/sync/push с offline queue
3. GET /api/sync?since=lastSyncTimestamp (pull changes)
4. Обработка конфликтов:
   - 409 → ConflictResolver для каждого
   - 200 → merge успешно
5. Очистка queue
6. SyncIndicator → synced
```

## Rollback Strategy
- Если sync failed после 3 retries:
  - Оставляем queue
  - SyncIndicator → error
  - User может retry вручную
  - Offer "discard changes" button

## Conflict on Reconnect
Если offline изменения конфликтуют с серверными:
1. Получаем серверную версию
2. Показываем ConflictResolver
3. User выбирает: use local, use server, or merge
4. Результат → POST /merge
