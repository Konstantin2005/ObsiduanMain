# Architecture: Worker-Based Planning for Graph Queries and Layout

## Component Diagram
```
+------------------+       +------------------+
|  Main Thread     |       |  Worker Pool     |
|  - UI Render     |       |  - Task Queue    |
|  - Orchestration |       |  - Workers[1..N] |
|  - Result Merge  |<----->|  - Scheduler     |
+------------------+       +------------------+
         |                         |
         |                         v
         |               +------------------+
         |               |  Planner Worker  |
         |               |  - Query Plan    |
         |               |  - Cache         |
         |               +------------------+
         |                         |
         |                         v
         |               +------------------+
         |               |  Layout Worker   |
         |               |  - Graph Layout  |
         |               |  - Incremental   |
         +------+--------+------------------+
                |
         +------v-------+
         | Result Merger |
         | - Determinism |
         | - Ordering    |
         +---------------+
```

## API Contract
```rust
pub struct WorkerPool { size: usize, queue: TaskQueue }
pub struct CancellationToken { cancelled: AtomicBool }

pub trait WorkerTask {
    type Input;
    type Output: Deterministic;
    fn execute(input: Self::Input, cancel: &CancellationToken) -> Result<Self::Output>;
}

pub enum WorkerMessage<T: Deterministic> {
    Result(T),
    Cancelled,
    Error(WorkerError),
}
```
