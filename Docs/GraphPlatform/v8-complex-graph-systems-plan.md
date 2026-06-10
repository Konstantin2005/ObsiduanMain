# Resilient Graph Platform v8: Superseded

This document is intentionally kept as a pointer, not as the active plan.

The v8 `Complex Graph Systems Plan` was useful because it identified the right system boundaries: store contracts, query planning, degradation, backend isolation, lineage, observability, and multi-scale graph assumptions.

But v8 started from too many abstractions at once. It was architecturally correct, but too wide for the next production slice.

The active plan is now:

- [v9-critical-path-graph-platform.md](v9-critical-path-graph-platform.md)

## Replacement Rule

Do not continue implementation from the old v8 task list.

Use v9 instead:

```txt
Not Contract First.
Critical Path First, Contracted.
```

## Why v8 Was Replaced

v8 was good for:

- naming failure domains;
- insisting on backend isolation;
- adding benchmark and reason-code discipline;
- protecting the renderer from graph complexity;
- identifying future query, worker, and WebGL gates.

v8 was not good enough for:

- protecting the first real frame;
- keeping contracts minimal;
- separating hot path from cold path;
- preventing lineage and reason codes from becoming graph-sized allocations;
- deferring WebGL, workers, multi-scale, and full query algebra until real rendering is proven.

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

Done means:

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
