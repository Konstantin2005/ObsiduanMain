# Resilient Graph Platform v8: Complex Graph Systems Plan

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v7 `Real Data First` is good as the next sprint, but too local as the architecture for a complex graph system.

It answers:

```txt
How do we finally show real nodes?
```

v8 must answer:

```txt
How do we build a graph platform that survives growing complexity?
```

The v8 formula:

```txt
Real Data First.
Contract First.
Budget Always.
Fallback Everywhere.
Explain Every Skip.
Never Let Graph Complexity Leak Into Renderer.
```

## Why v7 Is Not Enough

The v7 rewrite correctly cut premature WebGL, OffscreenCanvas drawing, minimap, themes, dirty rectangles, and storage overengineering. But it also cut too much architectural protection.

The dangerous assumption is:

```txt
First make real data visible, safe, measured, and responsive.
Then upgrade storage.
Then upgrade visuals.
Then workers.
Then WebGL.
```

For a complex system, the stronger rule is:

```txt
First make real data visible through contracts that already assume storage evolution, query planning, degradation, and backend swapping.
```

Otherwise we get a fast Canvas renderer that later has to be broken apart to become a real platform.

## Non-Negotiable Standard

Every optimization or feature must have:

- `contract`
- `budget`
- `benchmark`
- `fallback`
- `reason code`

If one is missing, it is an experiment, not a production feature.

## Current Baseline

- Vault size: `33,900` nodes, `35,948` edges.
- Graph Store build: about `1.85s`.
- Store write: about `38ms`.
- RenderPlan: about `9.54ms`.
- Scheduler: about `7.72ms`.
- Ultra Graph: Canvas MVP, synthetic `20,000` nodes, frame-budget drawing, degraded/emergency modes, health panel.

## Anti-Goals

These stay out of the near-term implementation:

- OffscreenCanvas drawing.
- WebGL.
- Themes.
- Minimap.
- Dirty rectangles.
- Cluster hulls as polish.
- Edge bundling polish.
- Compression.
- Tombstones.
- Full journal replay.
- Perfect append-only graph database.
- GPU picking.
- Shader effects.

These move earlier:

- Runtime contracts.
- Store validation.
- Query plan layer.
- Degradation ladder.
- Multi-scale model.
- Backend abstraction.
- Observability reason codes.
- Contract tests.

## Layer 1: Runtime Safety

Runtime safety is not just "close Ultra Graph if overloaded". That is the final step.

The system needs a degradation ladder:

| Level | Mode | Behavior |
| --- | --- | --- |
| L0 | normal | full current budget |
| L1 | labels-off | labels disabled |
| L2 | edge-reduced | edge budget reduced |
| L3 | cluster-only | raw nodes/edges hidden, cluster/backbone overview only |
| L4 | renderer-paused | state preserved, drawing paused |
| L5 | ultra-closed | Ultra Graph closed |
| L6 | safe-native | Guard applies native `fast-backbone` |

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-SAFE-001 | Define `DegradationState` enum | TODO | L0-L6 states are explicit and tested |
| V8-SAFE-002 | Add degradation transition policy | TODO | slow frames, memory pressure, and failures map to next state |
| V8-SAFE-003 | Add reason codes for transitions | TODO | every degradation transition explains why it happened |
| V8-SAFE-004 | Preserve renderer state before pause/close | TODO | camera/profile/selection survive fallback |
| V8-SAFE-005 | Guard fallback integration | TODO | L6 applies `fast-backbone`, never full native graph |
| TEST-V8-SAFE | Safety ladder tests | TODO | all transitions and fallback behavior covered |

## Layer 2: Durable Graph Store

Minimum before real renderer:

```txt
manifest validation
typed array validation
schema validation
edge endpoint validation
layout count validation
current/previous fallback
```

Later:

```txt
current/previous/next
journal
incremental update
compaction
sharding
compression
```

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-STORE-001 | `GraphStoreClient` contract | TODO | plugin runtime reads through adapter only |
| V8-STORE-002 | `GraphSnapshot` contract | TODO | loaded graph snapshot has manifest, arrays, validation, lineage |
| V8-STORE-003 | Manifest validation | TODO | schema/version/files/capabilities checked before array load |
| V8-STORE-004 | Typed array length validation | TODO | node/edge/layout array lengths match manifest stats |
| V8-STORE-005 | Edge endpoint validation | TODO | source/target IDs are in bounds |
| V8-STORE-006 | Layout count validation | TODO | layout x/y length equals node count |
| V8-STORE-007 | Current/previous recovery | TODO | corrupt current falls back to previous |
| V8-STORE-008 | Failure-domain mapping | TODO | store errors map to explicit `FailureState` values |
| TEST-V8-STORE | Store contract tests | TODO | good, missing, corrupt, mismatch, previous-fallback cases |

