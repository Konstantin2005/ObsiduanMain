# Shared Architecture: DEV: Remove full vault traversal from Live Graph render loop

## System Context
Live Graph currently traverses the full vault inside the render cycle, which creates avoidable performance pressure.

## Key Components
1. Precompute Layer — prepares graph data off the render thread
2. Snapshot Manager — maintains a consistent prepared snapshot
3. Renderer — consumes snapshot data only
4. Timing Monitor — tracks frame timing improvements

## Data Flow
Vault → Precompute → Snapshot → Renderer → Frame

## Constraints
- Full vault traversal must be removed from render hot path
- Frame timing must improve or stabilize
- Output correctness must be preserved
