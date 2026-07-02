# Performance Architecture: 20K–50K Node Graphs

**Version:** 1.0.0
**Issue:** #99 — "2 Мега Таска: Производительность графа 20K-50K+"
**Date:** 2026-06-25

---

## 1. Bottleneck Analysis

### 1.1 Identified Bottlenecks for 20K–50K Nodes

| # | Bottleneck | Location | Impact | Current Mitigation |
|---|-----------|----------|--------|-------------------|
| B1 | Full vault traversal in render loop | `graph-critical-frame.js:484` — `buildCriticalRenderPlan` iterates all nodes | O(n) per frame → 16–48ms at 50K | No — full scan exists |
| B2 | Edge scan on every frame | `graph-critical-frame.js:560-575` — edge selection scans all edges | O(e) per frame, e ~200K–500K at 50K | CSR index reduces scan |
| B3 | Synchronous manifest and array load | `graph-critical-frame.js:283-305` — `loadSnapshot` blocks UI thread | I/O blocking 5–50ms at 50K | No — synchronous `fs` calls |
| B4 | No persistent layout cache | `graph-multiscale.js` — multi-scale model rebuilt every query | CPU 10–100ms per rebuild | No — always fresh computation |
| B5 | No people graph precompute | People edge computation not cached | Repeated CPU on every frame | No |
| B6 | No worker pool for graph queries | `graph-worker-layer.js` — WorkerTaskController uses async, not true workers | UI thread does heavy work | `useWorker=false` by default |
| B7 | No CPU governor scaling | `graph-throughput-governor.js` — exists but not wired to Obsidian plugin | No dynamic throttling | Policy exists, not enforced |
| B8 | Shard storage grows unbounded | No compaction pipeline | Disk bloat, slow loads | No |
| B9 | Pan/zoom triggers full rerender | No progressive LOD for camera motion | Jank under interaction | Partial LOD exists |
| B10 | No benchmark regression gate | No CI benchmark comparison | Performance regressions undetected | Ad-hoc `measure-*.js` scripts |

### 1.2 Scale Impact Matrix

| Operation | 5K nodes | 20K nodes | 50K nodes | Scaling factor |
|-----------|----------|-----------|-----------|---------------|
| Full vault scan | 2ms | 8ms | 20ms | O(n) |
| Edge batch (all) | 5ms | 25ms | 60ms | O(e) |
| Manifest load | 1ms | 4ms | 10ms | O(n) |
| Multi-scale build | 3ms | 12ms | 35ms | O(n log n) |
| Render plan | 4ms | 18ms | 45ms | O(n + e) |
| **Total frame time** | **~15ms** | **~67ms** | **~170ms** | — |

**Target:** <16ms per frame (60fps) at 50K nodes.

---

## 2. Thread Architecture

### 2.1 Operation Distribution

```
┌─────────────────────────────────────────────────────────┐
│                    UI THREAD (main)                      │
│  Budget: <2ms JS + <14ms draw = <16ms total             │
│                                                          │
│  +-------+  +--------+  +----------+  +----------+      │
│  │Camera │  │Gesture │  │ Viewport │  │ Frame    │      │
│  │Input  │  │Handler │  │ Culling  │  │ Governor │      │
│  +-------+  +--------+  +----------+  +----------+      │
│       │          │            │              │           │
│       └──────────┴────────────┴──────────────┘           │
│                        │                                 │
│                        ▼                                 │
│              ┌─────────────────┐                         │
│              │  Render Backend │  Canvas 2D / WebGL      │
│              │  (draw only)    │                         │
│              └─────────────────┘                         │
└──────────────────────────────────────────────────────────┘
         │ transferControl / postMessage
         ▼
┌─────────────────────────────────────────────────────────┐
│                  WORKER POOL (2-8 workers)                │
│  Responsibilities:                                       │
│  - Graph query planning                                   │
│  - Layout computation                                     │
│  - Edge batch selection                                   │
│  - Multi-scale model building                             │
│  - Incremental index diff                                 │
│                                                          │
│  +----------+  +----------+  +------------------------+  │
│  │Query     │  │Layout    │  │Edge Batch              │  │
│  │Worker #1 │  │Worker #2 │  │Worker #3 (progressive) │  │
│  +----------+  +----------+  +------------------------+  │
└──────────────────────────────────────────────────────────┘
         │ IPC / shared memory (SharedArrayBuffer)
         ▼
┌─────────────────────────────────────────────────────────┐
│                BACKGROUND JOBS (idle priority)            │
│  Responsibilities:                                       │
│  - People graph cache rebuild                             │
│  - Shard compaction                                       │
│  - Manifest recovery                                      │
│  - Deep validation                                        │
│  - Benchmark collection                                   │
│                                                          │
│  Scheduled via:                                          │
│  - requestIdleCallback                                    │
│  - BackgroundTaskScheduler (custom)                      │
└──────────────────────────────────────────────────────────┘
```