## Layer 3: Data Lineage

Every frame and benchmark should be explainable.

Required lineage fields:

```json
{
  "storeBuildId": "...",
  "layoutBuildId": "...",
  "profileId": "...",
  "queryPlanId": "...",
  "renderPlanId": "...",
  "benchmarkRunId": "..."
}
```

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-LINEAGE-001 | Add store build ID | TODO | manifest contains stable build ID |
| V8-LINEAGE-002 | Add layout build ID | TODO | layout version/algorithm/seed are tracked |
| V8-LINEAGE-003 | Add profile/query/render IDs | TODO | health panel and benchmark include IDs |
| V8-LINEAGE-004 | Add benchmark run ID | TODO | JSON benchmarks are comparable over time |
| TEST-V8-LINEAGE | Lineage tests | TODO | IDs exist and propagate through snapshot/plan/benchmark |

## Layer 4: Query Algebra

Viewport culling is not a query engine.

The renderer must not own graph filtering logic. Queries compile into bitsets and priority sets before rendering.

Target contract:

```ts
type GraphQueryPlan = {
  profile: ProfilePolicy;
  filters: FilterExpression[];
  candidateNodes: Bitset;
  priorityNodes: Uint32Array;
  excludedNodes: Bitset;
  edgePolicy: EdgePolicy;
  labelPolicy: LabelPolicy;
  reasonCodes: string[];
};
```

Query types:

- profile query
- tag query
- path query
- type query
- selection query
- ego query
- cluster query
- viewport query
- priority query

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-QUERY-001 | Define `GraphQueryPlan` schema | TODO | query plan is immutable and testable |
| V8-QUERY-002 | Define `FilterExpression` schema | TODO | tag/path/type/profile/selection filters are explicit |
| V8-QUERY-003 | Candidate bitset builder | TODO | filters compile to node bitsets |
| V8-QUERY-004 | Priority node set builder | TODO | selected/backbone/important nodes get priority |
| V8-QUERY-005 | Excluded node bitset | TODO | hidden nodes are removed before RenderPlan |
| V8-QUERY-006 | Query reason codes | TODO | skipped/excluded nodes explain why |
| TEST-V8-QUERY | Query contract tests | TODO | filters produce deterministic bitsets and reason codes |

## Layer 5: Multi-Scale Model

Large graphs cannot be only "nodes and edges".

The core model needs multiple levels:

| Level | Meaning |
| --- | --- |
| 0 | domain map |
| 1 | clusters |
| 2 | backbone |
| 3 | important nodes |
| 4 | selected neighborhood |
| 5 | raw node detail |

This is a core scalability feature, not visual polish.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-SCALE-001 | Define multi-scale levels | TODO | levels 0-5 are part of RenderPlan inputs |
| V8-SCALE-002 | Cluster-level candidates | TODO | overview can render cluster/domain nodes |
| V8-SCALE-003 | Backbone-level candidates | TODO | backbone remains available at low zoom |
| V8-SCALE-004 | Ego graph candidates | TODO | selected neighborhood can be isolated |
| V8-SCALE-005 | Raw detail gate | TODO | raw nodes/labels only appear at detail zoom/budget |
| TEST-V8-SCALE | Multi-scale tests | TODO | each zoom/LOD level selects expected candidate layer |

## Layer 6: Render Planning

Renderer does not decide what matters. It receives:

```txt
RenderPlan
FrameBudget
DegradationState
```

RenderPlan is built from:

```txt
query plan
viewport
LOD
edge budget
memory state
input state
frame history
```

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-PLAN-001 | Define RenderPlan schema v8 | TODO | plan contains nodes, edges, labels, skipped reasons, lineage |
| V8-PLAN-002 | Define `BudgetPolicy` schema | TODO | node/edge/label/frame budgets are explicit |
| V8-PLAN-003 | Define `FrameBudget` schema | TODO | per-frame time/draw limits are explicit |
| V8-PLAN-004 | Edge tier policy | TODO | backbone/local/semantic/selected edges are tiered |
| V8-PLAN-005 | Edge sampling policy | TODO | sampling is deterministic and reason-coded |
| V8-PLAN-006 | Label policy | TODO | labels are cold, priority-based, and budgeted |
| TEST-V8-PLAN | RenderPlan contract tests | TODO | plan is immutable, budgeted, reason-coded, and deterministic |

