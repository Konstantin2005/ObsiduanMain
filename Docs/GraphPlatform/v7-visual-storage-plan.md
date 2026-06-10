# Resilient Graph Platform v7: Real Data First

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Diagnosis

The first v7 draft was useful as an architecture map, but too broad as an execution plan. It tried to plan renderer UX, storage schema, workers, WebGL, layout, query indexes, cache management, benchmarks, and polish at the same time.

That is the wrong risk profile right now.

The current Ultra Graph is still a Canvas MVP that renders synthetic `20,000` nodes. The next proof point is not a perfect graph engine. The next proof point is:

```txt
real Graph Store data -> visible real nodes -> responsive pan/zoom -> measured benchmark
```

Everything that does not directly help that proof point is deferred.

## North Star

Do not build the perfect graph engine first.

First make real data visible, safe, measured, and responsive.

Then upgrade storage.

Then upgrade visuals.

Then workers.

Then WebGL, only if Canvas is proven to be the bottleneck.

## Current Baseline

- Vault size: `33,900` nodes, `35,948` edges.
- Graph Store build: about `1.85s`.
- Store write: about `38ms`.
- RenderPlan: about `9.54ms`.
- Scheduler: about `7.72ms`.
- Ultra Graph: Canvas MVP, synthetic `20,000` nodes, frame-budget drawing, degraded/emergency modes, health panel.

## Execution Order

```txt
Real data -> viewport culling -> edge budget -> benchmark -> storage safety -> incremental update -> visual utility -> worker compute -> WebGL
```

## Hard Rules

- Native Obsidian graph remains protected by `fast-backbone`.
- Full native graph is never opened at startup.
- Heavy graph rendering goes through Ultra Graph only.
- Benchmarks must use temporary stores unless explicitly requested.
- Every phase gets tests before it is considered done.
- Renderer changes must preserve a safe fallback path.
- Storage changes must preserve `current/previous/next` recovery.

## Anti-Goals

These are explicitly forbidden until their gates are met:

- Do not build WebGL before real-data Canvas benchmark proves Canvas draw is the bottleneck.
- Do not build OffscreenCanvas drawing before the real-data Canvas renderer is stable.
- Do not build full incremental storage before a read-only plugin-side Graph Store client works.
- Do not build visual polish before viewport culling and edge budgets are stable.
- Do not build dirty rectangle redraw for pan/zoom now.
- Do not build minimap, themes, cluster hulls, or edge bundling before real data is smooth.
- Do not build a perfect append-only database as the first storage upgrade.

## Kill Switch Policy

Ultra Graph must have an explicit overload escape hatch:

```txt
Ultra Graph overloaded -> close Ultra Graph renderer -> apply safe native fast-backbone graph
```

Done criteria:

- repeated emergency frames trigger the kill switch;
- user sees a clear message;
- Guard applies `fast-backbone`;
- no full native graph is opened;
- incident is logged.

## Target Performance

| Scenario | Target |
| --- | --- |
| Real `Calendula-20K` graph open | no plugin crash, no UI freeze |
| 20K-34K nodes idle overview | responsive perceived interaction |
| active pan/zoom | no long input stalls |
| RenderPlan warm p95 | under `8ms` target, under `12ms` acceptable |
| visible edges during movement | labels off, edges heavily budgeted |
| idle edge refinement | max `5K` edges in first slice |
| missing/corrupt store | friendly recovery state |
| benchmark output | JSON, deterministic enough to compare |

## v7.0: Real Data First

Goal: Ultra Graph opens the real `Calendula-20K` graph, not synthetic nodes.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-0-001 | Plugin-side GraphStoreClient | TODO | uses `app.vault.adapter.readBinary/read`, no Node `fs` in plugin runtime |
| V7-0-002 | Load manifest only first | TODO | Ultra Graph reads tiny manifest before loading arrays |
| V7-0-003 | Load required arrays only | TODO | first pass loads layout x/y, node type/flags, edge source/target/flags |
| V7-0-004 | Render real node positions | TODO | Canvas uses `graph.layout.x/y.bin`, not synthetic coordinates |
| V7-0-005 | Render real edges under strict budget | TODO | edges are drawn from real edge arrays after node pass |
| V7-0-006 | Friendly store failure state | TODO | missing/corrupt store shows repair/rebuild action instead of crashing |
| V7-0-007 | Benchmark before/after | TODO | JSON report proves real-data renderer behavior |
| TEST-V7-0 | Real-data renderer tests | TODO | mocked adapter loads store, draws nodes/edges, handles corrupt store |

