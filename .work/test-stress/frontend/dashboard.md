# Dashboard

## Компоненты

### TaskDashboard
```
┌─────────────────────────────────────────┐
│  [SyncIndicator: ✅ Synced] [Add Task]  │
├─────────────────────────────────────────┤
│  [TaskCard] [TaskCard] [TaskCard]       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ Title   │ │ Title   │ │ Title   │  │
│  │ Status  │ │ Status  │ │ ⚠️ Conf │  │
│  │ v: 3    │ │ v: 1    │ │lict!    │  │
│  └─────────┘ └─────────┘ └─────────┘  │
└─────────────────────────────────────────┘
```

### TaskCard
- Title (editable inline)
- Status badge (active/done/archived)
- Version number
- Conflict warning icon (if unresolved)
- Last edited by (user)
- Click → открывает TaskEditor

### TaskEditor
- Title field
- Description textarea
- Status selector
- Version info panel
- Save button (with optimistic update)

### SyncIndicator
- ✅ Synced — зелёный
- 🔄 Syncing — жёлтый (анимация)
- ❌ Error — красный (retry button)
- 📴 Offline — серый (OfflineBanner)
- Last synced: timestamp
