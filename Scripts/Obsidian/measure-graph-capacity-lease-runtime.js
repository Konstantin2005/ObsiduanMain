const { performance } = require("perf_hooks");
const runtime = require("./graph-capacity-lease-runtime.js");

function parseArgs(argv) {
  const args = {
    confidence: 0.72,
    ttlMs: 30000,
    diskLatencyMs: 35,
    compilerBacklogMb: 80,
    edgeMultiplier: 12,
    nowMs: 1000000,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--confidence") {
      args.confidence = Number(value || args.confidence);
      i += 1;
    } else if (key === "--ttl-ms") {
      args.ttlMs = Number(value || args.ttlMs);
      i += 1;
    } else if (key === "--disk-latency-ms") {
      args.diskLatencyMs = Number(value || args.diskLatencyMs);
      i += 1;
    } else if (key === "--compiler-backlog-mb") {
      args.compilerBacklogMb = Number(value || args.compilerBacklogMb);
      i += 1;
    } else if (key === "--edge-multiplier") {
      args.edgeMultiplier = Number(value || args.edgeMultiplier);
      i += 1;
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
  const benchmarkTimed = timed(() => {
    const envelope = runtime.createCapacityEnvelope({
      staticCapacity: { logicalCores: 12, totalMemoryMb: 32768 },
      observed: {
        readMbSec: 120,
        compilerFactsSec: 80000,
        publishCriticalSectionMs: 4,
        diskLatencyMs: args.diskLatencyMs,
      },
      effective: {
        maxWorkersNow: 5,
        maxReadMbSecNow: 80,
        maxQueueBytesNow: 64 * 1024 * 1024,
        maxMemoryMbNow: 512,
        publishBudgetMs: 8,
      },
      confidence: args.confidence,
      ttlMs: args.ttlMs,
      nowMs: args.nowMs,
    });

    const admission = runtime.evaluateAdmission({
      intent: { changedFiles: 25000, userActive: false },
      envelope,
      pressure: { diskLatencyMs: args.diskLatencyMs },
      nowMs: args.nowMs + 1000,
    });

    const leases = new runtime.ResourceLeaseManager({
      capacity: {
        workers: 4,
        memoryMb: 512,
        ioMbSec: 80,
        queueBytes: 32 * 1024 * 1024,
        publishBudgetMs: 8,
      },
    });
    const current = leases.requestLease({
      owner: "current-view",
      resources: { workers: 1, memoryMb: 64, ioMbSec: 10, queueBytes: 4 * 1024 * 1024, publishBudgetMs: 2 },
      priority: 100,
      ttlMs: 10000,
      nowMs: args.nowMs,
      revocable: false,
    });
    const compiler = leases.requestLease({
      owner: "compiler",
      resources: { workers: 1, memoryMb: 128, ioMbSec: 20, queueBytes: 8 * 1024 * 1024, publishBudgetMs: 4 },
      priority: 90,
      ttlMs: 10000,
      nowMs: args.nowMs,
      revocable: false,
    });
    const people = leases.requestLease({
      owner: "people-scan",
      resources: { workers: 2, memoryMb: 256, ioMbSec: 30, queueBytes: 12 * 1024 * 1024, publishBudgetMs: 0 },
      priority: 20,
      ttlMs: 10000,
      nowMs: args.nowMs,
      revocable: true,
    });
    const repair = leases.requestLease({
      owner: "snapshot-repair",
      resources: { workers: 2, memoryMb: 128, ioMbSec: 20, queueBytes: 8 * 1024 * 1024, publishBudgetMs: 2 },
      priority: 95,
      ttlMs: 5000,
      nowMs: args.nowMs + 100,
      revocable: false,
    });

    const policy = runtime.createWatermarkPolicy({
      metric: "compilerBacklogBytes",
      soft: 32 * 1024 * 1024,
      hard: 64 * 1024 * 1024,
      critical: 128 * 1024 * 1024,
      recovery: 16 * 1024 * 1024,
      hysteresisWindowMs: 10000,
    });
    const pressure = runtime.evaluateWatermark({
      policy,
      value: args.compilerBacklogMb * 1024 * 1024,
      previousLevel: runtime.WATERMARK_LEVEL.NORMAL,
      levelSinceMs: args.nowMs,
      nowMs: args.nowMs + 1000,
    });
    const recovery = runtime.evaluateWatermark({
      policy,
      value: 8 * 1024 * 1024,
      previousLevel: pressure.level,
      levelSinceMs: args.nowMs,
      nowMs: args.nowMs + 11000,
    });

    const brownout = runtime.decideBrownout({
      watermarkDecisions: [pressure],
      admission,
    });

    const shedding = runtime.createSheddingPlan({
      generation: 42,
      cancelTaskIds: ["parse-old"],
      dependencyGraph: {
        "compile-old": ["parse-old"],
        "validate-old": ["compile-old"],
        "publish-old": ["validate-old"],
        "parse-new": [],
      },
    });

    const truth = runtime.createSnapshotTruth({
      coverage: {
        coreGraph: 1,
        peopleLinks: 0.74,
        layout: 1,
        archive: 0.52,
      },
      freshness: {
        currentYear: "fresh",
        people: "stale",
        archive: "partial",
      },
      stalePartitions: ["people"],
      missingPartitions: ["archive-2019"],
      queryLimitations: ["people-neighborhood-incomplete"],
    });

    const containment = runtime.evaluateContainment({
      partitionId: "people",
      producer: "people-scan",
      metrics: {
        edgeMultiplier: args.edgeMultiplier,
        unresolvedDelta: 100,
        coverage: 0.74,
      },
    });

    return {
      envelope,
      admission,
      leases: leases.snapshot(args.nowMs + 200),
      leaseResults: [current, compiler, people, repair],
      pressure,
      recovery,
      brownout,
      shedding,
      truth,
      containment,
    };
  });

  const value = benchmarkTimed.value;
  const granted = value.leaseResults.filter((result) => result.granted).length;
  const revoked = value.leaseResults.reduce((sum, result) => sum + result.revoked.length, 0);
  const containedPartitions = value.containment.contained ? [value.containment.partitionId] : [];

  return {
    ok:
      value.envelope.contract === runtime.CONTRACTS.CAPACITY_ENVELOPE &&
      value.admission.degraded &&
      granted >= 3 &&
      revoked >= 1 &&
      value.brownout.level === runtime.BROWNOUT_LEVEL.MODERATE &&
      value.truth.truthLabel === runtime.TRUTH_LABEL.PARTIAL_STALE &&
      value.containment.contained &&
      value.recovery.level === runtime.WATERMARK_LEVEL.RECOVERY,
    contract: "CapacityLeaseBenchmark/v21.0",
    timingsMs: {
      total: benchmarkTimed.ms,
    },
    input: args,
    capacity: {
      confidence: value.envelope.confidence,
      ttlMs: value.envelope.ttlMs,
      expiresAt: value.envelope.expiresAt,
    },
    admission: value.admission.decision,
    admissionReasons: value.admission.reasons,
    leasesGranted: granted,
    leasesRevoked: revoked,
    activeLeaseOwners: value.leases.leases.filter((lease) => lease.status === runtime.LEASE_STATUS.ACTIVE).map((lease) => lease.owner),
    brownout: value.brownout.level,
    disabled: value.brownout.disabled,
    truthLabel: value.truth.truthLabel,
    visualWarning: value.truth.visualWarning,
    containedPartitions,
    containmentActions: value.containment.actions,
    sheddingCancelled: value.shedding.cancelledTaskIds.length,
    recoveredWithoutOscillation: value.recovery.level === runtime.WATERMARK_LEVEL.RECOVERY,
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
