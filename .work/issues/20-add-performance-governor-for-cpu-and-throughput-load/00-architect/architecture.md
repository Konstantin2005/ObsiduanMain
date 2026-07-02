# Architecture: Performance Governor

## Component Diagram
```
+-------------------+     +-------------------+     +-------------------+
|  Pressure Sources |     |  Governor         |     |  Runtime Actions  |
|  - CPU Monitor    |---->|  - Policy Engine  |---->|  - Throttle       |
|  - Throughput Ops |     |  - State Machine  |     |  - Queue Backoff  |
|  - Queue Depth    |     |  - Fallback Logic |     |  - Error Shed     |
+-------------------+     +-------------------+     +-------------------+
         |                        |                          |
         v                        v                          v
+---------------------------------------------------------------+
|                     Telemetry / Logging                        |
+---------------------------------------------------------------+
```

## State Machine
```
NORMAL ──(threshold breach)──> WARNING ──(escalation)──> CRITICAL
  ^                               |                          |
  └──(recovery)───────────────────┘                          |
  └────────────────────────(fallback)────────────────────────┘
```

## API Contract
```rust
pub enum PressureLevel { Normal, Warning, Critical }
pub struct PressureSignal { cpu: f64, throughput: f64, queue_depth: usize }
pub enum ThrottleAction { Normal, Reduce(f64), Block, Fallback }

pub trait Governor {
    fn evaluate(&self, signal: &PressureSignal) -> ThrottleAction;
    fn state(&self) -> GovernorState;
}
```
