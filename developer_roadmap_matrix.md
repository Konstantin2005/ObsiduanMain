# Developer Roadmap Matrix

## Stream A: Live Graph UX and Runtime Contract

| Issue | Topic | Owner Stream | Dependencies | PR Order |
|---|---|---|---|---|
| #24 | Unified Graph Runtime Contract | Stream A | None | 1 |
| #28 | Live Graph UX State Machine | Stream A | #24 | 2 |
| #1 | Improve plugin stability and interface | Stream A | #24, #28 | 3 |
| #5 | Add Stop and Restore controls | Stream A | #28 | 4 |
| #6 | Show cycle progress and remaining links | Stream A | #28 | 5 |
| #7 | Add journal, preview, and safe restore | Stream A | #5, #28 | 6 |

## Stream B: Performance, Workers, and Rendering

| Issue | Topic | Owner Stream | Dependencies | PR Order |
|---|---|---|---|---|
| #29 | Performance Benchmark Harness and Regression Gate | Stream B | None | 1 |
| #26 | Graph Performance Governor and Workload Scheduler | Stream B | #29, #24 | 2 |
| #15 | Add CPU and throughput load control | Stream B | #26, #29 | 3 |
| #20 | Add performance governor for CPU and throughput load | Stream B | #15, #26 | 4 |
| #11 | Move query/layout/relations work into worker pool | Stream B | #24, #26 | 5 |
| #22 | Worker-based planning for graph queries and layout | Stream B | #11, #24 | 6 |
| #12 | Cache graph layout for 20K-50K nodes | Stream B | #11, #24 | 7 |
| #13 | Gradual edge loading for dense people graph | Stream B | #11, #12 | 8 |
| #14 | Decide on WebGL/OffscreenCanvas by benchmark | Stream B | #29 | 9 |
| #17 | Remove full vault traversal from render loop | Stream B | #24, #11 | 10 |
| #18 | Protect pan/zoom/selection from lag | Stream B | #17, #26 | 11 |
| #23 | Remove full vault traversal from render hot path | Stream B | #17, #24 | 12 |

## Stream C: Storage, Indexing, and Incremental Updates

| Issue | Topic | Owner Stream | Dependencies | PR Order |
|---|---|---|---|---|
| #30 | Repository Source-of-Truth and Generated Artifacts Policy | Stream C | None | 1 |
| #3 | Reduce repo size and remove generated files | Stream C | #30 | 2 |
| #25 | Graph Change Detection and Incremental Update System | Stream C | #24 | 3 |
| #9 | Speed up graph updates without full rebuild | Stream C | #25 | 4 |
| #10 | Prepare people connections in background and cache | Stream C | #25, #24 | 5 |
| #16 | Compact shard storage and recover manifest | Stream C | #30, #24 | 6 |
| #21 | Storage compaction and manifest recovery | Stream C | #16, #30 | 7 |
| #27 | Graph Storage Integrity, Compaction and Recovery Framework | Stream C | #16, #21 | 8 |

## Stream D: Automation, Repo Hygiene, and Cross-Repo Discipline

| Issue | Topic | Owner Stream | Dependencies | PR Order |
|---|---|---|---|---|
| #2 | Keep one canonical Live Graph codebase | Stream D | #30 | 1 |
| #4 | Sync performance settings and benchmarks | Stream D | #29, #24 | 2 |
| #8 | Sync Obsidian with Discord | Stream D | #24 | 3 |
| #19 | Move remaining git automation into Technical | Stream D | #30 | 4 |
| #31 | Cross-Repo Documentation and Execution Log Discipline | Stream D | #30 | 5 |
| #33 | Develop roadmap: group and sequence all active tasks | Stream D | #24, #30 | 6 |

## Sequencing Rules

1. Runtime contract first, so other streams build on a stable boundary.
2. Benchmark harness before any governor or backend policy changes.
3. Storage/source-of-truth cleanup before deduping or compacting aggressively.
4. UX work can run in parallel with performance work once the contract is stable.
5. Verification and regression gates must land with or immediately after implementation.

## Suggested Ownership Split

- Developer A: Stream A + Stream D
- Developer B: Stream B + Stream C

## Notes

- This matrix assumes PR-only workflow.
- Every PR should close only the issues it directly implements.
- Verification issues should remain as gates, not cleanup work.
