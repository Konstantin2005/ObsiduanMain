# Resilient Graph Platform v7: Visual + Storage Upgrade Plan

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## North Star

Make `Calendula-20K` feel smooth and visually useful at 20K+ nodes, then leave a path to 50K-100K nodes without rewriting the platform again.

The v6 foundation is good: safe native startup, Guard, Graph Store, RenderPlan, Scheduler, Ultra Graph MVP, health panel, benchmarks. v7 should stop drawing synthetic nodes and become a real graph product:

- Real indexed graph data in Ultra Graph, not synthetic coordinates.
- Smooth pan/zoom with no UI freeze.
- Clear visual hierarchy: clusters, people, diaries, backbone, selected neighborhoods.
- Storage that updates incrementally instead of rebuilding everything.
- Layout/cache pipeline that survives restarts and can be benchmarked.

## Current Baseline

- Vault size: `33,900` nodes, `35,948` edges.
- Graph Store build: about `1.85s`.
- Store write: about `38ms`.
- RenderPlan: about `9.54ms`.
- Scheduler: about `7.72ms`.
- Ultra Graph: Canvas MVP, synthetic `20,000` nodes, frame-budget drawing, degraded/emergency modes, health panel.

## Hard Rules

- Native Obsidian graph remains protected by `fast-backbone`.
- Full graph is never opened at startup.
- Heavy graph rendering goes through Ultra Graph only.
- All mass vault/storage writes need dry-run/force policy.
- Benchmarks must use temporary stores unless explicitly requested.
- Every milestone gets tests before it is considered done.

## Target Performance

| Scenario | Target |
| --- | --- |
| 20K nodes idle pan/zoom | 55-60 FPS perceived |
| 20K nodes active drag | no main-thread stall over 16ms |
| 30K-50K nodes overview | LOD/cluster mode, stable interaction |
| RenderPlan from warm store | under 8ms p95 |
| Incremental update after 1 changed note | under 100ms |
| Cold store rebuild 30K-50K | under 5s |
| Startup safe graph | under 2s perceived, no heavy panes |
| Storage corruption recovery | automatic fallback to previous snapshot |

## Milestone V7-A: Real Data Ultra Graph

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-A001 | Load Graph Store in Ultra Graph | TODO | Ultra Graph reads `graph.current` manifest and typed arrays |
| V7-A002 | Replace synthetic nodes with store layout | TODO | Canvas renders real node positions from `graph.layout.x/y.bin` |
| V7-A003 | Render real edges by RenderPlan | TODO | edges drawn from edge IDs, not generated placeholders |
| V7-A004 | Use profile budgets in renderer | TODO | UI respects `maxVisibleNodes`, `maxVisibleEdges`, label policy |
| V7-A005 | Store load failure state | TODO | missing/corrupt store shows friendly repair action |
| TEST-V7-A | Real graph renderer tests | TODO | mocked store loads, draws, degrades, and recovers |

Implementation notes:

- Ultra Graph should call a small browser-compatible loader, not import Node-only `fs` directly.
- For Obsidian plugin runtime, load store files through `app.vault.adapter.readBinary/read`.
- Keep Node Graph Store modules for tests/build scripts, but create a plugin-side `graph-store-client`.
- Initial real renderer can still be Canvas 2D, but data must come from the real store.

## Milestone V7-B: Visual Renderer Pipeline

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-B001 | Split renderer into layers | TODO | background, clusters, edges, nodes, labels, hover, selection are separate passes |
| V7-B002 | Viewport culling | TODO | renderer draws only camera-visible nodes plus padding |
| V7-B003 | Spatial index | TODO | quadtree/grid index supports fast viewport queries |
| V7-B004 | Dirty rectangle redraw | TODO | small interactions avoid full-canvas repaint when possible |
| V7-B005 | Adaptive edge pass | TODO | edges skip first during input burst and fade in after idle |
| V7-B006 | Progressive refinement | TODO | clusters first, nodes second, edges third, labels last |
| TEST-V7-B | Renderer pipeline tests | TODO | culling, pass ordering, and degraded passes are deterministic |