### 2.2 Thread Assignment Table

| Operation | Thread | Priority | Budget | Mechanism |
|-----------|--------|----------|--------|-----------|
| Camera input → viewport | UI | Critical | <1ms | Event → frustum update |
| Gesture processing | UI | Critical | <2ms | requestAnimationFrame |
| Canvas draw | UI | Critical | <14ms | Canvas 2D / WebGL |
| Graph query planning | Worker | High | <8ms | postMessage → worker |
| Layout computation | Worker | High | <16ms | postMessage → worker |
| Edge batch selection | Worker | Medium | <8ms | Progressive via budget |
| Multi-scale model | Worker | Medium | <4ms | Cached, rebuild on change |
| Incremental index diff | Worker | Medium | <50ms | Background schedule |
| People graph cache | Background | Low | <500ms | requestIdleCallback |
| Shard compaction | Background | Low | <2000ms | BackgroundTaskScheduler |
| Manifest recovery | Background | Low | <1000ms | BackgroundTaskScheduler |
| Deep validation | Background | Low | <200ms | BackgroundTaskScheduler |
| Benchmark collection | Background | Lowest | <100ms | On idle |

---

## 3. Caching Architecture

### 3.1 Multi-Level Cache Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    L1: Render Frame Cache                    │
│  TTL: 1 frame | Size: variable | Eviction: per frame        │
│  Contents: render plan, visible node/edge arrays             │
│  Invalidated: every frame (ephemeral)                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                    L2: Layout Cache                           │
│  TTL: until layout change | Size: ~8MB at 50K                │
│  Contents: layout X/Y, cluster assignments, backbone mask    │
│  Key: `layoutVersion` from manifest                          │
│  Invalidated: on layout recomputation                        │
│  Storage: SharedArrayBuffer (shared between UI + Workers)    │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                    L3: Multi-Scale Index                      │
│  TTL: ~30s or until graph change | Size: ~4MB at 50K        │
│  Contents: domain overview, spatial clusters, backbone nodes │
│            important nodes (by degree), ego neighborhoods   │
│  Key: `buildId` from snapshot manifest                       │
│  Invalidated: incremental update hook                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                    L4: People Graph Cache                     │
│  TTL: ~5min or on file change | Size: ~2MB at 10K people    │
│  Contents: precomputed people edges (co-mention, wiki-links) │
│  Key: `peopleCacheVersion`                                   │
│  Invalidated: background job on file change detection        │
│  Storage: serialized typed arrays                            │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 Cache Invalidation Protocol

```
┌──────────┐     file change     ┌──────────────┐
│ Vault FS ├──────────────────►  │ Change       │
└──────────┘                     │ Detector     │
                                 │ (chokidar)   │
                                 └──────┬───────┘
                                        │ changed paths
                                        ▼
                                 ┌──────────────┐
                                 │ Trust         │────► L4 People cache invalidated
                                 │ Classifier    │      for changed files
                                 │ (index-comp.) │
                                 └──────┬───────┘
                                        │ trust decision
                                        │ (REUSE / READ_AND_PARSE / ...)
                                        ▼
                                 ┌──────────────┐
                                 │ Incremental   │────► L2 Layout: skip if no
                                 │ Index Update  │      layout-impacting changes
                                 └──────┬───────┘
                                        │ new snapshot
                                        ▼
                                 ┌──────────────┐
                                 │ Snapshot      │────► L3 Multi-Scale: rebuild
                                 │ Publisher     │      if node count/edges changed
                                 └──────┬───────┘
                                        │ publish event
                                        ▼
                                 ┌──────────────┐
                                 │ Frame         │────► L1: next frame reads new snapshot
                                 │ Scheduler     │
                                 └──────────────┘
```

### 3.3 Cache Key Design

