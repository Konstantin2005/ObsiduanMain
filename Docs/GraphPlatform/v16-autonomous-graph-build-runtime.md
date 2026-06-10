# Autonomous Graph Build Runtime v16

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v15 learned how to use the machine safely.

It made worker pool a bounded accelerator behind deterministic `WorkPlan`, not the architecture itself.

v16 moves higher:

```txt
Do not just execute builds.
Operate the graph system.
```

Core formula:

```txt
A fast indexer measures time.
A production indexer manages resources.
An intelligent indexer learns.
```

## Why v16 Exists

v15 answers:

```txt
How do we build faster and safely with more resources?
```

v16 answers:

```txt
How does the system decide when to build,
how many resources to use,
when to stop,
whether the result is good,
and how to improve over months?
```

The current pipeline is still mostly one-shot:

```txt
input
-> WorkPlan
-> workers
-> compiler
-> snapshot
```

v16 makes the build process observable, adaptive, and historical:

```txt
BuildIntent
-> ExecutionPlan
-> ExecutionTrace
-> QualityDecision
-> BuildMemory
-> next policy recommendation
```

## Architecture

```txt
Change Detector
        |
        v
Build Scheduler
        |
        v
Cost Estimator
        |
        v
Work Planner
        |
        v
Adaptive Resource Governor
        |
        v
Worker Execution Engine
        |
        v
Streaming Collector
        |
        v
Incremental Compiler
        |
        v
Quality Gate
        |
        v
Snapshot Publisher
        |
        v
Build Memory
```

## Non-Negotiable Invariants

- Renderer never waits for build runtime.
- Renderer reads only published snapshots.
- Build runtime can delay, pause, downgrade, or reject a build.
- Every build has an `ExecutionTrace`.
- Every publish/reject decision has reasons.
- Resource choices are recorded.
- Event loop health is measured.
- Serialization overhead is measured.
- Build history influences future recommendations.
- Suspicious snapshots are not silently published.
- Partial/quality-degraded results are explicit.
- Warm trusted builds should not start worker pool.

## Layer 1 - Build Scheduler

The scheduler decides when a build should run.

Decisions:

```txt
NOW
DELAY
BACKGROUND
IDLE_ONLY
FULL_REBUILD_NIGHT
SKIP
```

Inputs:

```txt
changed file count
estimated changed bytes
user active
Obsidian focused
battery state
CPU load
memory pressure
sync storm detected
last build time
previous failure rate
```

Example:

```txt
3 changed files + user active
-> BACKGROUND with low resource policy

10K changed files + sync storm
-> DELAY or BACKGROUND_HEAVY after quiet period
```

## Layer 2 - Cost Estimator

Before build starts, estimate cost.

Output:

```json
{
  "estimatedMs": 3500,
  "estimatedReadMb": 200,
  "estimatedCpuMs": 2200,
  "estimatedWriteMb": 40,
  "recommendedMode": "BACKGROUND_NORMAL"
}
```

Inputs:

- affected files;
- affected bytes;
- previous build history;
- worker efficiency;
- disk pressure history;
- parser/resolver ratio;
- current mode.

The estimator does not need to be perfect initially. It must be explicit and measured.

## Layer 3 - Adaptive Resource Governor

Static `workers=8` is not enough.

Runtime signals:

```txt
CPU usage
event loop delay
main thread blocked ms
GC pauses
disk latency
worker utilization
queue pressure
memory pressure
serialization cost
thermal throttling
```

Actions:

```txt
increase workers
decrease workers
pause IO scheduling
change chunk size
reduce maxInFlightBytes
switch mode
abort or delay publish
```

Example:

```txt
workers 6 -> 4
chunk 8MB -> 2MB
reads 8 -> 3
```

## Layer 4 - Event Loop Protection

Worker threads can be fast while main thread dies.

Measure:

```txt
eventLoopDelay
mainThreadBlockedMs
GC pause estimate
structuredClone/serialization overhead
collector backlog
```

Danger example:

```txt
worker parse: 500ms
result serialization: 900ms
```

Then the bottleneck moved, not disappeared.

Policy:

```txt
if event loop delay exceeds threshold:
  reduce in-flight chunks
  reduce result payload size
  switch to compact records
  pause worker scheduling
```

## Layer 5 - Zero-Copy Evolution Path

Do not implement shared memory first, but keep the contract ready.

Stages:

```txt
Stage 1: JSON messages
Stage 2: compact records
Stage 3: Transferable ArrayBuffer
Stage 4: shared memory arena
```

Worker output contract should allow evolution:

```txt
payloadFormat:
  json
  compact
  transferable
  shared-arena
```

## Layer 6 - Streaming Compiler

Avoid pure batch:

```txt
workers finish
-> collect all
-> resolve all
-> arrays
-> write
```

Move toward pipeline:

```txt
worker parses chunk 1
-> collector consumes
-> resolver prepares partition
-> writer stages

while worker parses chunk 2
```

Initial stage can still materialize full arrays, but the architecture must expose streaming checkpoints.

## Layer 7 - Partitioned Deterministic Merge

ResultCollector can become the new bottleneck.

Use deterministic partitions:

```txt
partition by stable hash(noteId)
P0
P1
P2
P3
```

Rules:

- each partition sorted deterministically;
- final merge order deterministic;
- warnings sorted;
- unresolved sorted;
- edge groups sorted.

This keeps parallelism without noisy diffs.

## Layer 8 - Build Priority System

Not all files have equal value.

Priority examples:

```txt
priority 100: current workspace
priority 90: visible graph neighborhood
priority 80: backbone
priority 70: people index
priority 50: current year
priority 10: archive
```

Use priority for:

- scheduling;
- partial refresh;
- repair ordering;
- background indexing.

## Layer 9 - Partial Snapshot Strategy

For huge vaults:

```txt
build complete -> publish
```

is too coarse.

Target model:

```txt
base snapshot
+ fresh partitions
+ stale partitions
```

Example:

```txt
People fresh
Diary fresh
Archive rebuilding
```

Partial snapshots must be explicit and quality-scored.

## Layer 10 - Quality Gate

Validation is not enough.

Add `SnapshotQualityScore`:

```json
{
  "coverage": 0.98,
  "stalePartitions": 2,
  "failedFiles": 7,
  "unresolvedDelta": "+10",
  "edgeDropRate": 0.001
}
```

Decisions:

```txt
PUBLISH
REJECT
PUBLISH_PARTIAL
KEEP_PREVIOUS
RETRY_BACKGROUND
```

Quality inputs:

- node delta;
- edge delta;
- unresolved delta;
- failed files;
- stale partitions;
- coverage;
- previous snapshot comparison;
- parser/resolver incidents.

## Layer 11 - Build Memory

Build history file:

```txt
.graph-cache/local/build-history.jsonl
```

Record:

```json
{
  "buildId": "uuid",
  "mode": "BACKGROUND_NORMAL",
  "workers": 8,
  "durationMs": 12000,
  "diskPressure": "HIGH",
  "eventLoopDelayP95": 45,
  "serializationMs": 900,
  "snapshotDecision": "PUBLISHED",
  "nextRecommendation": {
    "workers": 4,
    "targetChunkBytes": 2097152
  }
}
```

The system should remember:

- this vault is worse with 8 workers;
- 3-4 workers are optimal;
- read bursts are punished by Defender;
- parser is cheap but resolver is expensive;
- serialization became bottleneck.

## First Slice

`V16-S1 Self Observing Build Runtime`

Tasks:

```txt
1. Save WorkPlan after build.
2. Add ExecutionTrace.
3. Add build-history.jsonl.
4. Measure event loop delay.
5. Measure serialization overhead.
6. Add adaptive worker reduction.
7. Add snapshot quality report.
8. Add publish/reject decision reasons.
9. Add build cost estimation.
10. Add priority queue skeleton.
```

Done:

```txt
System knows why build happened.
System knows why resources were chosen.
System learns previous performance.
System refuses suspicious snapshots.
System can improve future builds.
```

## Implementation Progress

### V16-S1A Self Observing Build Runtime Foundation - DONE

Implemented:

- `GraphBuildIntent/v16.0`;
- `GraphBuildSchedulerDecision/v16.0`;
- `GraphBuildCostEstimate/v16.0`;
- `GraphBuildExecutionTrace/v16.0`;
- `GraphBuildResourcePolicy/v16.0`;
- `GraphBuildRuntimeHealth/v16.0`;
- `GraphSnapshotQualityReport/v16.0`;
- `GraphBuildHistoryRecord/v16.0`;
- `GraphBuildPriorityPlan/v16.0`;
- `BuildHistoryStore` with JSONL append support;
- `AdaptiveResourceGovernor` with event-loop, serialization, disk, memory, and queue pressure reactions;
- suspicious snapshot quality gate with `KEEP_PREVIOUS` fallback;
- benchmark tool: `Scripts/Obsidian/measure-graph-build-runtime.js`.

Closed:

