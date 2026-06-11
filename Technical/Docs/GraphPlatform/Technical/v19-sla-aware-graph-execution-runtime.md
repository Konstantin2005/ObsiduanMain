# SLA-Aware Graph Execution Runtime v19

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

Do not make CPU saturation the goal.

CPU saturation must be a side effect of a balanced graph execution pipeline.

Correct formula:

```txt
Saturate CPU only when the pipeline can absorb the work
and the system SLA stays green.
```

Production goal:

```txt
maximize useful graph throughput
without increasing UI tail latency, GC pressure, memory pressure,
compiler backlog, stale work, or publish stalls.
```

## Why v19 Exists

v17 introduced:

```txt
UsefulGraphFactsPerSecond under UI SLA
```

The next temptation was:

```txt
keep all CPU cores busy
worker idle time ~= 0
```

That is still dangerous.

If worker idle time is forced to zero, the system can create:

```txt
compiler backlog growth
serialization growth
GC growth
IO queue growth
main-thread result bursts
snapshot publish stalls
stale work burning CPU
```

Correct rule:

```txt
Workers should not starve when downstream is healthy.
Workers may and should idle when downstream backpressure is active.
```

Idle workers are not automatically a failure.

Sometimes idle workers are the safety valve.

## Non-Negotiable Invariants

- CPU usage is not a success metric by itself.
- Worker idle below a fixed percentage is not a success metric by itself.
- Backpressure is allowed to idle workers.
- Main thread performs orchestration only.
- Compiler backlog controls upstream scheduling.
- IO prefetch must stop at downstream watermarks.
- Stale generations must be cancelled.
- Work stealing must be typed and deterministic.
- Generic cross-pool stealing is forbidden.
- First slice must avoid too many worker pools.
- Result transport evolves in stages, not all at once.
- Obsidian inactive does not mean the whole system is idle.
- System pressure matters beyond Obsidian focus state.

## Architecture

```txt
System Pressure Monitor
        |
        v
UI SLA Monitor
        |
        v
Build Intent / Deadline Planner
        |
        v
Task DAG Planner
        |
        v
Weighted Fair Scheduler
        |
        v
Typed Worker Pools
        |
        v
Backpressure Controller
        |
        v
Compiler Worker
        |
        v
Quality Gate
        |
        v
Snapshot Publisher
        |
        v
Execution Trace / Learning Policy
```

## Correct KPIs

Primary:

```txt
usefulFacts/sec under UI SLA
acceptedSnapshot/sec
costPerGraphFact
```

Safety:

```txt
eventLoopDelay p95/p99
GC pause p95
serializationMsPerMB
compilerBacklogDepth
compilerBacklogBytes
publishCriticalSectionMs
memoryPressure
diskLatency
staleWorkRatio
```

Anti-KPIs:

```txt
CPU percent alone
worker idle percent alone
queue depth alone
worker count alone
```

Correct worker-idle rule:

```txt
No starvation when downstream is healthy.
Allow idle when backpressure is active.
```

## Task DAG

Do not model graph work as simple queues.

Model it as a cancellable task DAG.

Example:

```txt
ReadFile
  -> ParseMarkdown
  -> ExtractLinks
  -> EmitFacts
  -> ResolveTargets
  -> BuildEdges
  -> ValidatePartition
  -> PublishSnapshot
```

Contract:

```txt
GraphTaskDescriptor/v19.0
```

Shape:

```json
{
  "taskId": "task-123",
  "type": "ParseMarkdown",
  "priority": 80,
  "deadlineMs": 500,
  "costEstimate": {
    "cpuMs": 4,
    "readBytes": 4096,
    "resultBytes": 512
  },
  "dependencies": ["read-file-123"],
  "generation": 42,
  "cancelToken": "gen-42",
  "resultFormat": "compact-json"
}
```

Required task fields:

```txt
taskId
type
priority
deadline
costEstimate
dependencies
generation
cancelToken
resultFormat
partitionId
```

## Backpressure Controller

Contract:

```txt
GraphBackpressureDecision/v19.0
```

Signals:

```txt
readyQueueDepth
readyChunkBytes
inFlightBytes
resultQueueBytes
compilerBacklogDepth
compilerBacklogBytes
memoryPressure
eventLoopDelay
diskLatency
serializationMsPerMB
staleWorkRatio
```