```javascript
// L2 Layout Cache key
{
  layoutVersion: manifest.layoutVersion,    // increments on layout change
  nodeCount: manifest.stats.nodes,           // for validation
}

// L3 Multi-Scale Index key
{
  buildId: manifest.buildId,                // unique per snapshot build
  schemaVersion: manifest.schemaVersion,
}

// L4 People Graph Cache key
{
  peopleCacheVersion: manifest.peopleCacheVersion,
  fileCount: manifest.stats.files,          // detect additions/deletions
  lastIndexedAt: manifest.stats.builtAt,    // detect staleness
}
```

---

## 4. Load Scheduler

### 4.1 Scheduler State Machine

```
                      ┌──────────┐
                      │  IDLE    │
                      └────┬─────┘
                           │ frame request
                           ▼
                      ┌──────────┐
              ┌──────►│  ACTIVE  │◄──────┐
              │       └────┬─────┘       │
              │            │              │
              │     ┌──────┴──────┐       │
              │     │  backpressure?      │
              │     └──────┬──────┘       │
              │            │              │
              │      ┌─────┴─────┐        │
              │      ▼           ▼        │
              │ ┌────────┐ ┌────────┐     │
              │ │DEGRADED│ │BROWNOUT│     │
              │ └───┬────┘ └───┬────┘     │
              │     │          │          │
              │     └─────┬────┘          │
              │           ▼               │
              │      ┌──────────┐         │
              │      │ EMERGENCY│         │
              │      └────┬─────┘         │
              │           │ recovery      │
              └───────────┘               │
         ┌────────────────────────────────┘
         │ frame done
         ▼
     ┌──────────┐
     │  POST     │──► schedule background work
     │  FRAME    │
     └──────────┘
```

### 4.2 Priority Queue Model

```
Priority 0 (CRITICAL):
  - Camera input processing
  - Frame render command
  - Canvas draw

Priority 1 (HIGH):
  - Graph query plan (for visible area)
  - Layout calculation for visible nodes
  - Edge batch for visible nodes

Priority 2 (MEDIUM):
  - Multi-scale model update
  - Incremental index update
  - Edge batch for off-screen neighbors

Priority 3 (LOW):
  - People graph cache rebuild
  - Deep validation

Priority 4 (IDLE):
  - Shard compaction
  - Manifest recovery
  - Benchmark data collection
  - Historical metrics export
```

### 4.3 Adaptive Profile Selection

```javascript
// Adaptive profile table for scheduler
const ADAPTIVE_PROFILES = {
  // Mode: { maxVisibleNodes, maxVisibleEdges, labelPolicy, edgePolicy, lodPolicy, workerCount }
  interactive:    { maxVisibleNodes: 3000,  maxVisibleEdges: 5000,  labelPolicy: "selected", edgePolicy: "backbone+local", lodPolicy: "aggressive",  workerCount: 1 },
  degraded:       { maxVisibleNodes: 1500,  maxVisibleEdges: 1500,  labelPolicy: "none",     edgePolicy: "backbone",     lodPolicy: "aggressive",  workerCount: 1 },
  brownout:       { maxVisibleNodes: 500,   maxVisibleEdges: 500,   labelPolicy: "none",     edgePolicy: "backbone",     lodPolicy: "native-safe", workerCount: 0 },
  emergency:      { maxVisibleNodes: 200,   maxVisibleEdges: 100,   labelPolicy: "none",     edgePolicy: "backbone",     lodPolicy: "native-safe", workerCount: 0 },
  memoryPressure: { maxVisibleNodes: 500,   maxVisibleEdges: 0,     labelPolicy: "none",     edgePolicy: "none",         lodPolicy: "native-safe", workerCount: 0 },
  batterySaver:   { maxVisibleNodes: 1000,  maxVisibleEdges: 1000,  labelPolicy: "none",     edgePolicy: "backbone",     lodPolicy: "native-safe", workerCount: 1 },
};
```

### 4.4 Load Scheduler API

```
┌──────────────────────────────────────────────────────────┐
│                   GraphLoadScheduler                      │
│                                                          │
│  - scheduleFrame(input) → FrameDecision                  │
│  - scheduleBackground(task, priority) → TaskHandle       │
│  - getResourceProfile() → ResourceProfile                │
│  - observeMetrics(metrics) → void                        │
│  - getCurrentMode() → "interactive" | "degraded" | ...   │
│                                                          │
│  Input signals:                                          │
│    - frameDurationMs (p50/p95/p99)                       │
│    - eventLoopDelayMs                                    │
│    - memoryUsageRatio                                    │
│    - workerResponseTimeMs                                │
│    - pointerEventsPerSecond                              │
│    - isBatteryPowered                                    │
│    - isWindowFocused                                     │
│                                                          │
│  Output decisions:                                       │
│    - mode: adaptive profile name                         │
│    - workerCount: 0..N                                  │
│    - actions: ["drop-stale-frames", "pause-io", ...]     │
│    - budgets: { nodes, edges, labels }                   │
└──────────────────────────────────────────────────────────┘
```

