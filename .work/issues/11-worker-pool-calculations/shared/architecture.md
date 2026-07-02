# Shared Architecture: Worker Pool Calculations

## Overview
Offload layout, query, and link computations to a managed worker pool.

## Key Components
- **WorkerPool**: Manages N workers (CPU cores - 1)
- **TaskQueue**: Priority queue with 50-task limit
- **TaskScheduler**: Assigns tasks to idle workers with preemption
- **WorkExecutor**: Runs in each worker (layout/query/link)
- **StateSynchronizer**: Versioned graph snapshots for consistency

## Task Priorities
- Critical (0): UI interactions
- High (1): Query execution
- Normal (2): Layout calculation
- Low (3): Precomputation / background refresh

## Backpressure
- Queue max 50 → reject with BackpressureError
- Low priority tasks older than 30s → dropped
- Critical tasks preempt running Normal/Low tasks

## Key Interfaces
See `00-architect/architecture.md` for detailed interfaces.
