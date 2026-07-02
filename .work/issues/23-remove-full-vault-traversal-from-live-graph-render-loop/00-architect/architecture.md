# Architecture: Live Graph Render Loop Optimization

## Component Diagram
```
   BEFORE:
   Vault ──(full traversal in-frame)──> Renderer ──> Frame
   
   AFTER:
   Vault ──> Precompute ──> Snapshot ──> Renderer ──> Frame
                ^               ^           ^
                |               |           |
          Vault Change     Immutable     Snapshot
          Events           Snapshots     Consumer
```

## Data Flow
```
Vault ──> Precompute (async/off-thread)
             │
             v
      Prepared Graph IR
             │
             v
      Snapshot Manager (immutable)
             │
             v
      Renderer (reads snapshot only)
             │
             v
      Frame Buffer
```

## API Contract
```rust
pub struct Snapshot { version: u64, nodes: Vec<Node>, edges: Vec<Edge>, timestamp: Instant }
pub trait Precompute { fn run(&self, vault: &Vault) -> Result<GraphIR>; }
pub trait SnapshotManager {
    fn get_latest(&self) -> Option<Snapshot>;
    fn publish(&self, ir: GraphIR) -> Result<u64>;
}

pub trait Renderer {
    fn render(&self, snapshot: &Snapshot) -> Frame;
}
```
