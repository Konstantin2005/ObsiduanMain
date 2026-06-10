# Resilient Graph Platform v9: Critical Path Graph Platform

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v7 was too local.

v8 was too correct on paper.

v9 is the plan we can actually build without drowning in abstractions.

```txt
Not Contract First.
Critical Path First, Contracted.
```

Final build order:

```txt
First protect the first real frame.
Then protect every next frame.
Then protect storage.
Then query.
Then multi-scale.
Then workers.
Then WebGL.
```

v8 is not wrong. It is just too wide for the next implementation slice. It defines many future contracts before the system proves that the first production frame can open fast, safely, and repeatably.

v9 keeps the useful parts of v8, but moves them behind one rule:

```txt
Only contract what is on the critical rendering path now.
Everything else is deferred until the real frame is protected.
```

## Critical Production Path

This is the first path that must be made boring, tested, measured, and recoverable:

```txt
open Ultra Graph
-> load manifest
-> validate minimal arrays
-> load x/y/type/flags
-> build visible node set
-> build tiny RenderPlan
-> draw Canvas nodes
-> draw small idle edge batch
-> emit frame stats
-> recover safely on failure
```

Nothing outside this path may block the first real frame.

## Non-Negotiable Invariants

- Renderer never reads vault.
- Renderer never reads markdown.
- Renderer never loads strings on first frame.
- Renderer never filters by text.
- Renderer never mutates `GraphSnapshot`.
- `RenderPlan` is immutable.
- `FrameStats` is aggregate-only.
- Canvas is behind backend.
- Bad store never throws past `GraphStoreClient`.
- No fallback opens full native graph.

## Minimal v9.0 Contracts

Only these contracts are allowed before the first real frame:

| Contract | Purpose | Hot Path Role |
| --- | --- | --- |
| `GraphStoreClient` | Owns all store reads, adapter errors, shallow validation, and recovery state | yes |
| `GraphSnapshot` | Immutable typed-array view of loaded graph data | yes |
| `RenderPlan` | Immutable list of visible draw work for one frame | yes |
| `RenderBackend` | Backend boundary for Canvas and test rendering | yes |
| `FrameStats` | Aggregate timing and count output for the frame | yes |
| `FailureState` | Typed safe failure result when store or backend cannot proceed | yes |

Everything else must wait until the first real frame is stable.

## Deferred Until After First Real Frame

- full `QueryPlan`;
- full lineage;
- multi-scale levels;
- reason registry;
- worker protocol;
- WebGL;
- complex `ProfilePolicy`;
- string tables;
- label planner;
- benchmark export polish;
- cluster integrity checks;
- query index integrity checks.

Deferred does not mean rejected. It means it cannot sit on the first-frame path yet.

## Hot Path / Cold Path Separation

Hot path:

```txt
camera update
viewport cull
RenderPlan build
Canvas draw
frame stats
```

Cold path:

```txt
labels
strings
query indexes
lineage details
benchmark export
repair/rebuild
validation deep scan
```

Rule:

```txt
Hot path may depend on cold path only through already-loaded immutable IDs or counters.
Cold path must never synchronously ask the renderer to wait.
```

## Hot Path Budgets

| Operation | Target | Acceptable | Failure Action |
| --- | ---: | ---: | --- |
| manifest read | `<= 50ms` | `<= 80ms` | enter `degraded` or `blocking` store state |
| minimal validation | `<= 100ms` | `<= 150ms` | skip deep validation and emit store warning |
| array load `x/y/type/flags` | `<= 500ms` | `<= 800ms` | reduce first-frame draw budget |
| visible set build | `<= 4ms` | `<= 8ms` | shrink visible budget, skip edges |
| `RenderPlan` build | `<= 4ms` | `<= 8ms` | shrink edge budget, keep nodes |
| Canvas node draw | `<= 8ms` | `<= 12ms` | increase stride or LOD, keep interaction |
| idle edge draw | `<= 4ms` | `<= 6ms` | stop edge batch for this frame |
| frame stats overhead | `<= 0.5ms` | `<= 1ms` | aggregate less often |