Done means:

```txt
Ultra Graph opens real 33,900 nodes.
It does not draw synthetic data.
It does not freeze the UI.
Store failure does not crash the plugin.
There is a benchmark, not just a feeling.
```

Implementation notes:

- Keep Canvas 2D.
- Keep one full canvas repaint per frame.
- Use LOD, culling, and batch budgets instead of dirty rectangles.
- Treat strings/labels as cold data.
- Do not load labels in the first real-data frame.

## v7.1: Make It Fast

Goal: real-data Canvas becomes responsive before any worker/WebGL work.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-1-001 | Viewport culling | TODO | renderer draws only camera-visible nodes plus padding |
| V7-1-002 | Spatial grid index | TODO | simple grid supports fast viewport queries; no quadtree yet |
| V7-1-003 | Adaptive edge pass | TODO | edges skip during input burst and refine after idle |
| V7-1-004 | Labels off during movement | TODO | active pan/zoom never draws labels |
| V7-1-005 | RenderPlan p95 gate | TODO | benchmark fails if RenderPlan exceeds accepted p95 |
| V7-1-006 | Emergency frame policy | TODO | repeated slow frames enter emergency mode or trigger kill switch |
| TEST-V7-1 | Culling and budget tests | TODO | visible set, edge budget, and degraded modes are deterministic |

Removed from this phase:

```txt
dirty rectangles
cluster hulls
minimap
WebGL
OffscreenCanvas drawing
themes
```

Why spatial grid, not quadtree:

- simpler implementation;
- stable deterministic tests;
- enough for camera viewport culling;
- easier to serialize later into storage.

## v7.2: Storage Safety

Goal: make the existing store safer and more explicit before making it more clever.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-2-001 | Store capability manifest | TODO | renderer checks schema, arrays, layout, and feature flags |
| V7-2-002 | Preserve `current/previous/next` | TODO | atomic swap behavior remains tested |
| V7-2-003 | Corrupt group recovery | TODO | corrupt current store falls back to previous |
| V7-2-004 | Read-only client contract | TODO | plugin client cannot write store during rendering |
| V7-2-005 | Repair command | TODO | rebuilds into temp/next and swaps only after validation |
| TEST-V7-2 | Storage safety tests | TODO | incompatible schema, missing arrays, corrupt current, repair flow |

Do not build yet:

```txt
compression
binary sharding
tombstones
compaction
full journal replay
```

The important storage upgrade for this phase is reliability, not features.

## v7.3: Incremental Index MVP

Goal: avoid full rebuild for one changed note, without building a perfect database.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-3-001 | Fingerprint table | TODO | path, mtime, size, and content hash are saved |
| V7-3-002 | Changed-file detector | TODO | indexer computes added/changed/deleted files |
| V7-3-003 | Stable node IDs | TODO | unchanged files preserve node IDs and layout positions |
| V7-3-004 | Update changed node | TODO | changed note updates one node row where possible |
| V7-3-005 | Replace changed source edges | TODO | outgoing edges for changed source are replaced |
| V7-3-006 | Fallback to full rebuild | TODO | incremental failure automatically falls back safely |
| TEST-V7-3 | Incremental MVP tests | TODO | add/change/delete note, preserve IDs, fallback on failure |

Non-goal:

```txt
Do not build an ideal append-only graph database now.
```

Acceptance:

- changing one diary note should not scan and rewrite everything;
- if incremental update is unsafe, full rebuild happens instead;
- previous store remains recoverable.

## v7.4: Visual Utility

Goal: add visual features only after real data is already responsive.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-4-001 | Node taxonomy | TODO | diary, person, system, backbone, selected nodes have distinct styles |
| V7-4-002 | Selected neighborhood | TODO | click highlights 1-hop/2-hop neighborhood |
| V7-4-003 | Label priority | TODO | labels use priority and budget, not all nodes |
| V7-4-004 | Search/filter overlay | TODO | filter compiles to candidate node set before rendering |
| V7-4-005 | Cluster aggregation | TODO | overview can show aggregated cluster structure |
| TEST-V7-4 | Visual utility tests | TODO | style policy, selection, labels, and filters are deterministic |

Deferred:

```txt
minimap
themes
cluster hulls
edge bundling polish
```

Visual policy:

- overview: density/cluster structure, few edges;
- mid zoom: important nodes, backbone, selected local edges;
- close zoom: labels and precise node affordances;
- active movement: no labels, reduced edges;
- idle: refine gradually.

## v7.5: Worker Compute

Goal: move expensive compute off the main thread, while main thread still owns drawing.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-5-001 | Worker protocol | TODO | main thread sends camera/profile/query events |
| V7-5-002 | Worker RenderPlan compute | TODO | worker computes visible nodes/edges/batches |
| V7-5-003 | Worker query bitsets | TODO | worker computes filters without blocking input |
| V7-5-004 | Worker edge batches | TODO | worker prepares edge batches for main-thread draw |
| V7-5-005 | Stale frame cancellation | TODO | old worker results are dropped |
| TEST-V7-5 | Worker compute tests | TODO | stale results, query batches, fallback path |

Important:

- OffscreenCanvas drawing is not part of v7.5.
- Main thread still draws.
- Worker first proves compute isolation.

OffscreenCanvas becomes a separate experiment only after v7.5 is stable.

## v7.6: WebGL Only If Needed

Goal: start WebGL only if Canvas is proven to be the bottleneck.

Gate:

```txt
Canvas real-data benchmark misses target FPS.
Visible nodes/edges are already optimized.
RenderPlan p95 is acceptable.
Storage/query/layout are not the bottleneck.
Draw calls are the bottleneck.
```

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-6-001 | WebGL decision report | TODO | benchmark proves Canvas draw bottleneck |
| V7-6-002 | WebGL capability probe | TODO | safe fallback to Canvas |
| V7-6-003 | Minimal GPU node renderer | TODO | draw visible nodes with GPU buffers |
| V7-6-004 | Minimal GPU edge renderer | TODO | draw visible edges with GPU buffers |
| TEST-V7-6 | WebGL fallback tests | TODO | no-WebGL path still works |

Not part of first WebGL slice:

```txt
GPU picking
complex instancing system
advanced shader effects
full WebGL health dashboard
```

## First Slice: V7-S1

This is the next implementation slice.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-S1-001 | GraphStoreClient via adapter | TODO | reads manifest with `read`, binary arrays with `readBinary` |
| V7-S1-002 | Load manifest | TODO | store stats and file paths shown in health panel |
| V7-S1-003 | Load layout x/y | TODO | real node positions available as typed arrays |
| V7-S1-004 | Load node type/flags | TODO | renderer can style diary/person/backbone nodes |
| V7-S1-005 | Draw real nodes | TODO | synthetic node generation removed from normal path |
| V7-S1-006 | Viewport culling | TODO | visible node list uses camera bounds |
| V7-S1-007 | Draw max 5K edges after idle | TODO | edges never block input burst |
| V7-S1-008 | Benchmark JSON | TODO | reports loaded nodes, visible nodes, drawn edges, frame mode |
| TEST-V7-S1 | First slice tests | TODO | adapter mock, real arrays, culling, edge idle budget, missing store |

Expected result:

```txt
Real Calendula-20K graph opens.
Pan/zoom does not die.
Edges do not block input.
There is benchmark data, not vibes.
```

## Risk Register

| ID | Risk | Mitigation |
| --- | --- | --- |
| R-V7-001 | Plan becomes too broad again | enforce v7.0-v7.6 gates and anti-goals |
| R-V7-002 | Plugin-side binary reads are slow | load manifest first, required arrays only, batch reads where possible |
| R-V7-003 | Renderer freezes on first real draw | node pass first, edges after idle, labels off |
| R-V7-004 | Store corruption crashes plugin | friendly failure state and previous-store recovery |
| R-V7-005 | Canvas is blamed too early | benchmark query/storage/render/draw separately before WebGL |
| R-V7-006 | Visual polish distracts from performance | defer polish until v7.4 |

## Acceptance Gates

Before leaving v7.0:

- Ultra Graph renders real nodes from Graph Store.
- Synthetic data is fallback/demo only, not normal path.
- Missing/corrupt store does not crash.
- Benchmark JSON exists.

Before leaving v7.1:

- viewport culling is active;
- edge budget is active;
- labels are off during movement;
- RenderPlan p95 is measured;
- emergency/kill-switch behavior is tested.

Before leaving v7.3:

- one changed note can update without full rebuild when safe;
- stable IDs preserve layout;
- fallback full rebuild is automatic and tested.

Before starting v7.6:

- Canvas has real-data benchmark failure;
- culling and edge budgets are already optimized;
- draw is proven to be bottleneck.
