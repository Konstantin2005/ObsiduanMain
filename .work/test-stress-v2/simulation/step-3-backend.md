# Step 3: Backend

## Реализовано
- CRDT event model (INSERT, UPDATE, DELETE, MOVE)
- Sync strategy (pull + push)
- Conflict logic (LWW, OR-Set, fractional index)
- Multi-tenant isolation (workspace-scoped, permission check)
- 8 API endpoints

## Key Features
- HLC-based event ordering
- Idempotent event processing
- Batch event push (up to 50)
- Tenant isolation with 403 on breach
- Permission levels: owner, editor, viewer

## Результат
Backend готов. CRDT event system работает.
