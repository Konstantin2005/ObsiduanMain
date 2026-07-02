# Rendering Scripts

This folder contains JavaScript modules that directly shape graph rendering.

## Contents

- `graph-critical-frame.js` - first-frame snapshot loading, critical RenderPlan, Canvas backend, frame stats.
- `graph-render-plan.js` - higher-level RenderPlan policy, LOD, memory pressure, query and scale integration.
- `graph-renderer-upgrade.js` - Canvas/WebGL upgrade gate and renderer bottleneck decision logic.
- `graph-scheduler.js` - render backpressure detection and frame budget adaptation.
- `live-graph/live-graph-core.js` - canonical live graph plugin entrypoint wrapper.
- `live-graph/builtin-graph.js` - actual live graph plugin implementation.

## Boundary

- Rendering code may consume graph store/query contracts.
- Rendering code should not parse vault markdown directly on the hot render path.
- Obsidian plugin `main.js` files stay inside `.obsidian/plugins` as thin entrypoints.