## Layer 7: Backend Isolation

Even if only Canvas exists today, Canvas must not leak into the architecture.

Target contract:

```ts
interface RenderBackend {
  id: string;
  loadSceneBuffers(snapshot: GraphSnapshot): Promise<void>;
  draw(plan: RenderPlan, budget: FrameBudget): RenderStats;
  dispose(): void;
}
```

Initial backends:

- `CanvasBackend`
- `NullBackend`
- `FutureWebGLBackend` placeholder/probe

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-BACKEND-001 | Define `RenderBackend` interface | TODO | Canvas is behind a backend boundary |
| V8-BACKEND-002 | Implement `CanvasBackend` | TODO | current Canvas drawing moves behind backend |
| V8-BACKEND-003 | Implement `NullBackend` | TODO | tests/benchmarks can run without drawing |
| V8-BACKEND-004 | Add backend failure state | TODO | backend failure maps to `FailureState` |
| V8-BACKEND-005 | Add backend stats | TODO | draw calls, nodes, edges, frame time are reported |
| TEST-V8-BACKEND | Backend contract tests | TODO | Canvas/Null backend share contract behavior |

## Layer 8: Observability Contracts

Every frame should answer:

```txt
Why are these nodes visible?
Why were these edges skipped?
Why are labels disabled?
Which budget fired?
Which degradation level is active?
Which store/layout/profile/query/render plan was used?
```

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-OBS-001 | Define reason code registry | TODO | skip/degrade/failure reason codes are documented |
| V8-OBS-002 | Frame stats schema | TODO | every frame emits comparable stats |
| V8-OBS-003 | Benchmark schema | TODO | JSON benchmark schema is stable |
| V8-OBS-004 | Health panel v8 fields | TODO | health panel shows lineage, budgets, degradation |
| V8-OBS-005 | Incident log integration | TODO | failures/degradations are logged with reason codes |
| TEST-V8-OBS | Observability tests | TODO | stats and benchmark schema are contract-tested |

## Failure Domains

Do not collapse all failures into "friendly error".

Failure domains:

| Domain | Example | Fallback |
| --- | --- | --- |
| `vault-read-failure` | adapter read throws | failure state, repair action |
| `manifest-failure` | invalid/missing manifest | previous store or rebuild |
| `binary-array-failure` | missing/short array | previous store or rebuild |
| `schema-mismatch` | incompatible version | safe failure with upgrade note |
| `layout-missing` | x/y absent | fallback layout or rebuild |
| `query-index-missing` | tag/path index absent | slower query or rebuild |
| `render-backend-failure` | Canvas/WebGL error | NullBackend or safe native fallback |
| `worker-failure` | worker crash/timeout | main-thread compute fallback |
| `memory-pressure` | high memory/slow frames | degradation ladder |
| `guard-repair-failure` | Guard cannot apply profile | incident and safe error |

## v8.0: Contracted Real Data Slice

Goal: make real data visible without locking the architecture into Canvas or unsafe storage reads.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-0-001 | Define `GraphStoreClient` interface | TODO | plugin client uses adapter and returns `GraphSnapshot` |
| V8-0-002 | Define `StoreValidationResult` | TODO | validation errors are typed and reason-coded |
| V8-0-003 | Define `FailureState` enum | TODO | all failure domains map to explicit states |
| V8-0-004 | Define `ProfilePolicy` contract | TODO | profile/budget/renderer settings are separated |
| V8-0-005 | Define `BudgetPolicy` contract | TODO | node/edge/label/frame budgets are explicit |
| V8-0-006 | Define `RenderPlan` schema | TODO | renderer receives immutable, budgeted plan |
| V8-0-007 | Define `RenderBackend` interface | TODO | Canvas is one backend, not the architecture |
| V8-0-008 | Define benchmark schema | TODO | benchmark JSON is stable and comparable |
| TEST-V8-0 | Contract tests | TODO | all contracts have fixture tests |

Done:

```txt
real data renderer can work,
Canvas does not leak into architecture,
store validation exists,
benchmark has a stable schema.
```

## v8.1: Real Data Canvas

