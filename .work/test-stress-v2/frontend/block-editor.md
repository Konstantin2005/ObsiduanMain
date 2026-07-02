# Block-Based Editor

## Component Tree
```
App
 └── AuthGate
 └── WorkspaceView
      ├── WorkspaceHeader (name, collaborator list, sync indicator)
      ├── BlockList
      │    ├── BlockRenderer (text)
      │    ├── BlockRenderer (image)
      │    ├── BlockRenderer (checklist)
      │    └── BlockRenderer (divider)
      ├── CollaboratorCursors (overlay)
      ├── SyncVisualizer
      └── OfflineBanner
```

## Block Types
- Text: plain text with LWW-Register
- Image: URL + caption
- Checklist: array of { text, checked }
- Divider: visual separator

## Editor State
```
selectedBlock: blockId | null
editingBlock: blockId | null (inline edit mode)
dragBlock: blockId | null (drag to reorder)
collaborators: Map<userId, { name, color, cursor }>
```

## Rendering Logic
```
1. Load blocks from CRDT state
2. Sort by position (fractional index)
3. Filter deleted (tombstoned) blocks
4. Render each block with BlockRenderer
5. Apply optimistic updates immediately
6. Re-render on sync confirmation
```
