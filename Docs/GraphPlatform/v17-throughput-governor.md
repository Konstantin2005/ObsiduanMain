# Graph Throughput Governor v17

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v17 must not optimize for raw resource usage.

It must optimize for:

```txt
Maximize useful graph throughput
subject to UI latency, memory, IO, and correctness budgets.
```

The target is not:

```txt
CPU 95%
workers = cores - 1
disk queue as high as possible
```

The target is:

```txt
UsefulGraphFactsPerSecond under UI SLA
```

## Why v17 Exists

v16 introduced a self-observing build runtime:

```txt
BuildIntent
-> SchedulerDecision
-> CostEstimate
-> ResourceGovernor
-> QualityReport
-> BuildHistory
```

v17 changes the optimization principle.

The old trap:

```txt
more workers
more IO
more CPU
```

The production rule:

```txt
more useful work per unit of latency, memory, IO, and correctness risk
```

High CPU can be pure noise when the bottleneck is:

```txt
serialization
resolver
GC
disk IO
Windows Defender
snapshot write
main-thread publish
```

## Non-Negotiable Invariants

- Renderer never waits for a build.
- Renderer reads only published snapshots or explicit partial snapshots.
- Main thread does orchestration only.
- Main thread never parses markdown.
- Main thread never resolves full graph dependencies.
- Main thread never builds the full edge list.
- Snapshot publish has a minimal critical section.
- Workers do not all share one uncontrolled queue.
- Task pools are separated by workload type.
- Resource increases require measured throughput gain.
- UI SLA violation triggers immediate throttle.
- Dashboard must not become a source of performance noise.
- Partial graph publishing must expose freshness and coverage.
- Thermal, battery, and OS power signals are best-effort only.
- Observed throttling must be trusted over unavailable platform signals.

## Architecture

```txt
Resource Profiler
        |
        v
SLA Monitor
        |
        v
Cost Estimator
        |
        v
Build Scheduler
        |
        v
Work Planner
        |
        v
Throughput Governor
        |
        v
Task-specific Worker Pools
        |
        v
Streaming Compiler
        |
        v
Quality Gate
        |
        v
Snapshot Publisher
        |
        v
Dashboard / Build History
```

## Correct Success Metrics

Primary:

```txt
UsefulGraphFactsPerSecond under UI SLA
```

Supporting:

```txt
records/sec
links/sec
validatedSnapshot/sec
ms per useful graph fact
cache hit rate
read amplification
publish critical-section ms
eventLoopDelay p95/p99
serialization ms/MB
snapshot write MB/s
```

Anti-metrics:

```txt
CPU target 95%
workers = cores
workers = cores - 1
high disk queue
busy waiting
```

## UI SLA Contract

Modes:

```txt
INTERACTIVE_SAFE
BACKGROUND_MAX
IDLE_HIGH_THROUGHPUT
EMERGENCY_THROTTLE
```

Budgets:

```txt
INTERACTIVE_SAFE:
  eventLoopDelayP95 <= 16ms
  eventLoopDelayP99 <= 32ms
  inputLatency <= 50ms
  renderFrameBudget <= 16ms
  snapshotPublishMainThread <= 8ms
  dashboardUpdateHz <= 2

BACKGROUND_MAX:
  eventLoopDelayP95 <= 32ms
  snapshotPublishMainThread <= 8ms
  dashboardUpdateHz <= 2

IDLE_HIGH_THROUGHPUT:
  eventLoopDelayP95 <= 64ms
  snapshotPublishMainThread <= 8ms
  dashboardUpdateHz <= 1

EMERGENCY_THROTTLE:
  pause new IO
  workerCount <= 1
  maxInFlightBytes <= one chunk
  cache-only when possible
```

Immediate throttle actions:

```txt
workers -50%
pause IO for at least 500ms
drop low-priority queued chunks
reduce chunkBytes
reduce maxInFlightBytes
switch low-priority partitions to cache-only
```

## Resource Profiler

The profiler is not just hardware detection.

It is an observed capability model.

Static signals:

```txt
cpu cores
total memory
platform
node version
process architecture
```

Observed signals:

```txt
eventLoopDelay
worker throughput
parse ms/file
read MB/s
serialization ms/MB
GC pause estimate
snapshot write MB/s
publish critical-section ms
```

Contract:

```txt
GraphResourceProfile/v17.0
```

Shape:

```json
{
  "staticCaps": {
    "logicalCores": 12,
    "totalMemoryMb": 32768,
    "platform": "win32"
  },
  "observedCaps": {
    "parseFilesPerSec": 12000,
    "readMbPerSec": 350,
    "serializationMsPerMb": 4.2,
    "snapshotWriteMbPerSec": 220
  },
  "confidence": 0.72,
  "lastUpdated": "2026-06-11T00:00:00.000Z"
}
```

