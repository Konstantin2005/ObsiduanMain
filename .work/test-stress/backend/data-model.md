# Data Model

## Task
```typescript
interface Task {
  id: string;
  title: string;
  description: string;
  status: 'active' | 'done' | 'archived';
  version: number;
  versions: Record<string, number>;  // userId → version
  history: VersionEntry[];
  locked: boolean;
  createdAt: string;
  updatedAt: string;
}
```

## VersionEntry
```typescript
interface VersionEntry {
  version: number;
  userId: string;
  timestamp: string;
  data: Partial<Task>;
}
```

## SyncAction (Offline Queue)
```typescript
interface SyncAction {
  type: 'create' | 'update' | 'delete';
  taskId: string;
  data: Partial<Task>;
  timestamp: string;
  clientVersion: number;
}
```

## Storage
```typescript
// In-memory storage
class TaskStore {
  private tasks: Map<string, Task> = new Map();
  private syncLog: SyncEntry[] = [];
  private userVersions: Map<string, number> = new Map();
}
```

## Constraints
- title: required, 1-200 символов
- description: optional, max 5000 символов
- status: enum('active', 'done', 'archived')
- version: auto-increment per task
- versions: auto-track per userId
