# Architecture: Progressive People Links Loading

## System Overview
```
[Graph Load] → [Node Renderer (immediate)]
                    ↓
            [EdgeLoader] → [Batch 1: strongest edges] → [Edge Renderer]
                    ↓
            [Batch N: weaker edges] → [Edge Renderer (async)]
                    ↓
            [ProgressiveState] → [UI: LoadingBar / EdgeCounter]
```

## Components

### 1. EdgeLoader
- Manages progressive loading of edges
- Breaks full edge set into batches ordered by priority
- Batches loaded via requestAnimationFrame (1 batch per frame max)
- Supports priority boosting for visible/selected nodes

### 2. ProgressiveState
```typescript
interface ProgressiveState {
  totalNodes: number;
  totalEdges: number;
  loadedEdges: number;
  loadedNodes: number;
  isLoading: boolean;
  currentBatch: number;
  totalBatches: number;
  visibleEdges: Map<string, Edge[]>;
}
```

### 3. PrioritySorter
- Orders edges by priority score: `weight * visibilityBonus + interactionBonus`
- visibilityBonus = 2x if edge connects two visible nodes
- interactionBonus = 10x if edge connects to hovered/selected node
- Sorted descending; top edges loaded first

### 4. LoadingIndicator
- Shows progress: "Loading connections... 245/1200 edges (20%)"
- Adaptive: hides when loaded >90% of edges
- Stylized as thin progress bar in graph corner

### 5. EdgePrioritizer
- Determines which edges to load next based on:
  - Edge weight (co-occurrence frequency) — higher first
  - Viewport visibility — edges near visible area
  - User interaction — hovered/selected node's edges

## Data Flow
```
1. GraphStore provides all nodes + total edge count
2. Nodes rendered immediately (no wait for edges)
3. EdgeLoader starts with batch 1 (top 100 edges by weight)
4. Each batch: 
   a. Read edges from source (cache/computed)
   b. Add to visible edge set
   c. Trigger re-render of affected areas
   d. Update ProgressiveState
   e. Schedule next batch via rAF
5. User zooms/pans/hovers → EdgePrioritizer boosts certain edges
6. Continue until all edges loaded or user navigates away
```

## Batch Configuration
| Density | Threshold | Batch Size | Priority |
|---------|-----------|------------|----------|
| Sparse | <100 people | All at once | N/A |
| Moderate | 100-500 | 200 edges | Weight-based |
| Dense | 500-2000 | 100 edges | Weight + visibility |
| Very Dense | >2000 | 50 edges | Weight + visibility + interaction |
