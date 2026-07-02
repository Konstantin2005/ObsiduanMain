# Plan: Worker Pool for Calculations (Issue #11)

## Objective
Offload query calculation, graph layout, and link computation from main thread to a worker pool.

## Key Requirements
1. Move layout calculations to workers
2. Move query processing to workers
3. Move link/edge computations to workers
4. Synchronize state between workers and UI
5. Implement backpressure and concurrency limits

## Implementation Steps

### Phase 1: Worker Pool Infrastructure
- Create `WorkerPool` manager with configurable size (default: CPU cores - 1)
- Implement task queue with priority levels
- Design work item model (task type, payload, priority, cancel token)

### Phase 2: Migration — Layout Calculation
- Extract layout algorithm (force-directed, etc.) into worker-executable module
- Serialize graph data for transfer to worker
- Worker runs layout, returns node positions
- Main thread applies positions to visual graph

### Phase 3: Migration — Query Processing
- Move graph query execution (filter, search, traversal) to workers
- Workers receive query + graph snapshot, return results
- Results are partial: worker sends back minimal data for UI update

### Phase 4: Migration — Link Computation
- Move edge/link computation (people links, backlinks, etc.) to workers
- Workers process link generation in parallel batches

### Phase 5: Coordination & Backpressure
- Implement task prioritization (UI interactions > background refresh > precomputation)
- Add backpressure: queue limits, worker饱和, task shedding
- State synchronization protocol between workers and main thread

## Success Criteria
- Main thread remains responsive (<16ms frame budget) during heavy computation
- Layout calculation completes in <3s for 20K nodes via worker pool
- Query execution: <100ms for common filter operations
