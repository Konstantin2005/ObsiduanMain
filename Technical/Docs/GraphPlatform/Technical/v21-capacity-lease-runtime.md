# Capacity Lease Runtime v21

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

Capacity is not a number.

Capacity is a contract with:

```txt
expiry
ownership
priority
confidence
revocation
recovery
```

v21 formula:

```txt
Do not just measure capacity.
Lease it, enforce it, revoke it, and recover it.
```

## Why v21 Exists

v19 corrected CPU saturation:

```txt
Saturate only when pipeline can absorb the work
and the system SLA stays green.
```

The next gap:

```txt
V20 describes overload protection,
but does not define a strict capacity control system.
```

Missing questions:

```txt
How is capacity measured?
How does capacity age?
How is capacity recalculated?
How do layers compete?
Who has the right to take resources?
Who can revoke resources?
```

Production runtime must say:

```txt
No work starts without admission.
No subsystem holds resources without a lease.
No partial snapshot pretends to be complete.
No faulty layer can take down the whole graph.
```

## Non-Negotiable Invariants

- Heavy work needs admission before it starts.
- Capacity has TTL and confidence.
- Capacity can expire.
- Capacity can be recalibrated.
- Resources are leased, not grabbed.
- Leases can renew, reduce, revoke, or expire.
- Fairness is per resource, not a single percent number.
- Brownout happens before emergency.
- Partial snapshots require truth labels.
- Faulty partitions are contained.
- Corruption in one producer does not poison the whole graph.
- Recovery uses hysteresis and cooldown.
- Chaos tests are required for overload claims.

## Architecture

```txt
Capacity Sampler
        |
        v
Capacity Envelope Manager
        |
        v
Admission Controller
        |
        v
Resource Lease Manager
        |
        v
Task DAG Scheduler
        |
        v
Backpressure + Brownout Controller
        |
        v
Execution Pools
        |
        v
Quality / Containment Gate
        |
        v
Truth-Labeled Snapshot Publisher
        |
        v
Recovery Manager
```

## Dynamic Capacity Envelope

Static envelope is unsafe.

Capacity changes because:

```txt
Windows Defender wakes up
Dropbox starts sync
laptop heats up
browser consumes memory
disk latency spikes
GC pressure rises
Obsidian opens a heavy note
```

Contract:

```txt
GraphCapacityEnvelope/v21.0
```

Shape:

```json
{
  "static": {
    "logicalCores": 12,
    "totalMemoryMb": 32768
  },
  "observed": {
    "readMbSec": 120,
    "compilerFactsSec": 80000,
    "publishCriticalSectionMs": 4
  },
  "effective": {
    "maxWorkersNow": 5,
    "maxReadMbSecNow": 80,
    "maxQueueBytesNow": 67108864
  },
  "confidence": 0.72,
  "ttlMs": 30000,
  "expiresAt": "2026-06-11T00:00:30.000Z",
  "lastCalibration": "2026-06-11T00:00:00.000Z"
}
```

Required fields:

```txt
static
observed
effective
confidence
ttlMs
expiresAt
lastCalibration
```

Rules:

```txt
expired envelope cannot admit heavy work
low confidence envelope reduces admission scope
pressure spike shortens TTL
stable observations can increase confidence
```

## Admission Controller

Do not start work and then fight fires.

Admit first.

Contract:

```txt
GraphAdmissionDecision/v21.0
```

Decisions:

```txt
START_NOW
START_DEGRADED
DEFER
REJECT
REPAIR_ONLY
```

Inputs:

```txt
build intent
deadline
capacity envelope
current leases
UI SLA
system pressure
task DAG cost
truth label risk
```

Example:

```txt
full rebuild 100K notes
+ UI active
+ disk latency high
= DEFER
```

Admission is not optional.

## Resource Lease Manager

Fairness must be enforced with leases.

Contract:

```txt
GraphResourceLease/v21.0
```

Shape:

```json
{
  "leaseId": "lease-123",
  "owner": "people-scan",
  "resources": {
    "workers": 2,
    "memoryMb": 256,
    "ioMbSec": 40,
    "queueBytes": 16777216,
    "publishBudgetMs": 0
  },
  "priority": 20,
  "expiresAt": "2026-06-11T00:00:05.000Z",
  "revocable": true,
  "status": "active"
}
```

Lease lifecycle:

```txt
request
grant
renew
reduce
revoke
expire
release
```

Resources:

```txt
workers
memoryMb
ioMbSec
queueBytes
publishBudgetMs
```

Resource fairness is per resource:

```txt
CPU share
IO share
memory share
queue share
publish share
```

Why:

```txt
people scan can use little CPU but fill result queues
validation can use little IO but consume compiler/publish time
layout can consume memory without high CPU
```

## Watermarks and Hysteresis

`Degrade before collapse` must be formal.

Contract:

```txt
GraphWatermarkPolicy/v21.0
```

Each critical metric needs:

```txt
soft watermark
hard watermark
critical watermark
recovery watermark
cooldownMs
hysteresisWindowMs
```

Example:

```txt
compilerBacklogBytes:
  soft: 32MB -> stop low priority
  hard: 64MB -> reduce parse workers
  critical: 128MB -> emergency mode
  recovery: 16MB for 10s -> recover
```

Without hysteresis:

```txt
runtime oscillates
workers flap
IO starts/stops rapidly
dashboard lies about stability
```

## Brownout Controller

Emergency is too late.

Brownout disables non-essential features before collapse.

Contract:

```txt
GraphBrownoutDecision/v21.0
```

Can disable:

```txt
dashboard detail
deep validation
layout prep
speculative prewarm
people scan
archive rebuild
historical metrics export
```

Must preserve:

```txt
current graph safety
changed-file core indexing
snapshot integrity
UI SLA
manifest recovery
quality gate
```

Brownout levels:

```txt
NONE
LIGHT
MODERATE
SEVERE
```

## Dependency-Aware Shedding

Work shedding must follow dependencies, not just task type.

Contract:

```txt
GraphSheddingPlan/v21.0
```

Rules:

```txt
if upstream is cancelled, cancel dependent downstream tasks
if partition is stale, cancel speculative derived tasks
if producer is contained, keep previous partition or mark missing
if generation changes, revoke leases for stale generation
```

Examples:

```txt
layout prep depends on nodes
validation depends on snapshot
compiler depends on parsed facts
people edges depend on people partition
```

No orphan tasks should burn CPU for an impossible publish.

## Truth-Labeled Snapshot Publisher

Partial snapshot without truth labels is dangerous.

Contract:

```txt
GraphSnapshotTruth/v21.0
```

Truth labels:

```txt
COMPLETE
PARTIAL_FRESH
PARTIAL_STALE
DEGRADED_CACHE_ONLY
PREVIOUS_ACTIVE
REPAIR_ONLY
```

Manifest shape:

```json
{
  "truthLabel": "PARTIAL_STALE",
  "coverage": {
    "coreGraph": 1.0,
    "peopleLinks": 0.74,
    "layout": 1.0,
    "archive": 0.52
  },
  "freshness": {
    "currentYear": "fresh",
    "people": "stale",
    "archive": "partial"
  },
  "missingPartitions": ["archive-2019"],
  "stalePartitions": ["people"],
  "queryLimitations": ["people-neighborhood-incomplete"],
  "visualWarning": "People links are stale; archive is partial."
}
```

Renderer rule:

```txt
RenderPlan must carry truth label and freshness map.
```

User must never see partial as complete.

## Containment Gate

Quality gate decides whether a snapshot can publish.

Containment gate decides whether a faulty subsystem can keep contributing.

Contract:

```txt
GraphContainmentDecision/v21.0
```

Anomalies:

```txt
people edges x10
unresolved links +5000
parser failures > threshold
layout invalid
edge count explosion
partition coverage collapse
malformed worker result
```

Decisions:

```txt
ALLOW
PUBLISH_WITHOUT_PARTITION
KEEP_PREVIOUS_PARTITION
DISABLE_PRODUCER
OPEN_INCIDENT
REPAIR_ONLY
```

Examples:

```txt
people scan explodes:
  disable people producer
  keep previous people partition
  publish core graph as PARTIAL_STALE

parser malformed result:
  reject parser partition
  open incident
  retry smaller chunk
```

## Chaos Harness

Stress harness must be hostile.

Faults:

```txt
worker returns huge result
worker returns malformed result
compiler slows 10x
publisher throws mid-write
disk full
permission denied
snapshot manifest half-written
system clock jumps backwards
memory allocation fails
cache directory deleted during build
sync rewrites files during publish
lease expires mid-task
capacity envelope expires during admission
```

Required checks:

```txt
no crash
no corrupt published snapshot
incident recorded
faulty partition contained
leases revoked or expired
truth label correct
recovery without oscillation
```

## First Slice

`V21-S1 Capacity Lease + Brownout Runtime`

Tasks:

```txt
1. Add dynamic CapacityEnvelope with confidence and TTL.
2. Add AdmissionController.
3. Add ResourceLease contract.
4. Add soft/hard/critical/recovery watermarks with hysteresis.
5. Add BrownoutController.
6. Add SnapshotTruthLabel.
7. Add ContainmentGate for anomalous partitions.
8. Add lease revoke/reduce behavior.
9. Add overload chaos tests.
10. Add recovery hysteresis tests.
```

Done:

```txt
Heavy work is admitted only when safe.
Resources are leased, not grabbed.
Low-priority systems brown out before collapse.
Partial snapshots are truth-labeled.
Faulty partitions are contained.
System recovers without oscillation.
```

## Implementation Progress

### V21-S1A Capacity Lease + Brownout Foundation - DONE

Implemented:

- `GraphCapacityEnvelope/v21.0`;
- `GraphAdmissionDecision/v21.0`;
- `GraphResourceLease/v21.0`;
- `GraphWatermarkPolicy/v21.0`;
- `GraphWatermarkDecision/v21.0`;
- `GraphBrownoutDecision/v21.0`;
- `GraphSheddingPlan/v21.0`;
- `GraphSnapshotTruth/v21.0`;
- `GraphContainmentDecision/v21.0`;
- dynamic capacity envelope with confidence and TTL;
- admission controller with `START_NOW`, `START_DEGRADED`, `DEFER`, `REJECT`, and `REPAIR_ONLY`;
- resource lease manager with grant, revoke, reduce, expire, and priority preemption;
- soft/hard/critical/recovery watermarks with hysteresis;
- brownout controller that disables non-essential work before emergency;
- dependency-aware shedding that propagates cancellation downstream;
- truth-labeled partial snapshot contract;
- partition containment gate for producer anomalies;
- benchmark tool: `Technical/Scripts/Obsidian/measure-graph-capacity-lease-runtime.js`.

Closed:

- `V21-B001`: capacity envelope now has TTL and confidence.
- `V21-B002`: heavy work now goes through admission.
- `V21-B003`: resource ownership is represented through leases.
- `V21-B005`: shedding now propagates through dependencies.
- `V21-B006`: partial snapshots now require truth labels.
- `V21-B007`: watermarks include recovery and hysteresis.
- `V21-B008`: brownout exists before emergency.
- `V21-B009`: faulty partitions can be contained.
- `V21-B011`: lease expiry is modeled.
- `V21-B012`: expired capacity envelope defers admission.

Current benchmark baseline:

```txt
Scenario: confidence 0.72, compiler backlog 80MB, people edge multiplier 12
Total capacity lease benchmark layer: 2.898ms
Admission: START_DEGRADED
Admission reason: low-capacity-confidence
Leases granted: 4
Leases revoked: 1
Active owners: current-view, compiler, snapshot-repair
Brownout: MODERATE
Disabled: dashboard-detail, deep-validation, layout-prep, speculative-prewarm, people-scan
Truth label: PARTIAL_STALE
Contained partitions: people
Containment actions: KEEP_PREVIOUS_PARTITION, DISABLE_PRODUCER, OPEN_INCIDENT
Dependency-aware shedding cancelled tasks: 4
Recovered without oscillation: true
```

Test status:

```txt
Pester: 51 passed, 0 failed
```

## Benchmark and Chaos Plan

Benchmarks:

```txt
bench:v21-capacity-envelope-ttl
bench:v21-admission-under-pressure
bench:v21-lease-revoke-reduce
bench:v21-watermark-hysteresis
bench:v21-brownout-before-emergency
bench:v21-truth-labeled-partial
bench:v21-containment-anomaly
bench:v21-chaos-publisher-failure
```

Report schema:

```json
{
  "contract": "CapacityLeaseBenchmark/v21.0",
  "admission": "START_DEGRADED",
  "leasesGranted": 3,
  "leasesRevoked": 1,
  "brownout": "MODERATE",
  "truthLabel": "PARTIAL_STALE",
  "containedPartitions": ["people"],
  "recoveredWithoutOscillation": true
}
```

## What To Lower From V20

Lower:

```txt
generic capacity benchmark
static fairness percentages
partial snapshot without truth labels
emergency mode as the primary fallback
capacity as a stable number
```

Raise:

```txt
admission control
resource leases
watermarks with hysteresis
brownout
truth labels
containment
chaos tests
capacity TTL/confidence
```

## Extension Points

```txt
ExtensionPoint: CapacitySampler
Future:
  OS-specific signals, Windows perf counters, battery/thermal

ExtensionPoint: AdmissionPolicy
Future:
  learned admission based on build history

ExtensionPoint: LeaseManager
Future:
  multi-resource fairness, priority inheritance

ExtensionPoint: BrownoutPolicy
Future:
  user-configurable quality/performance profiles

ExtensionPoint: ContainmentGate
Future:
  semantic anomaly detection

ExtensionPoint: SnapshotTruth
Future:
  query-time freshness explanations

ExtensionPoint: ChaosHarness
Future:
  fault injection suite
```

## Open Bugs To Track

```txt
V21-B001: static capacity envelope can make decisions from stale machine state.
V21-B002: no admission control means heavy work starts before safety is known.
V21-B003: fairness percentages without leases do not enforce ownership.
V21-B004: single fairness share cannot cover CPU, IO, memory, queue, and publish budgets.
V21-B005: shedding by task type can leave dependency orphan work running.
V21-B006: partial snapshot without truth label can mislead the user.
V21-B007: degrade without thresholds/hysteresis causes oscillation.
V21-B008: emergency-only fallback reacts too late.
V21-B009: faulty producer can poison otherwise healthy graph partitions.
V21-B010: stress harness without chaos cannot prove resilience.
V21-B011: lease expiry during task execution can leave unowned work.
V21-B012: capacity envelope expiry during admission can admit unsafe work.
```