---

## 5. Performance Benchmark Harness

### 5.1 Benchmark Suites

| Suite | Scope | Metrics | Cadence |
|-------|-------|---------|---------|
| **Frame Budget** | Render pipeline | p50/p95/p99 frame ms, node/edge draw count, budget exceed rate | Every commit |
| **Query Planning** | Query engine | query plan ms, candidate count, filter selectivity | Every commit |
| **Layout Compute** | Layout engine | layout ms, memory delta | Nightly |
| **Index Build** | Incremental index | full/incr build ms, read amplification, reuse ratio | Nightly |
| **People Graph** | People cache | cache rebuild ms, cache hit ratio, edge quality | Nightly |
| **Memory** | Whole system | snapshot bytes, typed array overhead, GC pressure | Weekly |
| **Regression** | Cross-suite delta | Δ from baseline, trend detection | Daily |

### 5.2 Benchmark Runner Architecture

```
┌──────────────────────────────────────────────┐
│            Benchmark Orchestrator              │
│                                               │
│  1. Select suite(s) based on trigger           │
│  2. Load baseline from ./benchmark/baseline    │
│  3. Run warmup (3 iterations)                  │
│  4. Run measured (10 iterations)               │
│  5. Collect metrics                            │
│  6. Compare vs baseline                        │
│  7. Determine pass/fail/regression             │
│  8. Store result in ./benchmark/results/       │
│  9. Update baseline if on main/develop         │
└──────────────────────────────────────────────┘
```

### 5.3 Benchmark Configuration

```json
{
  "suites": {
    "frame-budget": {
      "scenarios": [
        {
          "name": "viewport-5k",
          "nodeCount": 5000,
          "edgeCount": 25000,
          "viewportZoom": 1.0,
          "iterations": 10,
          "warmup": 3,
          "thresholdMs": { "p95": 16, "p99": 24 }
        },
        {
          "name": "viewport-20k",
          "nodeCount": 20000,
          "edgeCount": 100000,
          "viewportZoom": 0.5,
          "iterations": 10,
          "warmup": 3,
          "thresholdMs": { "p95": 16, "p99": 24 }
        },
        {
          "name": "viewport-50k",
          "nodeCount": 50000,
          "edgeCount": 250000,
          "viewportZoom": 0.3,
          "iterations": 10,
          "warmup": 3,
          "thresholdMs": { "p95": 16, "p99": 32 }
        }
      ],
      "metrics": ["frameMs", "planMs", "drawMs", "nodeCount", "edgeCount", "skipReasons"]
    },
    "regression-gate": {
      "maxDeltaPercent": 15,
      "alertOnFailure": true,
      "autoRollback": false
    }
  }
}
```

### 5.4 CI Integration (GitHub Actions)

```yaml
# .github/workflows/benchmark.yml
name: Graph Performance Benchmark
on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [main]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: node Technical/Scripts/Obsidian/measure-graph-benchmark.js --suite all
      - if: failure()
        run: |
          echo "Performance regression detected!"
          echo "See benchmark/results/${{ github.sha }}.json"
```

### 5.5 KPI Dashboard

| KPI | Target | Warning | Critical | Measurement |
|-----|--------|---------|----------|-------------|
| Frame p95 (50K) | <16ms | >20ms | >32ms | `GraphScheduler.getFrameHistory().p95FrameMs` |
| Frame p99 (50K) | <24ms | >32ms | >48ms | `GraphScheduler` |
| Render plan build | <8ms | >12ms | >20ms | `RenderPlan.timingsMs.renderPlan` |
| Worker response | <50ms | >100ms | >250ms | `graph-worker-layer.js` |
| Memory: snapshot | <256MB | >384MB | >512MB | `MemoryGovernor.snapshotBytes` |
| Memory: total RSS | <512MB | >768MB | >1024MB | `process.memoryUsage.rss` |
| Index build (incr) | <2s | >5s | >10s | `graph-build-runtime.js` |
| Index reuse ratio | >90% | <80% | <60% | `IndexOperationLog` |
| People cache hit | >80% | <60% | <40% | `people-cache.js` |
| Layout cache hit | >90% | <75% | <50% | `layout-cache.js` |

