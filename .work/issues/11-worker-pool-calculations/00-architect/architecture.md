# Architecture: Worker Pool Calculations

## System Overview
```
[Main Thread]                     [Worker Pool]
     │                                  │
     │── enqueueTask(task) ──────────▶  │── Worker-1 (layout)
     │                                  │── Worker-2 (queries)
     │                                  │── Worker-3 (links)
     │◀──── result callback ────────────│── Worker-N (available)
     │
     ▼
[TaskQueue] ───▶ [Backpressure] ───▶ [TaskScheduler]
```

## Components

### 1. WorkerPool
- Manages pool of Web Workers / worker threads
- Tracks busy/idle workers
- Handles worker lifecycle (spawn, terminate, restart on crash)
- Size: `navigator.hardwareConcurrency - 1` (leave 1 for UI)

### 2. TaskQueue
```typescript
enum TaskPriority { Critical = 0, High = 1, Normal = 2, Low = 3 }

interface WorkTask {
  id: string;
  type: 'layout' | 'query' | 'link' | 'precompute';
  payload: any;
  priority: TaskPriority;
  cancelToken?: AbortSignal;
  timestamp: number;
}
```
- Priority queue (sorted by priority, then FIFO within priority)
- Max queue size: 50 pending tasks (beyond that → reject with backpressure)

### 3. TaskScheduler
- Assigns tasks to idle workers
- Respects priority: higher priority tasks preempt lower (if worker supports cancellation)
- Implements work stealing: idle worker steals from busiest worker's queue

### 4. WorkExecutor (runs inside each worker)
- Receives task payload via structured clone
- Executes computation (layout/query/link)
- Returns result via postMessage
- Supports cancellation via AbortSignal

### 5. StateSynchronizer
- Manages state consistency between workers and main thread
- Graph snapshots are versioned
- Workers receive snapshot version; if stale, task is rejected/re-queued
- Main thread merges results using version stamps

## Task Types

| Task Type | Payload | Result | Priority |
|-----------|---------|--------|----------|
| layout    | Nodes + Edges + Config | Positions Map | Normal |
| query     | Query string + Filters + Snapshot | Filtered nodes | High |
| link      | Notes + People config | PeopleLinkGraph | Low |
| precompute| Graph subset + Algorithm | Partial result | Low |

## Backpressure Strategy
- **Queue limit**: 50 tasks max → reject with `BackpressureError`
- **Worker saturation**: If all workers busy, new Normal/Low tasks are queued; Critical tasks preempt
- **Task shedding**: Low priority tasks older than 30s are dropped
- **Progress feedback**: Tasks report progress % for UI feedback