## Performance Envelope For Contract Overhead

Contracts must prove they are cheap enough to stay on the hot path.

| Contract | Max Allowed Overhead | Notes |
| --- | ---: | --- |
| `GraphStoreClient` wrapper | `<= 1ms` after adapter read | no deep validation in hot path |
| `GraphSnapshot` construction | `<= 2ms` | typed-array references, no cloning |
| `RenderPlan` freeze/immutability guard | `<= 1ms` | shallow freeze or structural convention |
| `RenderBackend.draw` dispatch | `<= 0.2ms` | no per-node virtual calls |
| `FrameStats` collection | `<= 0.5ms` | aggregate counters only |
| `FailureState` mapping | `<= 0.2ms` | no stack parsing in frame loop |

If a contract exceeds the envelope, it moves out of the hot path or is redesigned.

## Budget Exceeded Policy

When budget is missed, the renderer must degrade in this order:

1. Stop idle edge drawing for this frame.
2. Keep labels disabled.
3. Reduce edge batch size.
4. Reduce visible node cap.
5. Increase render stride while input is moving.
6. Switch to cluster or backbone overview only when available.
7. Pause renderer while preserving camera and state.
8. Enter safe native profile, never full native graph.

Every budget action emits aggregate counters, not per-object reason records.

## Validation Policy

Shallow validation before first frame:

```txt
manifest schema
file presence
node count
layout count
basic array lengths
```

Deep validation after idle/background:

```txt
edge endpoint bounds
duplicate IDs
full consistency
cluster integrity
query index integrity
```

Rule:

```txt
Shallow validation protects startup.
Deep validation protects correctness.
Deep validation must not block first paint.
```

## Aggregate Reasons Only

Reason codes are frame-level aggregates, not per-node or per-edge objects.

Example:

```json
{
  "skipReasons": {
    "OUTSIDE_VIEWPORT": 29120,
    "EDGE_BUDGET": 18200,
    "LABELS_DISABLED_MOVING": 33900
  }
}
```

This gives observability without creating a second graph-sized allocation.

## Lineage Policy

Frame-level lineage carries IDs only:

```json
{
  "storeBuildId": "store-2026-06-10-001",
  "layoutBuildId": "layout-2026-06-10-001",
  "renderPlanId": "rp-000123",
  "frameId": 123
}
```

Detailed lineage is stored once per session or benchmark run.

Frame loop must never carry full lineage objects.

## Failure Severity Matrix

| Severity | Meaning | Examples | Runtime Behavior |
| --- | --- | --- | --- |
| `recoverable` | retry or fallback can continue real rendering | missing optional layout metadata, idle edge batch error | keep nodes, retry cold work |
| `degraded` | graph can render with reduced quality | memory pressure, slow frames, backend warning | reduce budgets, keep interaction |
| `blocking` | first real frame cannot be trusted | missing manifest, wrong array length, incompatible schema | show safe failure state, offer rebuild |
| `fatal` | runtime cannot safely proceed | repeated backend failure, guard repair failure, invariant violation | stop Ultra Graph path and preserve safe native profile |

All adapter and store exceptions must be mapped into this matrix inside `GraphStoreClient`.

## Backend Isolation

Allowed v9.0 backends:

- `CanvasBackend`
- `NullBackend`

Explicitly not allowed in v9.0:

- `FutureWebGLBackend` placeholder

Reason:

```txt
A placeholder backend is architecture theater until Canvas proves draw is the bottleneck.
```

Backend contract:

```ts
interface RenderBackend {
  id: string;
  draw(plan: RenderPlan, frameBudget: FrameBudget): FrameStats;
  dispose(): void;
}
```

Rules:

- Canvas calls are inside `CanvasBackend`.
- Tests use `NullBackend`.
- Backend failure maps to `FailureState`.
- No renderer code branches on Canvas internals.

