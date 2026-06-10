# Resilient Graph Platform v7: Superseded

This document is intentionally kept as a pointer, not as the active plan.

The v7 `Real Data First` plan was useful as a near-term sprint, but it was too narrow for the next system goal. It focused on making the real graph visible, but did not sufficiently protect the architecture against future complexity: storage evolution, query planning, render backend swapping, failure domains, data lineage, multi-scale graph models, and contract testing.

The active plan is now:

- [v8-complex-graph-systems-plan.md](v8-complex-graph-systems-plan.md)

## Replacement Rule

Do not continue implementation from the old v7 task list.

Use v8 instead:

```txt
Real Data First.
Contract First.
Budget Always.
Fallback Everywhere.
Explain Every Skip.
Never Let Graph Complexity Leak Into Renderer.
```

## Why v7 Was Replaced

v7 was good for:

- proving Ultra Graph can render real data;
- cutting premature WebGL/OffscreenCanvas/polish;
- defining a practical first slice.

v7 was not enough for:

- failure domains;
- data lineage;
- query algebra;
- multi-scale graph assumptions;
- backend isolation;
- stable benchmark schemas;
- contract tests.

## Active First Slice

The active first slice is `V8-S1 Contracted Real Renderer`:

```txt
1. Define GraphStoreClient interface.
2. Define RenderBackend interface.
3. Define RenderPlan schema.
4. Define BudgetPolicy schema.
5. Load manifest.
6. Validate manifest + array lengths.
7. Load x/y/type/flags only.
8. Build viewport visible set.
9. Draw real nodes via CanvasBackend.
10. Draw max 2K idle edges.
11. Emit benchmark JSON.
12. Emit reason codes for skipped nodes/edges/labels.
13. Missing/corrupt store enters FailureState, not crash.
```
