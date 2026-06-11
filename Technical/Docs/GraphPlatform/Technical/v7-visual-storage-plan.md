# Resilient Graph Platform v7: Superseded

This document is intentionally kept as a pointer, not as the active plan.

The v7 `Real Data First` plan was useful as a near-term sprint, but it was too narrow for the next system goal. It focused on making the real graph visible, but did not sufficiently protect the architecture against future complexity: storage evolution, query planning, render backend swapping, failure domains, data lineage, multi-scale graph models, and contract testing.

v8 improved the architecture, but became too abstract for the next implementation slice.

The active plan is now:

- [v9-critical-path-graph-platform.md](v9-critical-path-graph-platform.md)

## Replacement Rule

Do not continue implementation from the old v7 task list.

Use v9 instead:

```txt
Not Contract First.
Critical Path First, Contracted.
```

## Why v7 Was Replaced

v7 was good for:

- proving Ultra Graph can render real data;
- cutting premature WebGL/OffscreenCanvas/polish;
- defining a practical first slice.

v7 was not enough for:

- failure domains;
- hot/cold path separation;
- aggregate-only observability;
- shallow versus deep validation;
- backend isolation;
- stable first-frame budgets;
- contract tests.

## Active First Slice

The active first slice is `V9-S1 Critical Real Frame`:

```txt
1. GraphStoreClient catches all adapter errors.
2. Shallow manifest validation.
3. Load only x/y/type/flags.
4. Build visible set by camera bounds.
5. Create immutable RenderPlan.
6. Draw nodes through CanvasBackend.
7. Draw <= 1000 idle edges.
8. Emit aggregate FrameStats.
9. Missing/corrupt store enters FailureState.
10. Benchmark hot path budgets.
```