Visual policy:

- Overview zoom: clusters and density fields, very few edges.
- Mid zoom: key nodes, backbone edges, selected local edges.
- Close zoom: labels, precise node shapes, hover affordances.
- Active pan/zoom: never draw labels, draw sampled edges only.
- Idle: refine visual quality gradually.

## Milestone V7-C: Better Visual Design

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-C001 | Visual taxonomy | TODO | diary, person, cluster, backbone, selected, orphan have distinct styles |
| V7-C002 | Cluster hulls | TODO | year/month/person groups have soft hulls or density contours |
| V7-C003 | Edge bundling lite | TODO | high-level edges aggregate by cluster at low zoom |
| V7-C004 | Labels engine | TODO | label collision avoidance and priority labels |
| V7-C005 | Selection neighborhood | TODO | click node highlights 1-hop/2-hop without redrawing everything |
| V7-C006 | Search/filter overlay | TODO | text filter updates RenderPlan and visual state |
| V7-C007 | Mini-map | TODO | small overview map supports fast navigation |
| V7-C008 | Color themes | TODO | readable light/dark styles, no hardcoded single palette |
| TEST-V7-C | Visual behavior tests | TODO | selection/filter/label policies have deterministic snapshots |

Design direction:

- Use calm dark technical-map aesthetic for high-load mode.
- Use color sparingly: people, diaries, backbone, active selection.
- Edges should be subtle by default; selected local structure should pop.
- Labels are a reward for zooming in, not a permanent tax.
- Health/degradation UI should be visible but not noisy.

## Milestone V7-D: Off-Main-Thread Rendering

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-D001 | Worker protocol | TODO | main thread sends camera/profile/input events, worker returns draw batches |
| V7-D002 | OffscreenCanvas probe | TODO | use OffscreenCanvas when available, Canvas fallback otherwise |
| V7-D003 | Transfer typed arrays | TODO | graph arrays transferred/shared without JSON copies |
| V7-D004 | Worker scheduler | TODO | stale frames cancelled before draw |
| V7-D005 | Main-thread input shell | TODO | pointer/wheel handling stays responsive under render load |
| TEST-V7-D | Worker tests | TODO | stale-frame cancellation and fallback path are covered |

Fallback strategy:

- If OffscreenCanvas works: worker owns drawing.
- If not: worker computes visible batches, main thread draws small chunks.
- If worker fails: use current Canvas MVP path with degraded mode.

## Milestone V7-E: WebGL Renderer Option

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-E001 | WebGL capability probe | TODO | plugin detects WebGL2 and falls back safely |
| V7-E002 | Node point renderer | TODO | nodes drawn through GPU buffers |
| V7-E003 | Edge line renderer | TODO | visible edges drawn through GPU buffers |
| V7-E004 | Instanced attributes | TODO | node type/color/size/alpha are buffer attributes |
| V7-E005 | GPU picking map | TODO | hover/click uses color picking or CPU spatial fallback |
| V7-E006 | WebGL health metrics | TODO | GPU mode reports buffer size, draw calls, frame time |
| TEST-V7-E | WebGL fallback tests | TODO | no-WebGL path still works |

Priority:

- Do not start WebGL until real-data Canvas renderer is stable.
- WebGL should be optional, not a hard dependency.
- WebGL target is 50K-100K overview, not fancy effects first.

## Milestone V7-F: Storage Schema v7

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-F001 | Schema v7 manifest | TODO | manifest declares capabilities, files, versions, layout status |
| V7-F002 | Column groups | TODO | node, edge, layout, search, cluster indexes are independent groups |
| V7-F003 | Stable node IDs | TODO | unchanged files keep stable node IDs across rebuilds |
| V7-F004 | Tombstones | TODO | deleted notes are tracked until compaction |
| V7-F005 | Chunked binary files | TODO | large arrays split into shard files |
| V7-F006 | Compression policy | TODO | JSON/string tables optionally compressed; typed arrays stay direct-read friendly |
| V7-F007 | Store capability checks | TODO | renderer refuses incompatible store versions cleanly |
| TEST-V7-F | Schema migration tests | TODO | v6 store loads or migrates; corrupt groups recover |