Actions:

```txt
SCHEDULE_MORE
PAUSE_IO
REDUCE_PARSE_WORKERS
GIVE_CPU_TO_COMPILER
CANCEL_STALE_WORK
DROP_SPECULATIVE_WORK
ALLOW_WORKER_IDLE
REDUCE_RESULT_PAYLOAD
```

Important rule:

```txt
IO prepares chunks only until downstream watermarks.
```

Watermarks:

```txt
readyChunkBytes
inFlightBytes
resultQueueBytes
compilerBacklogBytes
memoryPressure
```

Without watermarks, prefetch can turn into OOM.

## Weighted Fair Scheduler

Contract:

```txt
GraphWeightedSchedule/v19.0
```

Interactive example:

```txt
current view index: 40
changed files: 30
people scan: 10
layout prep: 5
validation: 15
```

Idle example:

```txt
changed files: 25
people scan: 25
resolver cache: 20
layout prep: 20
validation: 10
```

Rules:

```txt
weights are policy, not hard guarantees
backpressure can override weights
deadline tasks can preempt background tasks
stale generations cancel before new work is scheduled
```

## Deadline-Aware Scheduling

Every schedulable unit should carry:

```txt
priority
deadline
cost
dependencies
generation
```

Fast-deadline examples:

```txt
current view
open notes
snapshot repair
current diary
```

Slow-deadline examples:

```txt
archive layout
full validation
long people scan
old partitions
```

The scheduler should prefer:

```txt
small high-value work first
repair before polish
current partitions before archive
fresh generations before stale generations
```

## Typed Work Stealing

Generic work stealing is forbidden.

Allowed:

```txt
ParseHashPool can steal HashTask.
PeopleScanPool can steal TextScanTask.
ValidationQueue can steal cheap stat validation.
```

Forbidden:

```txt
LayoutPool stealing ParseTask.
CompilerWorker stealing parse/hash/layout tasks.
Parse worker stealing layout-heavy task.
Worker stealing task with incompatible result format.
Worker stealing task with incompatible deterministic stage.
```

Why:

```txt
different memory model
different result format
different priority model
different deterministic order
different cache dependencies
```

## First-Slice Pool Boundary

Do not start with many pools.

Final architecture can contain:

```txt
ParsePool
PeopleScanPool
HashPool
ResolverCompilerWorker
LayoutPrepPool
ValidationPool
```

But first slice must start smaller:

```txt
ParseHashPool
CompilerWorker
ValidationQueue
```

Reason:

```txt
every pool needs queue logic
telemetry
backpressure
failure handling
serialization format
debuggability
```

## Compiler Worker Strategy

Compiler worker is necessary, but it can become the bottleneck.

Stages:

```txt
CompilerWorker v1:
  single deterministic compiler

CompilerWorker v2:
  partitioned compiler

CompilerWorker v3:
  deterministic reduce
```

Rule:

```txt
ParseHashPool must slow down when CompilerWorker backlog grows.
```

Compiler backlog is a first-class signal, not a debug metric.

## Result Transport Evolution

Zero-copy is not first implementation.

Evolution path:

```txt
Stage 1:
  compact JSON records + measure serialization

Stage 2:
  compact binary fact records

Stage 3:
  Transferable ArrayBuffer

Stage 4:
  SharedArrayBuffer only if necessary
```

Contract:

```txt
GraphTaskResultEnvelope/v19.0
```

Required fields:

```txt
taskId
generation
partitionId
resultFormat
recordCount
byteLength
serializationMs
isTransferable
```

## System Pressure Monitor

Obsidian inactive is not enough to claim the machine is idle.

User may be running:

```txt
game
render
Zoom
browser
compiler
backup
```

Signals:

```txt
eventLoopDelay
process CPU
system load
available memory
GC pause
disk latency
worker throughput
thermal inferred from throughput drop
battery/power if available
```

Rule:

```txt
High-throughput mode requires system appears idle,
power is okay,
pressure is low,
and user policy allows it.
```

## Useful Saturation Score

Replace:

```txt
CPU %
```

With:

```txt
UsefulSaturationScore
```

Draft formula:

```txt
usefulSaturation =
  usefulFactsPerSec
  / (
    eventLoopPenalty
    * memoryPenalty
    * serializationPenalty
    * staleWorkPenalty
    * compilerBacklogPenalty
  )
```

