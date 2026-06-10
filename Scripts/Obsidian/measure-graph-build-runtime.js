const { performance } = require("perf_hooks");
const runtime = require("./graph-build-runtime.js");

function parseArgs(argv) {
  const args = {
    changedFiles: 10000,
    totalFiles: 50000,
    changedMb: 1024,
    workers: 6,
    eventLoopDelay: 45,
    serializationMs: 900,
    unresolvedDelta: 50,
    quietMs: 6000,
    userActive: true,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--changed-files") {
      args.changedFiles = Math.max(0, Math.floor(Number(value || args.changedFiles)));
      i += 1;
    } else if (key === "--total-files") {
      args.totalFiles = Math.max(1, Math.floor(Number(value || args.totalFiles)));
      i += 1;
    } else if (key === "--changed-mb") {
      args.changedMb = Math.max(0, Number(value || args.changedMb));
      i += 1;
    } else if (key === "--workers") {
      args.workers = Math.max(1, Math.floor(Number(value || args.workers)));
      i += 1;
    } else if (key === "--event-loop-delay") {
      args.eventLoopDelay = Math.max(0, Number(value || args.eventLoopDelay));
      i += 1;
    } else if (key === "--serialization-ms") {
      args.serializationMs = Math.max(0, Number(value || args.serializationMs));
      i += 1;
    } else if (key === "--unresolved-delta") {
      args.unresolvedDelta = Math.max(0, Math.floor(Number(value || args.unresolvedDelta)));
      i += 1;
    } else if (key === "--quiet-ms") {
      args.quietMs = Math.max(0, Number(value || args.quietMs));
      i += 1;
    } else if (key === "--idle") {
      args.userActive = false;
    }
  }
  return args;
}

function timed(fn) {
  const startedAt = performance.now();
  const value = fn();
  return {
    value,
    ms: Number((performance.now() - startedAt).toFixed(3)),
  };
}