Goal: draw the real graph through the new contracts.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-1-001 | Load manifest | TODO | manifest is validated before arrays |
| V8-1-002 | Validate arrays | TODO | lengths, endpoint bounds, and layout counts checked |
| V8-1-003 | Load x/y/type/flags only | TODO | first hot path avoids labels/string tables |
| V8-1-004 | Build viewport visible set | TODO | camera culling happens before drawing |
| V8-1-005 | Draw real nodes through CanvasBackend | TODO | no synthetic data in normal path |
| V8-1-006 | Draw max `2K` idle edges | TODO | edge draw starts smaller than v7's `5K` |
| V8-1-007 | Emit reason codes for skips | TODO | skipped nodes/edges/labels are explainable |
| V8-1-008 | Emit benchmark JSON | TODO | benchmark includes lineage and frame stats |
| TEST-V8-1 | Real Canvas tests | TODO | adapter mock, validation, drawing, skips, failure state |

## v8.2: Degradation Ladder

Goal: degrade gracefully before closing Ultra Graph.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-2-001 | Slow-frame detection | TODO | p95/rolling frame history drives degradation |
| V8-2-002 | Labels-off level | TODO | labels disabled first |
| V8-2-003 | Edge-budget reduction level | TODO | edge tiers reduced before node loss |
| V8-2-004 | Cluster-only fallback | TODO | overview survives when raw graph is too heavy |
| V8-2-005 | Renderer pause state | TODO | camera/selection/profile preserved |
| V8-2-006 | Safe native fallback | TODO | final fallback applies `fast-backbone` |
| V8-2-007 | Incident log | TODO | all transitions logged with reason codes |
| TEST-V8-2 | Degradation tests | TODO | L0-L6 transitions and recovery are covered |

## v8.3: Query Plan Layer

Goal: keep graph complexity out of the renderer.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-3-001 | Profile filters | TODO | profile policy compiles to candidates |
| V8-3-002 | Type filters | TODO | diary/person/system filters compile to bitsets |
| V8-3-003 | Tag filters | TODO | tag filters compile from index or fallback scan |
| V8-3-004 | Path filters | TODO | path/year/month filters compile to bitsets |
| V8-3-005 | Selection filters | TODO | selected/ego graph queries are explicit |
| V8-3-006 | Candidate bitsets | TODO | RenderPlan consumes bitsets, not ad-hoc filters |
| V8-3-007 | Priority node sets | TODO | selected/backbone/important nodes are prioritized |
| TEST-V8-3 | Query plan tests | TODO | all filters produce deterministic candidate sets |

## v8.4: Multi-Scale Graph

Goal: make clusters/backbone/ego graph core scalability features.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-4-001 | Domain map level | TODO | graph can render domain-level overview |
| V8-4-002 | Cluster level | TODO | clusters are first-class render candidates |
| V8-4-003 | Backbone level | TODO | backbone is core navigation layer |
| V8-4-004 | Important node level | TODO | high-priority nodes survive low budgets |
| V8-4-005 | Ego graph level | TODO | selected neighborhood is isolated cleanly |
| V8-4-006 | Raw detail level | TODO | raw nodes/labels appear only under detail gates |
| TEST-V8-4 | Multi-scale tests | TODO | LOD and budgets choose correct levels |

## v8.5: Storage Evolution

Goal: evolve storage only after contracts and real rendering are stable.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-5-001 | Preserve `current/previous/next` | TODO | atomic store swap remains tested |
| V8-5-002 | Schema migration | TODO | old compatible stores load or migrate safely |
| V8-5-003 | Stable IDs | TODO | unchanged files keep node IDs |
| V8-5-004 | Fingerprints | TODO | mtime/size/hash table supports change detection |
| V8-5-005 | Incremental update MVP | TODO | changed source node/edges update without full rebuild |
| V8-5-006 | Full rebuild fallback | TODO | unsafe incremental update falls back automatically |
| TEST-V8-5 | Storage evolution tests | TODO | migrate, stable ID, fingerprint, incremental, fallback |

## v8.6: Worker Compute

Goal: move computation off main thread; drawing still stays on main thread.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-6-001 | Query plan worker | TODO | filters/bitsets compute off main thread |
| V8-6-002 | Viewport worker | TODO | visible sets compute off main thread |
| V8-6-003 | Edge batch worker | TODO | edge tiers/batches compute off main thread |
| V8-6-004 | Stale result cancellation | TODO | late worker results are dropped |
| V8-6-005 | Main-thread fallback | TODO | worker failure falls back safely |
| TEST-V8-6 | Worker compute tests | TODO | worker success, stale result, crash fallback |