Storage layout idea:

```text
.obsidian/graph-store/
  graph.manifest.json
  graph.journal.jsonl
  graph.current/
    manifest.json
    nodes/
      ids.u32
      type.u16
      flags.u32
      path.sid.u32
      basename.sid.u32
      mtime.f64
    edges/
      source.u32
      target.u32
      flags.u32
      weight.f32
    csr/
      out.offsets.u32
      out.targets.u32
      in.offsets.u32
      in.sources.u32
    layout/
      x.f32
      y.f32
      pinned.u8
      version.json
    indexes/
      cluster.u32
      tags.sid.u32
      properties.json
      spatial.grid.bin
    strings/
      strings.json
```

## Milestone V7-G: Incremental Indexing

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-G001 | File fingerprint table | TODO | path, mtime, size, content hash saved |
| V7-G002 | Changed-file detector | TODO | indexer computes added/changed/deleted sets |
| V7-G003 | Incremental node update | TODO | one changed note updates one node row |
| V7-G004 | Incremental edge update | TODO | source note edge range replaced without full rebuild |
| V7-G005 | Append-only journal | TODO | journal records updates and can replay |
| V7-G006 | Background compaction | TODO | fragmented edge/node data compacted when idle |
| V7-G007 | Atomic incremental commit | TODO | current store swaps only after validation |
| TEST-V7-G | Incremental tests | TODO | add/change/delete note, recover interrupted update |

Acceptance:

- Changing one diary note should not rebuild all `33,900` files.
- Incremental update must preserve stable IDs and layout positions.
- If incremental update fails, previous store remains active.

## Milestone V7-H: Query Indexes

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-H001 | Tag index | TODO | `tag:#graph/backbone` and future filters resolve without scanning text |
| V7-H002 | Path prefix index | TODO | diary/year/month filters resolve fast |
| V7-H003 | Type index | TODO | people/diary/system node queries resolve fast |
| V7-H004 | Property index | TODO | frontmatter properties are queryable |
| V7-H005 | Full-text-lite index | TODO | simple basename/title search for graph UI |
| V7-H006 | Query planner | TODO | query compiles to node bitset before RenderPlan |
| TEST-V7-H | Query tests | TODO | filters produce stable bitsets and stay inside budget |

RenderPlan should receive:

- `visibleCandidateBitset`
- `excludedBitset`
- `priorityNodeIds`
- `edgePolicy`
- `labelPolicy`
- `camera`
- `budget`

That keeps renderer dumb and fast.

## Milestone V7-I: Layout Storage + Layout Engine

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-I001 | Persisted layout metadata | TODO | layout version, algorithm, seed, bounds saved |
| V7-I002 | Incremental layout stability | TODO | changed notes do not reshuffle whole graph |
| V7-I003 | Cluster-aware initial layout | TODO | diaries by year/month, people by group, backbone ring |
| V7-I004 | Worker force pass | TODO | optional background layout refinement in worker |
| V7-I005 | Pinned/manual positions | TODO | user-pinned nodes survive rebuild |
| V7-I006 | Layout quality metrics | TODO | overlap, edge length, cluster spread measured |
| TEST-V7-I | Layout tests | TODO | deterministic layout and stable IDs preserve positions |

Visual result:

- Overview should look like an atlas, not a hairball.
- Diary years/months should form readable zones.
- People should form a separate but connected social region.
- Backbone should remain a navigational skeleton.

## Milestone V7-J: Cache + Memory Management

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-J001 | Array cache manager | TODO | loads only arrays needed for current renderer mode |
| V7-J002 | LRU for string tables | TODO | labels load on demand and evict under pressure |
| V7-J003 | Memory pressure detector | TODO | renderer enters memory-pressure mode before crash |
| V7-J004 | Store warmup policy | TODO | startup loads manifest first, arrays lazily |
| V7-J005 | Binary read batching | TODO | grouped reads avoid many tiny adapter calls |
| TEST-V7-J | Memory tests | TODO | synthetic pressure triggers degraded mode |

