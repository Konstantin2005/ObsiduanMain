# Shared Architecture: Progressive People Links

## Overview
Load people edges progressively instead of all-at-once in dense graphs.

## Key Components
- **EdgeLoader**: Manages batched edge loading via rAF
- **ProgressiveState**: Tracks load progress
- **PrioritySorter**: Orders edges by weight + visibility + interaction
- **LoadingIndicator**: Shows progress in UI
- **EdgePrioritizer**: Dynamically prioritizes edges based on viewport/interaction

## Loading Strategy
- Nodes: render immediately
- Edges: load in batches via requestAnimationFrame
- Priority: weight-based with interaction boost
- Thresholds: progressive mode activates at >500 edges

## Data Flow
1. Render all nodes immediately
2. Load strongest edges first (batch 100/rAF)
3. User interaction boosts relevant edges to front of queue
4. Continue until all edges loaded

## Key Interfaces
See `00-architect/architecture.md` for detailed interfaces.
