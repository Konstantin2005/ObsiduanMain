# Architecture: Graph Performance Governor and Workload Scheduler

## Module Structure
```
src/
  governor/
    monitor/
      cpu.ts            — CPU usage tracking
      memory.ts         — Memory usage tracking
      throughput.ts     — Operations-per-second counter
      baseline.ts       — Baseline performance profile
    control/
      thresholds.ts     — Adaptive threshold engine
      throttle.ts       — Throttle controller
      backpressure.ts   — Backpressure signal sender
    scheduler/
      priority-queue.ts — Priority-based work queue
      scheduler.ts      — Main scheduling loop
      load-shedder.ts   — Load shedding logic
```

## API Design
```typescript
interface ResourceUsage {
  cpuPercent: number;
  memoryMB: number;
  throughput: number; // ops/sec
}

interface GovernorConfig {
  maxCPUPercent: number;
  maxMemoryMB: number;
  adaptive: boolean;
  backgroundQuota: number; // fraction of resources for background
}

interface WorkItem {
  id: string;
  priority: 'high' | 'medium' | 'low';
  type: 'interactive' | 'background';
  execute: () => Promise<void>;
  onBackpressure?: () => void;
}
```