## SLA Monitor

Contract:

```txt
GraphSlaReport/v17.0
```

Responsibilities:

```txt
measure eventLoopDelay p95/p99
estimate input latency
measure publish critical section
measure dashboard update cost
emit violation reasons
trigger emergency throttle decisions
```

Violation reasons:

```txt
UI_LAG
INPUT_LATENCY
PUBLISH_TOO_LONG
DASHBOARD_OVERHEAD
FRAME_BUDGET_EXCEEDED
```

## Throughput Governor

Contract:

```txt
GraphThroughputGovernorDecision/v17.0
```

The governor is a loop:

```txt
measure
decide
apply
observe
learn
```

It controls:

```txt
workerCount
chunkBytes
maxInFlightBytes
maxReadConcurrency
taskPriority
pause/resume
cache-only mode
```

Throttle reasons:

```txt
UI_LAG
MEMORY_PRESSURE
DISK_LATENCY
SERIALIZATION_OVERHEAD
GC_PRESSURE
LOW_THROUGHPUT_GAIN
SYNC_STORM
BATTERY_SAFE_MODE
PUBLISH_TOO_LONG
```

Scale-up is allowed only when:

```txt
throughput gain is positive
UI SLA is still green
memory growth is bounded
disk latency is bounded
serialization cost is bounded
publish critical section is bounded
```

Scale-down is mandatory when:

```txt
SLA violation happens
useful throughput stops improving
memory pressure appears
disk latency spikes
serialization becomes dominant
publish critical section exceeds budget
```

## Adaptive Hill-Climbing

Do not use:

```txt
workers = cores - 1
```

Use conservative hill-climbing:

```txt
start workers: 2
try workers: 4
try workers: 6
compare useful throughput and SLA
keep only if throughput improves enough
step down immediately on SLA violation
```

Decision example:

```txt
workers 2 -> 4:
  useful throughput +38%
  eventLoopDelay p95 8ms -> 11ms
  keep

workers 4 -> 6:
  useful throughput +3%
  eventLoopDelay p95 11ms -> 24ms
  rollback to 4
```

## Task-Specific Worker Pools

Do not create one generic worker pool for all graph work.

Separate:

```txt
IOQueue
ParsePool
CompilerWorker
PeopleLinkPool
LayoutPrepPool
Publisher
```

Reason:

```txt
parsing is CPU-bound
reading is IO-bound
resolver is dependency-bound
people linking is correctness-bound
layout prep is memory-bound
publish is latency-bound
```

Important correction:

```txt
Workers may extract raw facts.
CompilerWorker performs deterministic resolve/build stages.
LayoutPrepPool may prepare layout facts.
Main thread only swaps the published snapshot pointer and notifies UI.
```

## IO Governor

`maxReadConcurrency` is not enough.

The IO governor must manage:

```txt
read amplification budget
bytes/sec target
latency sampling
cache hit target
small file batching
large file isolation
sync storm detection
Defender slowdown detection
pause reads decision
```

The governor must be allowed to say:

```txt
do not read now
```

Examples:

```txt
sync storm active -> delay
disk latency high -> pause reads
cache hit low -> reduce speculative reads
large file detected -> isolate from small file batch
observed Defender slowdown -> lower read concurrency
```

## Partition Consistency Model

Priority scheduling is useful only if partial freshness is explicit.

Contract:

```txt
GraphPartition/v17.0
```

Shape:

```json
{
  "id": "current-year",
  "priority": 90,
  "freshness": "partial-fresh",
  "coverage": 0.92,
  "lastBuildId": "build-123",
  "dependencies": ["people", "resolver-cache"]
}
```

Freshness states:

```txt
complete
partial-fresh
partial-stale
partition-building
partition-failed
missing
```

RenderPlan must expose:

```txt
which partition is fresh
which partition is stale
which partition is missing
```

This prevents a partial graph from pretending to be a complete graph.

## System Boundaries

Do not merge these into one vague runtime:

```txt
Graph Build Runtime
Prewarm / Cache Builder
People Link Runtime
Snapshot Publisher
Renderer Loader
Dashboard
```

Each system needs:

```txt
contract
budget
fallback
test
benchmark
failure mode
```

## Dashboard Budget

Dashboard can become overhead.

Rules:

```txt
sample at 1-2Hz
use metrics ring buffer
no heavy aggregation on main thread
export JSON separately
hide per-worker noisy detail by default
```

Dashboard must show:

