# Plan: Progressive Loading of People Links in Dense Graphs (Issue #13)

## Objective
Transition from eager loading to progressive loading of people links in dense graphs (many people nodes with many connections).

## Key Requirements
1. Load people links incrementally instead of all at once
2. Define thresholds/paging for progressive edge loading
3. Show loading indicators for partial state
4. Maintain stable rendering order during progressive loading
5. Support navigation/search with partial data

## Implementation Steps

### Phase 1: Progressive Loading Strategy
- Define density thresholds: sparse (<100 people), moderate (100-500), dense (>500)
- Implement paging policy: load N edges per batch
- Prioritize edges by weight (strongest connections first)

### Phase 2: Incremental Rendering
- Render nodes immediately (they're cheap)
- Add edges in batches as they load
- Maintain stable node positions; new edges should not cause layout shifts
- Show edge loading progress in UI

### Phase 3: Loading State Management
- Add `PartialGraphState` with `{ nodesLoaded, edgesLoaded, totalEdges, isLoading }`
- Show loading indicators (spinner, progress bar, edge count)
- Prevent interaction with incomplete edge data (disable "show all connections" until loaded)

### Phase 4: Navigation & Search with Partial Data
- Search operates on loaded data + prioritizes loading of relevant edges
- Zooming in triggers higher priority loading for visible region
- Node hover/click triggers immediate loading of that node's connections

### Phase 5: Threshold Configuration
- Configurable batch size (default: 100 edges per batch)
- Configurable max edges before progressive loading kicks in (default: 500)
- Priority function for edge ordering (weight-based, recency-based)

## Success Criteria
- Initial render with all nodes <500ms even for 2000+ person graph
- Edges appear progressively; user sees first edges within 200ms of initial render
- Full graph loaded within 5s for dense graphs
- No jank during progressive loading (<16ms per frame)
