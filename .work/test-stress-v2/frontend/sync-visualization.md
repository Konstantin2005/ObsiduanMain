# Sync Visualization

## SyncIndicator Component
```typescript
interface SyncState {
  status: 'synced' | 'syncing' | 'error' | 'offline';
  pendingCount: number;
  lastSynced: Date | null;
  retryCount: number;
}
```

## Visual States
| Status | Icon | Color | Description |
|---|---|---|---|
| synced | ✅ | Green | All events confirmed |
| syncing | 🔄 | Yellow/animating | Events in flight |
| error | ❌ | Red | Retry failed, click to retry |
| offline | 📴 | Gray | No connection |

## Detailed View (click to expand)
```
Sync Status
├── Online: ✅
├── Last synced: 13:05:22
├── Pending: 3 events
├── Retry in: 4s (backoff)
└── Event log:
    ├── BLOCK_UPDATE blk-42 ✅ confirmed
    ├── BLOCK_INSERT blk-99 🔄 syncing
    └── BLOCK_DELETE blk-17 ⏳ pending
```

## OfflineBanner
When offline for > 5 seconds:
```
📴 You are offline
   3 changes pending
   [Try again]
```

## Reconnection
```
1. Network restored → detect via navigator.onLine
2. Flush pending events (batch of 20)
3. Pull latest events (GET /sync)
4. Merge into local CRDT state
5. Update SyncIndicator → synced
```