## Resource Governors

### FrameGovernor

Owns:

- rolling frame timing;
- input burst detection;
- edge budget;
- node cap;
- render stride;
- transition cooldowns.

Must answer:

```txt
Can this frame draw nodes?
Can this frame draw edges?
Should labels remain disabled?
Should the renderer degrade or recover?
```

### MemoryGovernor

Owns:

- typed-array memory envelope;
- string/label load permission;
- cold cache size;
- emergency memory pressure state.

Must answer:

```txt
Can cold data be loaded?
Should edge batches shrink?
Should graph enter cluster/backbone only mode?
```

### IOGovernor

Owns:

- manifest read timing;
- array load timing;
- deep validation scheduling;
- repair/rebuild scheduling;
- concurrent file read limit.

Must answer:

```txt
Can this IO run before first frame?
Should this IO move to idle?
Should failed IO block, degrade, or retry?
```

## Operational State Machine

Runtime states:

| State | Meaning |
| --- | --- |
| `NORMAL` | budgets healthy |
| `INPUT_BURST` | user is moving camera; cold work and labels disabled |
| `FRAME_PRESSURE` | frame budget missed; reduce edges/nodes |
| `MEMORY_PRESSURE` | memory governor reduces cold data and caches |
| `STORE_DEGRADED` | current store partially usable or recovered |
| `RENDERER_DEGRADED` | backend can draw only reduced plan |
| `EMERGENCY_CLUSTER_ONLY` | raw graph too heavy; overview only when available |
| `PAUSED` | renderer paused, state preserved |
| `SAFE_NATIVE` | Ultra Graph stopped, safe native graph profile applied |

Every transition must define:

- trigger;
- cooldown;
- recovery condition;
- max retries;
- severity.

## Store Compatibility Matrix

Every store manifest must expose:

```json
{
  "storeVersion": 9,
  "supportedReadVersions": [7, 8, 9],
  "supportedWriteVersion": 9,
  "migrationRequired": false,
  "canRenderWithoutMigration": true
}
```

Compatibility rules:

- If `canRenderWithoutMigration` is true, first frame may render before migration.
- If `migrationRequired` is true but read version is supported, migration runs cold or idle.
- If read version is unsupported, enter `blocking` `FailureState`.
- Writes always target `supportedWriteVersion`.

## v9.0: Minimal Critical Contracts

Goal: define only the contracts needed by the first real frame.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-0-001 | Define `GraphStoreClient` | TODO | all adapter errors are caught and mapped to `FailureState` |
| V9-0-002 | Define `GraphSnapshot` | TODO | immutable typed-array view exposes `x/y/type/flags` |
| V9-0-003 | Define `RenderPlan` | TODO | immutable visible node set and idle edge batch |
| V9-0-004 | Define `RenderBackend` | TODO | Canvas hidden behind backend contract |
| V9-0-005 | Define `FrameStats` | TODO | aggregate counts and timings only |
| V9-0-006 | Define `FailureState` | TODO | recoverable/degraded/blocking/fatal states explicit |
| TEST-V9-0 | Minimal contract tests | TODO | contracts are cheap, immutable, and failure-safe |

## v9.1: Critical Real Frame

Goal: draw real nodes through the shortest safe path.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-1-001 | Open Ultra Graph through v9 entrypoint | TODO | no full native graph fallback on startup |
| V9-1-002 | Load manifest | TODO | manifest read budget measured |
| V9-1-003 | Shallow manifest validation | TODO | schema/files/counts/array lengths checked |
| V9-1-004 | Load only `x/y/type/flags` | TODO | no strings or labels in first frame |
| V9-1-005 | Build visible set by camera bounds | TODO | viewport culling before draw |
| V9-1-006 | Create immutable `RenderPlan` | TODO | plan build budget measured |
| V9-1-007 | Draw nodes through `CanvasBackend` | TODO | real nodes appear from Graph Store |
| V9-1-008 | Draw `<= 1000` idle edges | TODO | edge draw is optional and budgeted |
| V9-1-009 | Emit aggregate `FrameStats` | TODO | first frame explains timing and counts |
| V9-1-010 | Enter `FailureState` on bad store | TODO | missing/corrupt store does not crash |
| TEST-V9-1 | Critical frame tests | TODO | good store, missing store, corrupt store, slow budget, backend failure |