Important:

- Never parse large JSON on the hot path.
- String labels are cold data.
- Typed arrays are hot data.
- Label rendering waits until idle/zoomed.

## Milestone V7-K: Visual QA + Benchmarks

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-K001 | Renderer benchmark command | TODO | reports FPS proxy, draw calls, visible nodes/edges |
| V7-K002 | Storage benchmark command | TODO | reports full rebuild, incremental update, compaction |
| V7-K003 | Golden RenderPlan fixtures | TODO | deterministic temp graph fixtures checked into tests |
| V7-K004 | Visual smoke harness | TODO | headless canvas mock validates pass order |
| V7-K005 | Stress matrix | TODO | 20K, 50K synthetic, 100K synthetic benchmarks |
| V7-K006 | Regression budget gates | TODO | tests fail if RenderPlan/storage exceed thresholds |
| TEST-V7-K | Benchmark tests | TODO | benchmark JSON schema and pass/fail behavior covered |

Benchmark commands should produce JSON only by default, so results can be compared over time.

## Milestone V7-L: UX Control Surface

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V7-L001 | Graph command palette | TODO | open ultra graph, rebuild store, benchmark, repair |
| V7-L002 | Renderer mode switch | TODO | Auto, Canvas, WebGL, Safe Native |
| V7-L003 | Quality slider | TODO | Performance, Balanced, Detail profiles |
| V7-L004 | Filter presets | TODO | Backbone, People, Current Year, Diaries, Selection |
| V7-L005 | Health details drawer | TODO | shows reason for degraded mode and suggested fix |
| V7-L006 | Store repair button | TODO | rebuilds temp/next store then atomically swaps |
| TEST-V7-L | UX command tests | TODO | commands call correct repair/build/profile flows |

## Risk Register

| ID | Risk | Mitigation |
| --- | --- | --- |
| R-V7-001 | Canvas 2D caps out before 50K | Keep WebGL as optional milestone after real-data Canvas |
| R-V7-002 | Obsidian adapter binary reads are slow | Batch reads, lazy-load arrays, keep manifest tiny |
| R-V7-003 | Incremental index complexity causes corruption | Journal + previous snapshot + tests for interrupted update |
| R-V7-004 | Visual design becomes noisy | Enforce zoom-level visual policy and label budgets |
| R-V7-005 | Worker/OffscreenCanvas compatibility varies | Feature probe and fallback to main-thread chunked Canvas |
| R-V7-006 | Storage schema migration breaks old stores | Store capability checks and v6 compatibility loader |

## Suggested Execution Order

1. V7-A: make Ultra Graph render real Graph Store data.
2. V7-B: add viewport culling, spatial index, progressive visual passes.
3. V7-F/G: upgrade storage schema and incremental indexing.
4. V7-H/I: query indexes and stable layout storage.
5. V7-D: move compute/draw prep off main thread.
6. V7-C/L: improve visual polish and UX controls.
7. V7-E: add WebGL only after Canvas real-data path is reliable.
8. V7-K: lock performance with benchmark gates.

## First Implementation Slice

Smallest high-impact slice:

| ID | Task | Why First |
| --- | --- | --- |
| V7-A001 | Plugin-side Graph Store client | unlocks real data rendering |
| V7-A002 | Real node layout rendering | removes synthetic limitation |
| V7-B002 | Viewport culling | immediate FPS improvement |
| V7-B005 | Adaptive edge pass | removes most visible interaction stalls |
| V7-K001 | Renderer benchmark command | proves whether visual changes work |

Expected result after first slice:

- Ultra Graph opens real `Calendula-20K` nodes.
- Pan/zoom remains responsive because visible nodes are capped by viewport and budget.
- Edges fade/refine after interaction instead of blocking input.
- We get a benchmark JSON before/after every renderer change.