OffscreenCanvas remains a separate experiment after this.

## v8.7: Backend Upgrade

Goal: add WebGL only after benchmark proves draw bottleneck.

Gate:

```txt
Canvas real-data benchmark misses target FPS.
Visible nodes/edges are optimized.
RenderPlan p95 is acceptable.
Storage/query/layout are not the bottleneck.
Draw is the bottleneck.
```

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-7-001 | Canvas bottleneck report | TODO | benchmark proves draw bottleneck |
| V8-7-002 | WebGL capability probe | TODO | fallback to Canvas remains safe |
| V8-7-003 | Minimal WebGL node backend | TODO | visible nodes render through GPU buffers |
| V8-7-004 | Minimal WebGL edge backend | TODO | visible edges render through GPU buffers |
| V8-7-005 | Backend comparison benchmark | TODO | Canvas vs WebGL JSON comparison |
| TEST-V8-7 | Backend upgrade tests | TODO | no-WebGL fallback and backend contract pass |

## First Slice: V8-S1 Contracted Real Renderer

This replaces the v7 first slice.

Tasks:

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V8-S1-001 | Define `GraphStoreClient` interface | TODO | plugin-side store reads are behind contract |
| V8-S1-002 | Define `RenderBackend` interface | TODO | Canvas is swappable |
| V8-S1-003 | Define `RenderPlan` schema | TODO | renderer receives immutable plan |
| V8-S1-004 | Define `BudgetPolicy` schema | TODO | node/edge/label/frame budgets are explicit |
| V8-S1-005 | Load manifest | TODO | manifest read through adapter |
| V8-S1-006 | Validate manifest and arrays | TODO | lengths, schema, endpoint bounds checked |
| V8-S1-007 | Load x/y/type/flags only | TODO | labels/string tables stay cold |
| V8-S1-008 | Build viewport visible set | TODO | camera culling before drawing |
| V8-S1-009 | Draw real nodes via CanvasBackend | TODO | normal path draws real Graph Store data |
| V8-S1-010 | Draw max `2K` idle edges | TODO | smaller first edge budget than v7 |
| V8-S1-011 | Emit benchmark JSON | TODO | benchmark includes lineage/stats/reasons |
| V8-S1-012 | Emit reason codes | TODO | skipped nodes/edges/labels explainable |
| V8-S1-013 | Missing/corrupt store enters `FailureState` | TODO | no crash on bad store |
| TEST-V8-S1 | First slice contract tests | TODO | contracts, adapter mock, validation, render, failure, benchmark |

Done:

```txt
Real graph opens.
Architecture does not lock into Canvas.
Bad store does not crash.
Renderer does not own query logic.
Benchmark proves frame behavior.
Skipped visual data has explainable reasons.
```

## Contract Test Matrix

| Contract | Test Focus |
| --- | --- |
| `GraphStoreClient` | adapter reads, manifest validation, array validation, failure domains |
| `GraphSnapshot` | lineage, stats, arrays, validation result |
| `RenderPlan` | immutability, budgets, visible sets, skipped reasons |
| `BudgetPolicy` | node/edge/label/frame caps, degradation changes |
| `ProfilePolicy` | safe native, ultra graph, danger profiles |
| `FailureRecovery` | store failure, backend failure, worker failure, fallback ladder |
| `BenchmarkSchema` | stable JSON, run IDs, timings, budgets, reason codes |
| `RenderBackend` | Canvas and Null backend obey same draw contract |

## Acceptance Gates

Before leaving v8.0:

- Contracts exist and have tests.
- Store validation exists before real draw.
- Canvas is behind backend boundary.
- Failure domains map to `FailureState`.
- Benchmark schema is stable.

Before leaving v8.1:

- real nodes draw from Graph Store;
- synthetic path is fallback/demo only;
- bad store does not crash;
- skipped visual data has reason codes;
- benchmark JSON proves behavior.

Before leaving v8.2:

- L0-L6 degradation ladder is implemented;
- safe native fallback is tested;
- incident log records transitions.

Before starting v8.7:

- Canvas benchmark proves draw bottleneck;
- query/storage/layout/render planning are not the bottleneck;
- backend swap does not require renderer rewrite.