## v9.2: Governors And State Machine

Goal: keep every next frame stable after the first one works.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-2-001 | Add `FrameGovernor` | TODO | slow frames reduce edge/node budgets before pause |
| V9-2-002 | Add `MemoryGovernor` | TODO | cold loads and caches respect memory pressure |
| V9-2-003 | Add `IOGovernor` | TODO | deep validation and repair never block frame loop |
| V9-2-004 | Add operational state machine | TODO | transitions have trigger/cooldown/recovery/max retries |
| V9-2-005 | Add aggregate degradation reasons | TODO | no per-object reason allocations |
| TEST-V9-2 | Governor tests | TODO | pressure, recovery, cooldown, and safe fallback cases |

## v9.3: Deep Validation And Store Compatibility

Goal: protect correctness after first render.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-3-001 | Schedule deep validation in idle/background | TODO | endpoint bounds and duplicate IDs do not block first frame |
| V9-3-002 | Add store compatibility matrix | TODO | read/write/migration support is explicit |
| V9-3-003 | Add cold repair/rebuild flow | TODO | corrupt store can be repaired safely |
| V9-3-004 | Add previous-store recovery | TODO | current failure can fall back without throwing |
| TEST-V9-3 | Store compatibility tests | TODO | compatible, migration, unsupported, corrupt current, previous fallback |

## v9.4: Query Layer

Goal: introduce query planning only after real rendering and governors are stable.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-4-001 | Define minimal query input contract | TODO | renderer still receives only `RenderPlan` |
| V9-4-002 | Compile viewport/profile filters to bitsets | TODO | no text filtering in renderer |
| V9-4-003 | Add priority node sets | TODO | selected/backbone nodes survive budgets |
| V9-4-004 | Add cold query index integrity checks | TODO | query index validation stays off first frame |
| TEST-V9-4 | Query layer tests | TODO | deterministic bitsets, priority, budget interaction |

## v9.5: Multi-Scale Graph

Goal: add clusters/backbone as scalability layers after query planning exists.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-5-001 | Define scale levels from existing data | TODO | overview/backbone/detail levels are explicit |
| V9-5-002 | Build cluster/backbone candidates cold | TODO | scale data does not block first frame |
| V9-5-003 | Add scale-aware `RenderPlan` inputs | TODO | raw graph is not the only render layer |
| TEST-V9-5 | Multi-scale tests | TODO | zoom and pressure select expected scale |

## v9.6: Worker Compute

Goal: move compute off the main thread only when contracts and state recovery are proven.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-6-001 | Define worker message protocol | TODO | protocol is based on v9 contracts, not renderer internals |
| V9-6-002 | Move cold validation to worker | TODO | main thread remains responsive |
| V9-6-003 | Move query/visible-set compute when needed | TODO | stale worker results are dropped |
| V9-6-004 | Add main-thread fallback | TODO | worker failure maps to `degraded`, not crash |
| TEST-V9-6 | Worker tests | TODO | success, timeout, stale result, crash fallback |

## v9.7: Backend Upgrade Gate

Goal: add WebGL only after data proves Canvas draw is the bottleneck.

Gate:

```txt
Real data benchmark misses target FPS.
Visible set and RenderPlan are within budget.
Storage/query/layout are not the bottleneck.
Canvas draw is proven as the bottleneck.
Backend boundary already has CanvasBackend and NullBackend tests.
```

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-7-001 | Produce Canvas bottleneck report | TODO | draw time is the limiting factor |
| V9-7-002 | Define WebGL backend contract delta | TODO | no renderer rewrite required |
| V9-7-003 | Add minimal WebGL node backend | TODO | GPU path renders visible nodes only |
| V9-7-004 | Add Canvas fallback comparison | TODO | WebGL failure returns to Canvas safely |
| TEST-V9-7 | Backend upgrade tests | TODO | capability failure and backend comparison covered |