---

## 6. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RENDER LOOP (per frame)                       │
│                                                                      │
│  ┌────────┐   ┌───────────┐   ┌────────────┐   ┌───────────────┐   │
│  │Camera  │──►│Viewport   │──►│Worker Query│──►│Layout Lookup  │   │
│  │Input   │   │Frustum    │   │(pool)      │   │(L2 cache hit?)│   │
│  └────────┘   └───────────┘   └─────┬──────┘   └───────┬───────┘   │
│                                      │                  │           │
│                            ┌─────────▼─────┐   ┌───────▼───────┐   │
│                            │CACHE MISS:    │   │CACHE HIT:     │   │
│                            │Query Plan     │   │Use cached     │   │
│                            │→ Worker Pool  │   │layout arrays  │   │
│                            └───────┬───────┘   └───────┬───────┘   │
│                                    │                   │           │
│                                    ▼                   ▼           │
│                            ┌─────────────────────────────────┐     │
│                            │     Edge Batch Selection        │     │
│                            │  Progressive via budget         │     │
│                            └─────────────┬───────────────────┘     │
│                                          │                         │
│                                          ▼                         │
│                            ┌─────────────────────────────────┐     │
│                            │     Canvas Draw (WebGL/2D)      │     │
│                            │  Budget: <14ms                  │     │
│                            └─────────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                              │ post-frame
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    POST-FRAME BACKGROUND WORK                         │
│                                                                       │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────────────┐   │
│  │Incremental     │  │People Graph  │  │Shard Compaction /      │   │
│  │Index Update    │  │Cache Rebuild │  │Manifest Recovery       │   │
│  └────────────────┘  └──────────────┘  └────────────────────────┘   │
│                                                                       │
│  All scheduled via BackgroundTaskScheduler with priority + budget    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Week 1)

**Goal:** Wire existing governors into Obsidian plugin, fix full vault traversal

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #17 | Remove full vault traversal from render loop | `graph-critical-frame.js:484` — replace `for (index=0..nodeCount)` with CSR-based neighbor walk | 3h |
| #25 | Wire GraphScheduler into Live Graph plugin | `builtin-graph.js` + `graph-scheduler.js` — connect frame timing to scheduler | 4h |
| #26 | Wire ThroughputGovernor | `builtin-graph.js` + `graph-throughput-governor.js` — connect SLA monitoring | 4h |
| — | Port governors to browser environment (remove `os`, `fs` deps) | all governor files | 6h |

**Deliverable:** First frame with adaptive budget at 20K nodes. Bench: 5K runs at 60fps.

### Phase 2: Worker Pool (Week 2)

**Goal:** Move query planning and layout to Web Workers

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #11 | Implement true Web Worker pool | New: `graph-worker-pool.js`, `graph-worker-entry.js` | 8h |
| #11 | Move query plan to worker | `graph-query-engine.js` — run in worker | 3h |
| #11 | Move edge batch to worker | `graph-worker-layer.js` — use real postMessage | 3h |
| — | SharedArrayBuffer for snapshot arrays | Transfer typed arrays via `postMessage` with transferable | 4h |

**Deliverable:** Query + edge batch off UI thread. Bench: 20K at 60fps.

### Phase 3: Caching (Week 3)

**Goal:** Implement layout cache, people graph cache, progressive edge loading

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #12 | Persistent layout cache | New: `layout-cache.js` — L2 cache with layoutVersion key | 6h |
| #10 | Background people graph cache | New: `people-graph-cache.js` — scan + cache people edges in background | 8h |
| #13 | Progressive edge loading | `graph-render-plan.js` — load edges in priority batches | 4h |
| #25 | L3 multi-scale cache | `graph-multiscale.js` — cache + invalidate on buildId change | 4h |

**Deliverable:** 50K viewport at 30fps without cache, 50K at 60fps with warm cache.

### Phase 4: CPU Governor & Shard Compaction (Week 4)

**Goal:** Dynamic CPU throttling, storage compaction, manifest recovery

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #15 | Wire CPU governor to worker pool | `graph-throughput-governor.js` + `graph-worker-pool.js` | 6h |
| #16 | Shard compaction | New: `shard-compaction.js` — merge + compress old shards | 8h |
| #27 | Manifest recovery | `graph-critical-frame.js` — extend fallback chain + repair | 6h |
| — | BackgroundTaskScheduler | New: `background-task-scheduler.js` — idle-time scheduling | 4h |

