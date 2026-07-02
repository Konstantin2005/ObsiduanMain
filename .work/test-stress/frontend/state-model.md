# State Model

## Store
```typescript
interface AppState {
  tasks: Map<string, Task>;
  syncStatus: 'synced' | 'syncing' | 'error' | 'offline';
  lastSyncTimestamp: number | null;
  pendingChanges: number;  // offline queue size
  conflicts: Map<string, ConflictInfo>;
  selectedTaskId: string | null;
  networkStatus: 'online' | 'offline';
  error: string | null;
}
```

## Actions
| Action | Trigger | Effect |
|---|---|---|
| FETCH_TASKS | Mount / refresh | GET /api/tasks |
| CREATE_TASK | Add button | POST → optimistic add |
| UPDATE_TASK | Save | PUT → optimistic update |
| RESOLVE_CONFLICT | User picks version | POST /merge |
| SYNC_PULL | Every 3s | GET /api/sync |
| SYNC_PUSH | Reconnect | POST /api/sync/push |
| GO_OFFLINE | Network loss | Queue changes |
| GO_ONLINE | Network restore | Flush queue, sync |

## Optimistic Update Flow
```
User edits title
→ IMMEDIATE: store.tasks[id].title = newTitle (optimistic)
→ API: PUT /api/tasks/id { title: newTitle, version: currentVersion }
→ Success: store.tasks[id].version = response.version
→ Error 409: show ConflictResolver, offer rollback
→ Error 500: rollback to previous title, show error toast
```