- `V16-B001`: build history now gives the runtime memory across builds.
- `V16-B002`: static worker policy now has an adaptive runtime governor.
- `V16-B003`: serialization overhead is measured and can reduce chunk size.
- `V16-B005`: priority plan orders current workspace/backbone/people before archives.
- `V16-B007`: suspicious snapshot deltas now produce explicit quality decisions.
- `V16-B008`: build memory can recommend lower worker/chunk pressure.

Current benchmark baseline:

```txt
Scenario: 10K changed files, 50K total files, 1024MB changed data, 6 initial workers
Total runtime decision layer: 2.13ms
Scheduler: 1.117ms
Cost estimator: 0.08ms
Resource governor: 0.145ms
Quality gate: 0.097ms
Build history: 0.199ms
Priority plan: 0.065ms
Serialization measurement: 0.427ms
Workers: 6 -> 4
Snapshot decision: KEEP_PREVIOUS
Next recommendation: workers=5, targetChunkBytes=4194304
```

Test status:

```txt
Pester: 47 passed, 0 failed
```

## What To Lower From v15

Lower priority:

- aggressive mode;
- workers=8 tuning;
- perfect chunk sizes;
- more parallelism;
- resolver in workers.

Raise priority:

- ExecutionTrace;
- BuildHistory;
- event loop health;
- serialization cost;
- adaptive throttling;
- quality scoring;
- priority scheduling.

## Extension Points

```txt
ExtensionPoint: BuildScheduler
Future:
AI workload prediction

ExtensionPoint: CostEstimator
Future:
learned performance model

ExtensionPoint: ResourceGovernor
Future:
reinforcement tuning

ExtensionPoint: QualityGate
Future:
semantic graph validation

ExtensionPoint: PriorityPlanner
Future:
user behavior based indexing

ExtensionPoint: SnapshotSystem
Future:
partial graph publishing

ExtensionPoint: Compiler
Future:
distributed build
```

## Tests

Required tests:

- build scheduler chooses `DELAY` during sync storm;
- cost estimator emits estimated duration/read/write;
- execution trace records resource choice reasons;
- build history writes JSONL record;
- event loop delay over threshold reduces workers;
- serialization overhead is measured;
- quality gate rejects suspicious unresolved spike;
- quality gate keeps previous snapshot on low coverage;
- priority queue orders current workspace before archive;
- build memory recommends fewer workers after high disk pressure.

## Benchmarks

Benchmark cases:

```txt
bench:v16-scheduler-idle-vs-active
bench:v16-cost-estimator
bench:v16-event-loop-protection
bench:v16-serialization-overhead
bench:v16-quality-gate
bench:v16-build-history-recommendation
bench:v16-priority-queue
```

Report schema:

```json
{
  "buildId": "uuid",
  "schedulerDecision": "BACKGROUND",
  "costEstimate": {
    "estimatedMs": 3500,
    "estimatedReadMb": 200
  },
  "resourcePolicy": {
    "initialWorkers": 6,
    "finalWorkers": 4,
    "reason": "EVENT_LOOP_DELAY"
  },
  "runtimeHealth": {
    "eventLoopDelayP95": 42,
    "serializationMs": 900,
    "queuePressure": "HIGH"
  },
  "qualityGate": {
    "decision": "PUBLISH",
    "coverage": 0.99,
    "unresolvedDelta": 0
  },
  "nextRecommendation": {
    "workers": 4,
    "targetChunkBytes": 2097152
  }
}
```

## Open Bugs To Track

```txt
V16-B001: one-shot WorkPlan does not let the system learn over time.
V16-B002: static worker policy can overload disk or main thread.
V16-B003: worker speed can hide structuredClone serialization bottleneck.
V16-B004: batch collector can become single-thread bottleneck at 500K notes.
V16-B005: no priority system treats current workspace and old archive equally.
V16-B006: all-or-nothing snapshot publish blocks useful partial freshness.
V16-B007: validation without quality score can publish suspicious graph deltas.
V16-B008: no build history prevents real auto-tuning.
```

Closed bugs:

```txt
V16-B001: fixed in V16-S1A by BuildHistoryStore and recommendation policy.
V16-B002: fixed in V16-S1A by AdaptiveResourceGovernor.
V16-B003: fixed in V16-S1A by serialization overhead measurement and chunk-size reaction.
V16-B005: fixed in V16-S1A by GraphBuildPriorityPlan.
V16-B007: fixed in V16-S1A by GraphSnapshotQualityReport and KEEP_PREVIOUS fallback.
V16-B008: fixed in V16-S1A by build-history JSONL records.
```