**Deliverable:** Auto-throttling under pressure. 50K stable at 30fps minimum on low-end hardware (4GB RAM, integrated GPU).

### Phase 5: Smooth Interaction (Week 5)

**Goal:** Pan/zoom/selection remain smooth under load

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #18 | Gesture-optimized LoD switching | `graph-render-plan.js` — reduce node detail during gesture | 4h |
| #18 | Input burst detection + frame skip | `graph-scheduler.js` — detect >60 events/s, skip intermediate frames | 3h |
| — | Selection highlight without rerender | Overlay selection layer, reuse render plan | 3h |

**Deliverable:** Smooth 60fps pan/zoom at 50K with swipe.

### Phase 6: Benchmark & Regression (Week 6)

**Goal:** Comprehensive benchmark harness, CI integration, KPI dashboard

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #29 | Benchmark harness | New: `graph-benchmark.js` — suite runner, baseline, reporter | 8h |
| #29 | CI workflow | `.github/workflows/benchmark.yml` | 3h |
| #29 | KPI dashboard | New: `benchmark/dashboard.md` + badge generator | 4h |
| — | Performance regression gate | PR check: `Benchmark CI` must pass | 2h |

**Deliverable:** CI blocks PRs with >15% regression. Automated benchmark on every push to develop.

### Phase 7: Polish & Edge Cases (Week 7)

| Issue | Task | Files | Effort |
|-------|------|-------|--------|
| #4 | Sync benchmark settings | Align `graph-throughput-governor.js` thresholds with benchmark config | 3h |
| — | WebGL/OffscreenCanvas evaluation | `graph-renderer-upgrade.js` — run benchmark comparison | 4h |
| — | Low-end hardware tuning | Memory budget reduction, aggressive LoD for <4GB RAM | 4h |
| — | Error recovery hardening | Stabilize `graph-stability.js` fallback chain | 4h |

**Deliverable:** All 50K targets met. Documentation complete.

---

## 8. Performance KPIs (Acceptance Criteria)

### 8.1 Hard Requirements (must pass)

| KPI | 20K nodes | 50K nodes | Measurement |
|-----|-----------|-----------|-------------|
| Frame p95 | <16ms | <16ms | `GraphScheduler` |
| Frame p99 | <24ms | <32ms | `GraphScheduler` |
| Input latency | <50ms | <100ms | `ThroughputGovernor` |
| Snapshot memory | <128MB | <256MB | `MemoryGovernor` |
| Index build (incr) | <1s | <3s | `graph-build-runtime` |
| Index reuse ratio | >90% | >85% | `IndexOperationLog` |
| Cold start (load) | <500ms | <1000ms | `GraphStoreClient` |

### 8.2 Soft Requirements (target)

| KPI | 20K nodes | 50K nodes | Measurement |
|-----|-----------|-----------|-------------|
| Layout cache hit rate | >90% | >85% | `layout-cache.js` |
| People cache hit rate | >85% | >80% | `people-graph-cache.js` |
| Worker utilization | >60% | >70% | Worker pool stats |
| Frame budget exceed rate | <1% | <5% | `GraphScheduler` |

### 8.3 Resource Budget (max)

| Resource | Limit | When |
|----------|-------|------|
| Max workers | 8 | Background index |
| Max worker memory | 128MB each | SharedArrayBuffer pools |
| Max I/O chunk | 4MB | Index reads |
| Max in-flight bytes | 32MB | Concurrent reads |
| Max snapshot arrays | 256MB | All typed arrays combined |
| Max frame budget JS | <2ms | UI thread JS per frame |
| Max frame budget draw | <14ms | Canvas per frame |

---

## 9. Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| SharedArrayBuffer not available in Obsidian | High | High | Fallback to structured clone (postMessage) |
| Web Workers not available in Obsidian mobile | Medium | High | Run worker tasks as async on UI thread with strict budget |
| Memory fragmentation at 50K typed arrays | Medium | Medium | Use pool allocators, reuse arrays |
| File watcher chokidar CPU at 50K files | Medium | Low | Debounce + batch windows |
| WebGL context loss on resize/scrolling | Low | Medium | Auto-restore context, fallback to Canvas 2D |
| Benchmark flakiness on CI | Medium | Medium | 10-iteration median, outlier rejection |