```txt
mode
useful facts/sec
worker count
chunk bytes
max in-flight bytes
read concurrency
eventLoopDelay p95/p99
publish critical-section ms
throttle reasons
quality decision
cache hit rate
partition freshness summary
```

## Thermal and Battery Reality

Battery, thermal, OS power mode, and Defender signals are best-effort.

Do not make hard promises.

Fallback to observed throttling:

```txt
throughput decreases
latency increases
CPU remains high
disk latency increases
GC pressure increases
```

## Quality Gate

Before publish, validate:

```txt
node count delta
edge count delta
unresolved delta
failed files
coverage
stale partitions
snapshot schema
dependency completeness
publish critical-section budget
```

Decisions:

```txt
PUBLISH_FULL
PUBLISH_PARTIAL
KEEP_PREVIOUS
REPAIR_REQUIRED
```

## Build History / Learning

Save:

```txt
mode
workers
chunkBytes
maxInFlightBytes
readConcurrency
durationMs
usefulFactsPerSec
throttle reasons
quality result
SLA report
resource profile summary
```

Next run:

```txt
start from last known good config for this vault and machine
```

## First Slice

`V17-S1 UI-Protected Throughput Governor`

Tasks:

```txt
1. Add SLA Monitor with eventLoopDelay p95/p99.
2. Add ResourceProfile with static and observed fields.
3. Add ThroughputGovernor contract.
4. Add conservative dynamic worker resize.
5. Add maxInFlightBytes and maxReadConcurrency enforcement.
6. Add explicit throttle reasons.
7. Extend build-history.jsonl with throughput and SLA records.
8. Add dashboard sampling budget at <=2Hz.
9. Add benchmark: throughput vs eventLoopDelay.
10. Add emergency throttle mode.
```

Done:

```txt
Build uses more resources only while UI SLA holds.
If UI lag appears, workers and IO reduce automatically.
Dashboard explains every throttle reason.
Benchmark proves throughput gain and UI protection together.
Renderer remains isolated.
Snapshot publish still goes through quality gate.
```

## Benchmark Plan

Benchmarks:

```txt
bench:v17-throughput-vs-workers
bench:v17-event-loop-sla
bench:v17-serialization-pressure
bench:v17-disk-latency-pause
bench:v17-publish-critical-section
bench:v17-dashboard-overhead
bench:v17-partition-freshness
bench:v17-history-recommendation
```

Required report:

```json
{
  "contract": "GraphThroughputBenchmark/v17.0",
  "workers": [2, 4, 6],
  "usefulFactsPerSec": [10000, 13800, 14200],
  "eventLoopDelayP95": [8, 11, 24],
  "decision": "KEEP_WORKERS_4",
  "reasons": ["LOW_THROUGHPUT_GAIN", "UI_LAG_RISK"]
}
```

## What To Remove From the Previous Direction

Remove:

```txt
workers = cores
workers = cores - 1 as rule
CPU target 95% as success metric
battery/thermal hard promises
night/full rebuild turbo as a default goal
workers doing resolving/linking/layout in one shared pool
dashboard with high-frequency updates
```

Raise:

```txt
UI SLA
event loop delay
serialization overhead
GC pressure
useful throughput
adaptive resize
quality gate
partition freshness
build history
```

## Extension Points

```txt
ExtensionPoint: ResourceSignalProvider
Future:
  battery, thermal, OS power mode, Defender detection

ExtensionPoint: ThroughputGovernor
Future:
  hill-climbing and learned tuning

ExtensionPoint: TaskPool
Future:
  separate ParsePool, ResolverPool, PeoplePool, LayoutPool

ExtensionPoint: PartitionScheduler
Future:
  partial graph publishing with explicit freshness

ExtensionPoint: QualityGate
Future:
  semantic validation and anomaly detection

ExtensionPoint: Dashboard
Future:
  historical graphs and regression alerts

ExtensionPoint: BuildHistory
Future:
  auto-config per machine and vault
```

## Open Bugs To Track

```txt
V17-B001: raw CPU target can hide bad throughput.
V17-B002: fixed worker count can overload disk, GC, or serialization.
V17-B003: missing UI SLA can let background work freeze Obsidian.
V17-B004: merge/publish can overload main thread even when parsing is offloaded.
V17-B005: generic worker pool mixes CPU, IO, resolver, people, and layout workloads.
V17-B006: IO governor without latency/read-amplification budgets can make reads worse.
V17-B007: priority partial publishing can display a misleading graph without freshness map.
V17-B008: dashboard can become its own performance bottleneck.
V17-B009: battery/thermal signals may be unavailable or unreliable in Electron.
V17-B010: build history without useful throughput metric can learn the wrong policy.
```