function runBenchmark(options = {}) {
  const args = { ...parseArgs([]), ...options };
  const changedBytes = args.changedMb * 1024 * 1024;

  const schedulerTimed = timed(() => {
    const intent = runtime.createBuildIntent({
      reason: "benchmark",
      changedFiles: args.changedFiles,
      changedBytes,
      totalFiles: args.totalFiles,
      userActive: args.userActive,
      obsidianFocused: args.userActive,
    });
    return runtime.scheduleBuild({
      intent,
      runtime: {
        quietMs: args.quietMs,
        userActive: args.userActive,
        obsidianFocused: args.userActive,
      },
    });
  });

  const costTimed = timed(() =>
    runtime.estimateBuildCost({
      affectedFiles: args.changedFiles,
      affectedBytes: changedBytes,
      recommendedMode: schedulerTimed.value.mode,
    }),
  );

  const governor = new runtime.AdaptiveResourceGovernor({
    policy: {
      workerCount: args.workers,
      maxInFlightChunks: args.workers + 2,
      maxInFlightBytes: 64 * 1024 * 1024,
      targetChunkBytes: 8 * 1024 * 1024,
      maxReadConcurrency: Math.max(1, args.workers),
    },
  });

  const healthTimed = timed(() => {
    const health = runtime.createRuntimeHealth({
      eventLoopDelayP95: args.eventLoopDelay,
      serializationMs: args.serializationMs,
      diskPressure: args.eventLoopDelay > 32 ? "HIGH" : "LOW",
      queuePressure: args.serializationMs > 250 ? "HIGH" : "LOW",
      workerUtilization: 0.96,
    });
    return {
      health,
      resourceDecision: governor.observe(health),
    };
  });

  const qualityTimed = timed(() =>
    runtime.evaluateSnapshotQuality({
      previousStats: { edges: 100000, unresolved: 10 },
      nextStats: { edges: 99000, unresolved: 10 + args.unresolvedDelta },
      coverage: args.unresolvedDelta > 25 ? 0.97 : 0.995,
      failedFiles: args.unresolvedDelta > 25 ? 1 : 0,
      stalePartitions: args.unresolvedDelta > 25 ? 1 : 0,
    }),
  );

  const historyTimed = timed(() => {
    const history = new runtime.BuildHistoryStore({ maxEntries: 20 });
    history.record({
      buildId: schedulerTimed.value.buildId,
      mode: schedulerTimed.value.mode,
      workers: args.workers,
      durationMs: costTimed.value.estimatedMs,
      diskPressure: healthTimed.value.health.diskPressure,
      eventLoopDelayP95: healthTimed.value.health.eventLoopDelayP95,
      serializationMs: healthTimed.value.health.serializationMs,
      snapshotDecision: qualityTimed.value.decision,
      nextRecommendation: healthTimed.value.resourceDecision.nextPolicy,
    });
    history.record({
      buildId: `${schedulerTimed.value.buildId}-prev`,
      mode: schedulerTimed.value.mode,
      workers: args.workers,
      durationMs: costTimed.value.estimatedMs * 1.1,
      diskPressure: "HIGH",
      eventLoopDelayP95: Math.max(args.eventLoopDelay, 40),
      serializationMs: Math.max(args.serializationMs, 500),
      snapshotDecision: qualityTimed.value.decision,
    });
    return {
      recommendation: history.recommend({
        workerCount: args.workers,
        targetChunkBytes: 8 * 1024 * 1024,
        maxInFlightChunks: args.workers + 2,
        maxReadConcurrency: args.workers,
      }),
      history: history.snapshot(),
    };
  });

  const priorityTimed = timed(() =>
    runtime.buildPriorityPlan([
      { path: "Archive/2019.md", archive: true },
      { path: "People/Alice.md", peopleIndex: true },
      { path: "Calendula/Today.md", currentWorkspace: true },
      { path: "Graph/Backbone.md", backbone: true },
    ]),
  );

  const serializationTimed = timed(() =>
    runtime.measureSerializationOverhead({
      nodes: Array.from({ length: 1000 }, (_, index) => ({
        id: index,
        x: index % 100,
        y: Math.floor(index / 100),
      })),
    }),
  );

  const totalMs = Number(
    (
      schedulerTimed.ms +
      costTimed.ms +
      healthTimed.ms +
      qualityTimed.ms +
      historyTimed.ms +
      priorityTimed.ms +
      serializationTimed.ms
    ).toFixed(3),
  );

  return {
    ok:
      schedulerTimed.value.contract === runtime.CONTRACTS.SCHEDULER_DECISION &&
      costTimed.value.contract === runtime.CONTRACTS.COST_ESTIMATE &&
      healthTimed.value.resourceDecision.nextPolicy.workerCount <= args.workers &&
      qualityTimed.value.decision !== runtime.QUALITY_DECISION.PUBLISH &&
      priorityTimed.value.items[0].currentWorkspace === true,
    contract: "GraphBuildRuntimeBenchmark/v16.0",
    input: args,
    timingsMs: {
      scheduler: schedulerTimed.ms,
      costEstimator: costTimed.ms,
      resourceGovernor: healthTimed.ms,
      qualityGate: qualityTimed.ms,
      buildHistory: historyTimed.ms,
      priorityPlan: priorityTimed.ms,
      serializationMeasure: serializationTimed.ms,
      total: totalMs,
    },
    buildId: schedulerTimed.value.buildId,
    schedulerDecision: schedulerTimed.value,
    costEstimate: costTimed.value,
    runtimeHealth: healthTimed.value.health,
    resourcePolicy: {
      initialWorkers: args.workers,
      finalWorkers: healthTimed.value.resourceDecision.nextPolicy.workerCount,
      actions: healthTimed.value.resourceDecision.actions,
      reasons: healthTimed.value.resourceDecision.reasons,
    },
    qualityGate: qualityTimed.value,
    nextRecommendation: historyTimed.value.recommendation,
    buildHistory: {
      count: historyTimed.value.history.count,
    },
    priorityPlan: {
      firstPath: priorityTimed.value.items[0].path,
      count: priorityTimed.value.count,
    },
    serializationOverhead: serializationTimed.value,
  };
}

function main() {
  const report = runBenchmark(parseArgs(process.argv.slice(2)));
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  if (!report.ok) process.exit(1);
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(1);
  }
}

module.exports = {
  parseArgs,
  runBenchmark,
};
