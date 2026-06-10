# Resilient Graph Platform v6 Backlog

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Milestone 1: Safe Native + Profile Policy

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| GP-A001 | Startup profile is always `fast-backbone` | DONE | `graph.json.search` is non-empty, safe physics are applied, tests pass |
| GP-A002 | Workspace safety repair | DONE | one graph leaf, no heavy panes, safe active leaf |
| GP-A003 | Guard quarantine mode | DONE | drift detection repairs graph/workspace and logs incident |
| GP-B001 | Profile schema v6 | DONE | profiles are policy objects with graph settings and budgets |
| GP-B002 | Profile validator | DONE | unsafe startup/full-danger profiles are rejected |
| GP-B003 | Profile switcher | DONE | offline switcher validates profiles and repairs workspace |
| TEST-M001 | Safe startup tests | DONE | Pester verifies profile, workspace, guard, drift policy |

## Milestone 2: Graph Store MVP

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| GP-C001 | Atomic graph store MVP | DONE | `graph.current`, `graph.previous`, `graph.next`, manifest, journal |
| GP-C002 | Manifest schema | DONE | manifest contains schema, stats, files, checksums |
| GP-D001 | Forward CSR | DONE | outgoing adjacency can be queried without scanning all edges |
| GP-D002 | Reverse CSR | DONE | incoming adjacency mirrors forward edge count |
| TEST-M003 | Index tests | DONE | build/load/corrupt-current/recover cases |

## Milestone 3: Query + RenderPlan

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| GP-E001 | Separate graph layers | DONE | Vault/Indexed/Query/Visible/Render graph boundaries documented and coded |
| GP-E002 | Immutable RenderPlan | DONE | renderer receives typed arrays and cannot expand plan |
| GP-E003 | LOD selector | DONE | LOD 0-4 selected from zoom/profile/budget |
| GP-F001 | Frame scheduler | DONE | pan/zoom cancels low-priority work |

## Milestone 4+: Renderer, Resilience, Ops

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| GP-I001 | Canvas Ultra Graph MVP | DONE | 20K synthetic nodes, pan/zoom, FPS counter |
| GP-J001 | Degraded modes | DONE | overload enters controlled mode |
| GP-K001 | Graph Health panel | DONE | metrics and degradation reasons visible |
| GP-L001 | Vault safety policy | DONE | no destructive/mass edit without dry-run/confirmation |

## Milestone 5: Benchmark + Handoff

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| GP-M001 | Repeatable performance benchmark | DONE | temp-store benchmark validates graph store, render plan, scheduler, and outputs JSON |
| TEST-M005 | Benchmark and safety tests | DONE | Pester covers safety policy and benchmark wrapper |

## Active Next Plan

The next active plan is `v9 Critical Path Graph Platform`.

| ID | Task | Status | Done Criteria |
| --- | --- | --- | --- |
| V9-S1 | Critical Real Frame | TODO | real nodes appear from Graph Store with no strings, no labels, no uncaught store errors, and aggregate FrameStats |
| V9-0 | Minimal hot-path contracts | TODO | GraphStoreClient, GraphSnapshot, RenderPlan, RenderBackend, FrameStats, FailureState |
| V9-1 | Shallow validation and real node draw | TODO | manifest, files, counts, x/y/type/flags, visible set, CanvasBackend |
| V9-2 | Governors and state machine | TODO | FrameGovernor, MemoryGovernor, IOGovernor, transition cooldowns, recovery, aggregate reasons |
| V9-3 | Deep validation and store compatibility | TODO | idle deep scan, compatibility matrix, migration policy, previous-store recovery |