## First Slice: V9-S1 Critical Real Frame

This replaces `V8-S1 Contracted Real Renderer`.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-S1-001 | `GraphStoreClient` catches all adapter errors | TODO | no adapter exception escapes to renderer |
| V9-S1-002 | Shallow manifest validation | TODO | manifest schema, files, counts, basic lengths checked |
| V9-S1-003 | Load only `x/y/type/flags` | TODO | no strings, labels, markdown, or text filters on first frame |
| V9-S1-004 | Build visible set by camera bounds | TODO | culling target `<= 4ms`, acceptable `<= 8ms` |
| V9-S1-005 | Create immutable `RenderPlan` | TODO | plan build target `<= 4ms`, acceptable `<= 8ms` |
| V9-S1-006 | Draw nodes through `CanvasBackend` | TODO | real nodes appear through backend boundary |
| V9-S1-007 | Draw `<= 1000` idle edges | TODO | edges never block node draw |
| V9-S1-008 | Emit aggregate `FrameStats` | TODO | timings, counts, budgets, aggregate skip reasons |
| V9-S1-009 | Missing/corrupt store enters `FailureState` | TODO | no crash and no full native graph fallback |
| V9-S1-010 | Benchmark hot path budgets | TODO | first-frame and frame-loop budget report exists |
| TEST-V9-S1 | Critical real frame tests | TODO | real store fixture, bad store fixture, budget pressure, backend failure |

Done:

```txt
Real nodes appear.
No synthetic normal path.
No strings first frame.
No labels first frame.
No uncaught store errors.
No full native fallback.
No Canvas architecture leak.
Frame stats prove where time went.
```

## Deleted From The Near Plan

These are not part of v9.0 or v9.1:

- WebGL placeholder backend;
- full reason registry;
- per-node skip reason objects;
- full lineage objects in frame loop;
- full query algebra;
- multi-scale levels;
- worker protocol;
- profile-policy expansion;
- label rendering;
- theme polish;
- minimap;
- cluster hulls;
- edge bundling polish.

## Contract Test Matrix

| Contract | Test Focus |
| --- | --- |
| `GraphStoreClient` | adapter errors, shallow validation, bad store mapping, previous fallback later |
| `GraphSnapshot` | immutability, typed-array references, no strings first frame |
| `RenderPlan` | immutability, visible node set, idle edge cap, no renderer mutation |
| `RenderBackend` | Canvas/Null parity, backend failure state |
| `FrameStats` | aggregate-only timings, counts, reason counters |
| `FailureState` | recoverable/degraded/blocking/fatal mapping |
| `FrameGovernor` | budget miss, cooldown, recovery |
| `MemoryGovernor` | cold data block, pressure, cache limits |
| `IOGovernor` | first-frame IO allowlist, idle deep validation |

## Acceptance Gates

Before leaving v9.0:

- minimal six contracts exist;
- contracts have tests;
- contract overhead is measured;
- no deferred architecture leaks into hot path.

Before leaving v9.1:

- real nodes draw from Graph Store;
- synthetic data is not the normal path;
- first frame loads no strings and no labels;
- bad store enters `FailureState`;
- no fallback opens full native graph;
- `CanvasBackend` and `NullBackend` are tested;
- aggregate `FrameStats` prove hot path timing.

Before leaving v9.2:

- governors control frame, memory, and IO pressure;
- operational state machine has trigger/cooldown/recovery/max retries;
- degradation is aggregate-reasoned and recoverable.

Before starting v9.7:

- Canvas is proven as the draw bottleneck;
- storage, query, layout, and RenderPlan are within budget;
- WebGL can be added without rewriting renderer ownership.
