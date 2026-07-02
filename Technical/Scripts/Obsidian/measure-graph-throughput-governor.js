const { performance } = require("perf_hooks");
const governor = require("./graph-throughput-governor.js");

function parseArgs(argv) {
  const args = {
    workers: "2,4,6",
    throughput: "10000,13800,14200",
    eventLoopP95: "8,11,24",
    serializationMsPerMb: "2,3,4",
    diskLatencyMs: "10,12,18",
    mode: governor.SLA_MODE.INTERACTIVE_SAFE,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--workers") {
      args.workers = value || args.workers;
      i += 1;
    } else if (key === "--throughput") {
      args.throughput = value || args.throughput;
      i += 1;
    } else if (key === "--event-loop-p95") {
      args.eventLoopP95 = value || args.eventLoopP95;
      i += 1;
    } else if (key === "--serialization-ms-per-mb") {
      args.serializationMsPerMb = value || args.serializationMsPerMb;
      i += 1;
    } else if (key === "--disk-latency-ms") {
      args.diskLatencyMs = value || args.diskLatencyMs;
      i += 1;
    } else if (key === "--mode") {
      args.mode = value || args.mode;
      i += 1;
    }
  }

  return args;
}

function parseNumberList(value) {
  return String(value || "")
    .split(",")
    .map((item) => Number(item.trim()))
    .filter((item) => Number.isFinite(item));
}

function timed(fn) {
  const startedAt = performance.now();
  const value = fn();
  return {
    value,
    ms: Number((performance.now() - startedAt).toFixed(3)),
  };
}

function valueAt(values, index, fallback = 0) {
  return values[index] ?? values[values.length - 1] ?? fallback;
}

function runBenchmark(options = {}) {
  const args = { ...parseArgs([]), ...options };
  const workerSeries = parseNumberList(args.workers);
  const throughputSeries = parseNumberList(args.throughput);
  const eventLoopSeries = parseNumberList(args.eventLoopP95);
  const serializationSeries = parseNumberList(args.serializationMsPerMb);
  const diskSeries = parseNumberList(args.diskLatencyMs);
  const maxWorkers = Math.max(...workerSeries, 1);

  const benchmarkTimed = timed(() => {
    const runtime = new governor.ThroughputGovernor({
      policy: {
        mode: args.mode,
        workerCount: workerSeries[0] || 2,
        maxWorkers,
        chunkBytes: 4 * 1024 * 1024,
        maxInFlightBytes: 16 * 1024 * 1024,
        maxReadConcurrency: 2,
      },
    });

    const decisions = [];
    let previousUsefulFactsPerSec = 0;
    for (let index = 0; index < workerSeries.length; index += 1) {
      const workerCount = workerSeries[index];
      runtime.policy = governor.normalizeThroughputPolicy({ ...runtime.policy, workerCount, maxWorkers });
      const usefulFactsPerSec = valueAt(throughputSeries, index);
      const eventLoopDelayP95 = valueAt(eventLoopSeries, index);
      const sla = governor.evaluateSla({
        mode: args.mode,
        metrics: {
          eventLoopDelayP95,
          eventLoopDelayP99: eventLoopDelayP95 * 1.6,
          inputLatencyMs: eventLoopDelayP95 * 2,
          renderFrameMs: Math.max(8, eventLoopDelayP95),
          snapshotPublishMs: 4,
          dashboardUpdateHz: 1,
        },
      });
      const profile = governor.createResourceProfile({
        staticCaps: { logicalCores: maxWorkers + 2, totalMemoryMb: 32768 },
        observedCaps: {
          usefulFactsPerSec,
          eventLoopDelayP95,
          serializationMsPerMb: valueAt(serializationSeries, index),
          readMbPerSec: 300,
          snapshotWriteMbPerSec: 200,
        },
        confidence: 0.8,
      });
      const decision = runtime.observe({
        slaReport: sla,
        resourceProfile: profile,
        previousSample: { usefulFactsPerSec: previousUsefulFactsPerSec },
        sample: {
          usefulFactsPerSec,
          serializationMsPerMb: valueAt(serializationSeries, index),
          diskLatencyMs: valueAt(diskSeries, index),
        },
      });
      decisions.push(decision);
      previousUsefulFactsPerSec = usefulFactsPerSec;
    }

    const freshnessMap = governor.buildFreshnessMap([
      { id: "current-year", priority: 90, freshness: governor.PARTITION_FRESHNESS.PARTIAL_FRESH, coverage: 0.94, lastBuildId: "bench" },
      { id: "people", priority: 80, freshness: governor.PARTITION_FRESHNESS.COMPLETE, coverage: 1, lastBuildId: "bench" },
      { id: "archive", priority: 10, freshness: governor.PARTITION_FRESHNESS.PARTIAL_STALE, coverage: 0.2, lastBuildId: "old" },
    ]);
    const dashboard = governor.createDashboardSample({
      policy: runtime.policy,
      slaReport: decisions[decisions.length - 1].slaReport,
      decision: decisions[decisions.length - 1],
      freshnessMap,
    });
    return { decisions, finalPolicy: runtime.policy, dashboard, freshnessMap };
  });

  const decisions = benchmarkTimed.value.decisions;
  const finalDecision = decisions[decisions.length - 1];
  const bestIndex = decisions.reduce((best, decision, index) => {
    if (!decision.slaReport.ok) return best;
    if (best === -1) return index;
    if (decision.throughput.usefulFactsPerSec > decisions[best].throughput.usefulFactsPerSec) return index;
    return best;
  }, -1);

  const decisionLabel =
    finalDecision.actions.includes(governor.GOVERNOR_ACTION.SCALE_DOWN) ||
    finalDecision.actions.includes(governor.GOVERNOR_ACTION.EMERGENCY_THROTTLE)
      ? `KEEP_WORKERS_${bestIndex >= 0 ? workerSeries[bestIndex] : benchmarkTimed.value.finalPolicy.workerCount}`
      : finalDecision.actions[0];

  return {
    ok:
      decisions.length === workerSeries.length &&
      finalDecision.contract === governor.CONTRACTS.GOVERNOR_DECISION &&
      benchmarkTimed.value.dashboard.contract === governor.CONTRACTS.DASHBOARD_SAMPLE &&
      finalDecision.throttleReasons.length > 0,
    contract: "GraphThroughputBenchmark/v17.0",
    input: args,
    timingsMs: {
      total: benchmarkTimed.ms,
    },
    workers: workerSeries,
    usefulFactsPerSec: throughputSeries,
    eventLoopDelayP95: eventLoopSeries,
    decision: decisionLabel,
    reasons: finalDecision.throttleReasons,
    actions: finalDecision.actions,
    finalPolicy: benchmarkTimed.value.finalPolicy,
    dashboard: {
      maxHz: benchmarkTimed.value.dashboard.maxHz,
      workerCount: benchmarkTimed.value.dashboard.workerCount,
      freshnessCoverage: benchmarkTimed.value.dashboard.freshness.coverage,
      throttleReasons: benchmarkTimed.value.dashboard.throttleReasons,
    },
    decisions: decisions.map((decision, index) => ({
      workerCount: workerSeries[index],
      usefulFactsPerSec: decision.throughput.usefulFactsPerSec,
      gain: decision.throughput.gain,
      actions: decision.actions,
      reasons: decision.throttleReasons,
      nextWorkerCount: decision.nextPolicy.workerCount,
      eventLoopDelayP95: decision.slaReport.metrics.eventLoopDelayP95,
    })),
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
