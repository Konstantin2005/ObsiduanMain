const path = require("path");
const { performance } = require("perf_hooks");
const store = require("./build-calendula-graph-store.js");
const renderPlan = require("./graph-render-plan.js");
const { GraphScheduler } = require("./graph-scheduler.js");

function parseArgs(argv) {
  const args = {
    nodeBudget: 3000,
    edgeBudget: 5000,
    minimumNodes: 0,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--vault") {
      args.vaultRoot = path.resolve(value);
      i += 1;
    } else if (key === "--store") {
      args.storeRoot = path.resolve(value);
      i += 1;
    } else if (key === "--node-budget") {
      args.nodeBudget = Number(value);
      i += 1;
    } else if (key === "--edge-budget") {
      args.edgeBudget = Number(value);
      i += 1;
    } else if (key === "--minimum-nodes") {
      args.minimumNodes = Number(value);
      i += 1;
    }
  }
  if (!args.vaultRoot) throw new Error("Missing --vault");
  if (!args.storeRoot) throw new Error("Missing --store");
  return args;
}

function timed(fn) {
  const startedAt = performance.now();
  const value = fn();
  return {
    value,
    ms: Number((performance.now() - startedAt).toFixed(2)),
  };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const graphTimed = timed(() => store.buildGraph(args.vaultRoot));
  const manifestTimed = timed(() => store.writeStore(args.vaultRoot, args.storeRoot, graphTimed.value));
  const profile = {
    name: "benchmark",
    maxVisibleNodes: args.nodeBudget,
    maxVisibleEdges: args.edgeBudget,
    labelPolicy: "selected-only",
    lodPolicy: "aggressive",
  };
  const camera = { x: 0, y: 0, width: 100000, height: 100000, zoom: 1 };
  const planTimed = timed(() =>
    renderPlan.buildRenderPlan({
      storeRoot: args.storeRoot,
      profile,
      camera,
      frameId: 1,
    }),
  );
  const scheduler = new GraphScheduler();
  const scheduledTimed = timed(() => scheduler.scheduleFrame({ storeRoot: args.storeRoot, profile, camera }));
  const manifest = manifestTimed.value;
  const plan = planTimed.value;
  const scheduled = scheduledTimed.value;
  const ok =
    manifest.validation.ok &&
    manifest.stats.nodes >= args.minimumNodes &&
    manifest.stats.unresolved === 0 &&
    plan.nodes.length <= plan.budgets.nodeBudget &&
    plan.edges.length <= plan.budgets.edgeBudget;

  process.stdout.write(
    `${JSON.stringify(
      {
        ok,
        schemaVersion: manifest.schemaVersion,
        stats: manifest.stats,
        timingsMs: {
          buildGraph: graphTimed.ms,
          writeStore: manifestTimed.ms,
          renderPlan: planTimed.ms,
          scheduler: scheduledTimed.ms,
        },
        renderPlan: {
          mode: plan.mode,
          lod: plan.lod,
          nodes: plan.nodes.length,
          edges: plan.edges.length,
          labels: plan.labels.length,
          budgets: plan.budgets,
          skipped: plan.skipped,
        },
        scheduler: {
          mode: scheduled.plan.mode,
          actions: scheduled.actions,
          signals: scheduled.signals,
          p95FrameMs: scheduled.p95FrameMs,
        },
        storeRoot: args.storeRoot,
      },
      null,
      2,
    )}\n`,
  );
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(1);
  }
}

module.exports = { parseArgs };