Interpretation:

```txt
CPU can rise only if usefulSaturation rises.
If CPU rises but usefulSaturation falls, throttle.
```

## Stale Work Cancellation

Old work must stop when it cannot publish.

Mechanisms:

```txt
generation tokens
task invalidation
speculative work cancellation
stale partition cancellation
cancelled result drop
```

Rules:

```txt
new generation invalidates stale speculative tasks
compiler ignores stale result envelopes
publisher never publishes stale generation as fresh
execution trace records cancellation reasons
```

## First Slice

`V19-S1 SLA-Aware Saturation Core`

Tasks:

```txt
1. Define TaskDescriptor with type, priority, dependencies, generation, cancelToken.
2. Add UI SLA Monitor with eventLoopDelay p95/p99.
3. Add System Pressure Monitor basic signals.
4. Add BackpressureController.
5. Add ParseHashPool only, not all pools yet.
6. Add single CompilerWorker contract and backlog metric.
7. Add generation-based stale task cancellation.
8. Add compiler backlog metric.
9. Add useful saturation score.
10. Add execution trace with throttle reasons.
```

Done:

```txt
CPU rises only when useful throughput rises.
Workers pause when compiler/backpressure says stop.
Stale tasks are cancelled.
Main thread SLA remains green.
Compiler worker does not block UI.
Benchmarks show throughput vs penalties.
```

## Benchmark Plan

Benchmarks:

```txt
bench:v19-useful-saturation-score
bench:v19-compiler-backlog-backpressure
bench:v19-stale-generation-cancellation
bench:v19-typed-work-stealing
bench:v19-watermark-prefetch
bench:v19-weighted-fair-scheduling
bench:v19-deadline-preemption
```

Report schema:

```json
{
  "contract": "GraphExecutionRuntimeBenchmark/v19.0",
  "usefulFactsPerSec": 13800,
  "usefulSaturationScore": 9200,
  "compilerBacklogDepth": 12,
  "compilerBackpressure": false,
  "staleWorkCancelled": 120,
  "actions": ["SCHEDULE_MORE"],
  "eventLoopDelayP95": 11
}
```

## What To Remove From V18 S1

Remove from first slice:

```txt
many separate pools
full work stealing
zero-copy as mandatory
idle full CPU mode
WASM/native addon discussion
layout prep pool
validation pool as worker pool
PeopleScanPool in first slice
```

Raise:

```txt
Task DAG
backpressure
compiler backlog
system pressure
generation cancellation
useful saturation score
weighted scheduling
deadline scheduling
```

## Extension Points

```txt
ExtensionPoint: TaskDAG
Future:
  partitioned graph compiler, distributed build

ExtensionPoint: SchedulerPolicy
Future:
  learned scheduler, reinforcement tuning

ExtensionPoint: ResultTransport
Future:
  JSON -> compact binary -> Transferable ArrayBuffer

ExtensionPoint: CompilerWorker
Future:
  partitioned compiler + deterministic reduce

ExtensionPoint: WorkerPoolRegistry
Future:
  PeopleScanPool, LayoutPool, ValidationPool

ExtensionPoint: PressureSignals
Future:
  OS battery, thermal, Defender detection

ExtensionPoint: QualityGate
Future:
  semantic anomaly detection

ExtensionPoint: SnapshotPublisher
Future:
  partial snapshot publishing
```

## Open Bugs To Track

```txt
V19-B001: CPU saturation as a target can hide downstream bottlenecks.
V19-B002: forcing worker idle to zero can grow compiler backlog.
V19-B003: generic work stealing can violate task determinism and result formats.
V19-B004: too many pools in S1 can make the runtime untestable.
V19-B005: zero-copy as mandatory first step can stall implementation.
V19-B006: single CompilerWorker can become the new bottleneck.
V19-B007: IO prefetch without watermarks can trigger memory pressure or OOM.
V19-B008: Obsidian inactive does not mean the system is idle.
V19-B009: missing fairness can let people scan or validation starve urgent work.
V19-B010: missing deadline scheduling can delay current-view graph freshness.
V19-B011: stale tasks can keep burning CPU after a newer generation exists.
V19-B012: useful saturation score can be gamed unless penalties include stale work and backlog.
```
