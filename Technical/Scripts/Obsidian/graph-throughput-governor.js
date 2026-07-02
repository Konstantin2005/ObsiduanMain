const os = require("os");

const CONTRACTS = Object.freeze({
  RESOURCE_PROFILE: "GraphResourceProfile/v17.0",
  SLA_REPORT: "GraphSlaReport/v17.0",
  GOVERNOR_POLICY: "GraphThroughputPolicy/v17.0",
  GOVERNOR_DECISION: "GraphThroughputGovernorDecision/v17.0",
  PARTITION: "GraphPartition/v17.0",
  DASHBOARD_SAMPLE: "GraphDashboardSample/v17.0",
});

const SLA_MODE = Object.freeze({
  INTERACTIVE_SAFE: "INTERACTIVE_SAFE",
  BACKGROUND_MAX: "BACKGROUND_MAX",
  IDLE_HIGH_THROUGHPUT: "IDLE_HIGH_THROUGHPUT",
  EMERGENCY_THROTTLE: "EMERGENCY_THROTTLE",
});

const THROTTLE_REASON = Object.freeze({
  UI_LAG: "UI_LAG",
  INPUT_LATENCY: "INPUT_LATENCY",
  PUBLISH_TOO_LONG: "PUBLISH_TOO_LONG",
  DASHBOARD_OVERHEAD: "DASHBOARD_OVERHEAD",
  FRAME_BUDGET_EXCEEDED: "FRAME_BUDGET_EXCEEDED",
  MEMORY_PRESSURE: "MEMORY_PRESSURE",
  DISK_LATENCY: "DISK_LATENCY",
  SERIALIZATION_OVERHEAD: "SERIALIZATION_OVERHEAD",
  GC_PRESSURE: "GC_PRESSURE",
  LOW_THROUGHPUT_GAIN: "LOW_THROUGHPUT_GAIN",
  SYNC_STORM: "SYNC_STORM",
  BATTERY_SAFE_MODE: "BATTERY_SAFE_MODE",
});

const GOVERNOR_ACTION = Object.freeze({
  KEEP: "KEEP",
  SCALE_UP: "SCALE_UP",
  SCALE_DOWN: "SCALE_DOWN",
  EMERGENCY_THROTTLE: "EMERGENCY_THROTTLE",
  PAUSE_IO: "PAUSE_IO",
  REDUCE_CHUNK_BYTES: "REDUCE_CHUNK_BYTES",
  REDUCE_IN_FLIGHT_BYTES: "REDUCE_IN_FLIGHT_BYTES",
  DROP_LOW_PRIORITY: "DROP_LOW_PRIORITY",
  CACHE_ONLY_LOW_PRIORITY: "CACHE_ONLY_LOW_PRIORITY",
});

const PARTITION_FRESHNESS = Object.freeze({
  COMPLETE: "complete",
  PARTIAL_FRESH: "partial-fresh",
  PARTIAL_STALE: "partial-stale",
  BUILDING: "partition-building",
  FAILED: "partition-failed",
  MISSING: "missing",
});

const DEFAULT_SLA_BUDGETS = Object.freeze({
  [SLA_MODE.INTERACTIVE_SAFE]: Object.freeze({
    eventLoopDelayP95: 16,
    eventLoopDelayP99: 32,
    inputLatencyMs: 50,
    renderFrameMs: 16,
    snapshotPublishMs: 8,
    dashboardUpdateHz: 2,
  }),
  [SLA_MODE.BACKGROUND_MAX]: Object.freeze({
    eventLoopDelayP95: 32,
    eventLoopDelayP99: 64,
    inputLatencyMs: 75,
    renderFrameMs: 24,
    snapshotPublishMs: 8,
    dashboardUpdateHz: 2,
  }),
  [SLA_MODE.IDLE_HIGH_THROUGHPUT]: Object.freeze({
    eventLoopDelayP95: 64,
    eventLoopDelayP99: 96,
    inputLatencyMs: 150,
    renderFrameMs: 48,
    snapshotPublishMs: 8,
    dashboardUpdateHz: 1,
  }),
  [SLA_MODE.EMERGENCY_THROTTLE]: Object.freeze({
    eventLoopDelayP95: 16,
    eventLoopDelayP99: 32,
    inputLatencyMs: 50,
    renderFrameMs: 16,
    snapshotPublishMs: 8,
    dashboardUpdateHz: 1,
  }),
});

const DEFAULT_POLICY = Object.freeze({
  mode: SLA_MODE.INTERACTIVE_SAFE,
  workerCount: 2,
  minWorkers: 1,
  maxWorkers: 8,
  chunkBytes: 4 * 1024 * 1024,
  minChunkBytes: 256 * 1024,
  maxInFlightBytes: 16 * 1024 * 1024,
  maxReadConcurrency: 2,
  pauseIoMs: 0,
  cacheOnlyLowPriority: false,
  dashboardMaxHz: 2,
});

function nowIso() {
  return new Date().toISOString();
}

function freezeArray(values = []) {
  return Object.freeze(Array.from(values));
}

function freezeObject(value = {}) {
  return Object.freeze({ ...value });
}

function clampNumber(value, min, max) {
  const number = Number(value);
  if (!Number.isFinite(number)) return min;
  return Math.max(min, Math.min(max, number));
}

function positiveInteger(value, fallback) {
  const number = Math.floor(Number(value));
  return Number.isFinite(number) && number > 0 ? number : fallback;
}

function createResourceProfile({
  staticCaps = {},
  observedCaps = {},
  confidence = 0.5,
  lastUpdated = nowIso(),
} = {}) {
  const logicalCores = positiveInteger(staticCaps.logicalCores, Math.max(1, os.cpus()?.length || 1));
  const totalMemoryMb = positiveInteger(staticCaps.totalMemoryMb, Math.floor(os.totalmem() / 1024 / 1024));

  return Object.freeze({
    contract: CONTRACTS.RESOURCE_PROFILE,
    staticCaps: Object.freeze({
      logicalCores,
      totalMemoryMb,
      platform: staticCaps.platform || process.platform,
      nodeVersion: staticCaps.nodeVersion || process.version,
      arch: staticCaps.arch || process.arch,
    }),
    observedCaps: Object.freeze({
      eventLoopDelayP95: Number(observedCaps.eventLoopDelayP95 || 0),
      eventLoopDelayP99: Number(observedCaps.eventLoopDelayP99 || 0),
      usefulFactsPerSec: Number(observedCaps.usefulFactsPerSec || 0),
      parseFilesPerSec: Number(observedCaps.parseFilesPerSec || 0),
      readMbPerSec: Number(observedCaps.readMbPerSec || 0),
      serializationMsPerMb: Number(observedCaps.serializationMsPerMb || 0),
      gcPauseMs: Number(observedCaps.gcPauseMs || 0),
      snapshotWriteMbPerSec: Number(observedCaps.snapshotWriteMbPerSec || 0),
      publishCriticalSectionMs: Number(observedCaps.publishCriticalSectionMs || 0),
    }),
    confidence: clampNumber(confidence, 0, 1),
    lastUpdated,
  });
}

function getSlaBudget(mode = SLA_MODE.INTERACTIVE_SAFE, overrides = {}) {
  const selected = DEFAULT_SLA_BUDGETS[mode] || DEFAULT_SLA_BUDGETS[SLA_MODE.INTERACTIVE_SAFE];
  return Object.freeze({ ...selected, ...overrides });
}

function evaluateSla({
  mode = SLA_MODE.INTERACTIVE_SAFE,
  metrics = {},
  budgets = null,
} = {}) {
  const budget = budgets ? Object.freeze({ ...getSlaBudget(mode), ...budgets }) : getSlaBudget(mode);
  const violations = [];

  if (Number(metrics.eventLoopDelayP95 || 0) > budget.eventLoopDelayP95) violations.push(THROTTLE_REASON.UI_LAG);
  if (Number(metrics.eventLoopDelayP99 || 0) > budget.eventLoopDelayP99) violations.push(THROTTLE_REASON.UI_LAG);
  if (Number(metrics.inputLatencyMs || 0) > budget.inputLatencyMs) violations.push(THROTTLE_REASON.INPUT_LATENCY);
  if (Number(metrics.renderFrameMs || 0) > budget.renderFrameMs) violations.push(THROTTLE_REASON.FRAME_BUDGET_EXCEEDED);
  if (Number(metrics.snapshotPublishMs || 0) > budget.snapshotPublishMs) violations.push(THROTTLE_REASON.PUBLISH_TOO_LONG);
  if (Number(metrics.dashboardUpdateHz || 0) > budget.dashboardUpdateHz) violations.push(THROTTLE_REASON.DASHBOARD_OVERHEAD);

  const uniqueViolations = freezeArray([...new Set(violations)]);
  return Object.freeze({
    contract: CONTRACTS.SLA_REPORT,
    mode,
    ok: uniqueViolations.length === 0,
    emergency: uniqueViolations.some((reason) =>
      reason === THROTTLE_REASON.UI_LAG ||
      reason === THROTTLE_REASON.INPUT_LATENCY ||
      reason === THROTTLE_REASON.PUBLISH_TOO_LONG,
    ),
    violations: uniqueViolations,
    budgets: budget,
    metrics: freezeObject(metrics),
    checkedAt: nowIso(),
  });
}

function normalizeThroughputPolicy(policy = {}) {
  const merged = { ...DEFAULT_POLICY, ...policy };
  const minWorkers = Math.max(1, Math.floor(Number(merged.minWorkers || DEFAULT_POLICY.minWorkers)));
  const maxWorkers = Math.max(minWorkers, Math.floor(Number(merged.maxWorkers || DEFAULT_POLICY.maxWorkers)));
  const chunkBytes = Math.max(
    Math.floor(Number(merged.minChunkBytes || DEFAULT_POLICY.minChunkBytes)),
    Math.floor(Number(merged.chunkBytes || DEFAULT_POLICY.chunkBytes)),
  );
  const maxInFlightBytes = Math.max(chunkBytes, Math.floor(Number(merged.maxInFlightBytes || DEFAULT_POLICY.maxInFlightBytes)));

  return Object.freeze({
    contract: CONTRACTS.GOVERNOR_POLICY,
    mode: merged.mode || SLA_MODE.INTERACTIVE_SAFE,
    workerCount: clampNumber(Math.floor(Number(merged.workerCount || DEFAULT_POLICY.workerCount)), minWorkers, maxWorkers),
    minWorkers,
    maxWorkers,
    chunkBytes,
    minChunkBytes: Math.max(64 * 1024, Math.floor(Number(merged.minChunkBytes || DEFAULT_POLICY.minChunkBytes))),
    maxInFlightBytes,
    maxReadConcurrency: Math.max(1, Math.floor(Number(merged.maxReadConcurrency || DEFAULT_POLICY.maxReadConcurrency))),
    pauseIoMs: Math.max(0, Number(merged.pauseIoMs || 0)),
    cacheOnlyLowPriority: Boolean(merged.cacheOnlyLowPriority),
    dashboardMaxHz: Math.max(0.1, Number(merged.dashboardMaxHz || DEFAULT_POLICY.dashboardMaxHz)),
  });
}

function computeThroughputGain({ previousUsefulFactsPerSec = 0, usefulFactsPerSec = 0 } = {}) {
  const previous = Math.max(0, Number(previousUsefulFactsPerSec || 0));
  const current = Math.max(0, Number(usefulFactsPerSec || 0));
  if (previous === 0) return current > 0 ? 1 : 0;
  return (current - previous) / previous;
}

class ThroughputGovernor {
  constructor({
    policy = DEFAULT_POLICY,
    thresholds = {},
  } = {}) {
    this.policy = normalizeThroughputPolicy(policy);
    this.thresholds = Object.freeze({
      minUsefulThroughputGain: 0.08,
      highSerializationMsPerMb: 8,
      highGcPauseMs: 40,
      highDiskLatencyMs: 50,
      memoryPressureRatio: 0.85,
      ...thresholds,
    });
    this.decisions = [];
  }

  observe({
    slaReport = evaluateSla({ mode: this.policy.mode }),
    resourceProfile = createResourceProfile(),
    sample = {},
    previousSample = {},
  } = {}) {
    const report = slaReport.contract === CONTRACTS.SLA_REPORT ? slaReport : evaluateSla(slaReport);
    const profile = resourceProfile.contract === CONTRACTS.RESOURCE_PROFILE ? resourceProfile : createResourceProfile(resourceProfile);
    const usefulFactsPerSec = Number(sample.usefulFactsPerSec || profile.observedCaps.usefulFactsPerSec || 0);
    const previousUsefulFactsPerSec = Number(previousSample.usefulFactsPerSec || 0);
    const throughputGain = computeThroughputGain({ previousUsefulFactsPerSec, usefulFactsPerSec });
    const reasons = [...report.violations];
    const actions = [];
    let next = { ...this.policy, pauseIoMs: 0, cacheOnlyLowPriority: false };

    if (sample.memoryPressure || Number(sample.memoryUsedRatio || 0) > this.thresholds.memoryPressureRatio) {
      reasons.push(THROTTLE_REASON.MEMORY_PRESSURE);
    }
    if (Number(sample.diskLatencyMs || 0) > this.thresholds.highDiskLatencyMs) {
      reasons.push(THROTTLE_REASON.DISK_LATENCY);
    }
    if (Number(sample.serializationMsPerMb || profile.observedCaps.serializationMsPerMb || 0) > this.thresholds.highSerializationMsPerMb) {
      reasons.push(THROTTLE_REASON.SERIALIZATION_OVERHEAD);
    }
    if (Number(sample.gcPauseMs || profile.observedCaps.gcPauseMs || 0) > this.thresholds.highGcPauseMs) {
      reasons.push(THROTTLE_REASON.GC_PRESSURE);
    }
    if (sample.syncStorm) {
      reasons.push(THROTTLE_REASON.SYNC_STORM);
    }
    if (sample.batterySafeMode) {
      reasons.push(THROTTLE_REASON.BATTERY_SAFE_MODE);
    }

    const uniqueReasons = [...new Set(reasons)];
    const mustThrottle =
      report.emergency ||
      uniqueReasons.includes(THROTTLE_REASON.MEMORY_PRESSURE) ||
      uniqueReasons.includes(THROTTLE_REASON.DISK_LATENCY) ||
      uniqueReasons.includes(THROTTLE_REASON.SERIALIZATION_OVERHEAD) ||
      uniqueReasons.includes(THROTTLE_REASON.GC_PRESSURE) ||
      uniqueReasons.includes(THROTTLE_REASON.SYNC_STORM) ||
      uniqueReasons.includes(THROTTLE_REASON.BATTERY_SAFE_MODE);

    if (mustThrottle) {
      actions.push(
        GOVERNOR_ACTION.EMERGENCY_THROTTLE,
        GOVERNOR_ACTION.SCALE_DOWN,
        GOVERNOR_ACTION.PAUSE_IO,
        GOVERNOR_ACTION.REDUCE_CHUNK_BYTES,
        GOVERNOR_ACTION.REDUCE_IN_FLIGHT_BYTES,
        GOVERNOR_ACTION.DROP_LOW_PRIORITY,
        GOVERNOR_ACTION.CACHE_ONLY_LOW_PRIORITY,
      );
      next.workerCount = Math.max(next.minWorkers, Math.floor(next.workerCount / 2));
      next.chunkBytes = Math.max(next.minChunkBytes, Math.floor(next.chunkBytes / 2));
      next.maxInFlightBytes = Math.max(next.chunkBytes, Math.min(next.maxInFlightBytes, next.chunkBytes));
      next.maxReadConcurrency = Math.max(1, Math.floor(next.maxReadConcurrency / 2));
      next.pauseIoMs = Math.max(500, Number(sample.pauseIoMs || 0));
      next.cacheOnlyLowPriority = true;
    } else if (previousUsefulFactsPerSec > 0 && throughputGain < this.thresholds.minUsefulThroughputGain) {
      uniqueReasons.push(THROTTLE_REASON.LOW_THROUGHPUT_GAIN);
      actions.push(GOVERNOR_ACTION.SCALE_DOWN, GOVERNOR_ACTION.REDUCE_IN_FLIGHT_BYTES);
      next.workerCount = Math.max(next.minWorkers, next.workerCount - 1);
      next.maxInFlightBytes = Math.max(next.chunkBytes, Math.floor(next.maxInFlightBytes / 2));
    } else if (report.ok && next.workerCount < next.maxWorkers) {
      actions.push(GOVERNOR_ACTION.SCALE_UP);
      next.workerCount = Math.min(next.maxWorkers, next.workerCount + 1);
      next.maxInFlightBytes = Math.max(next.maxInFlightBytes, next.chunkBytes * Math.min(next.workerCount, 8));
    } else {
      actions.push(GOVERNOR_ACTION.KEEP);
    }

    this.policy = normalizeThroughputPolicy(next);
    const decision = Object.freeze({
      contract: CONTRACTS.GOVERNOR_DECISION,
      mode: this.policy.mode,
      actions: freezeArray([...new Set(actions)]),
      throttleReasons: freezeArray([...new Set(uniqueReasons)]),
      throughput: Object.freeze({
        usefulFactsPerSec,
        previousUsefulFactsPerSec,
        gain: Number(throughputGain.toFixed(6)),
      }),
      slaReport: report,
      resourceProfile: profile,
      nextPolicy: this.policy,
      decidedAt: nowIso(),
    });
    this.decisions.push(decision);
    return decision;
  }

  snapshot() {
    return Object.freeze({
      contract: CONTRACTS.GOVERNOR_DECISION,
      policy: this.policy,
      decisions: freezeArray(this.decisions),
    });
  }
}

function createPartition({
  id,
  priority = 0,
  freshness = PARTITION_FRESHNESS.MISSING,
  coverage = 0,
  lastBuildId = null,
  dependencies = [],
} = {}) {
  if (!id) throw new Error("GraphPartition requires id");
  return Object.freeze({
    contract: CONTRACTS.PARTITION,
    id: String(id),
    priority: Number(priority || 0),
    freshness,
    coverage: clampNumber(coverage, 0, 1),
    lastBuildId,
    dependencies: freezeArray(dependencies),
  });
}

function buildFreshnessMap(partitions = []) {
  const items = Array.from(partitions || []).map((partition) =>
    partition.contract === CONTRACTS.PARTITION ? partition : createPartition(partition),
  );
  const byId = {};
  const counts = {};
  let weightedCoverage = 0;
  let priorityTotal = 0;
  for (const partition of items) {
    byId[partition.id] = partition;
    counts[partition.freshness] = (counts[partition.freshness] || 0) + 1;
    const weight = Math.max(1, partition.priority);
    weightedCoverage += partition.coverage * weight;
    priorityTotal += weight;
  }
  return Object.freeze({
    partitions: Object.freeze(byId),
    counts: freezeObject(counts),
    coverage: priorityTotal > 0 ? Number((weightedCoverage / priorityTotal).toFixed(6)) : 0,
  });
}

function shouldSampleDashboard({ lastSampleAtMs = 0, nowMs = Date.now(), maxHz = 2 } = {}) {
  const hz = Math.max(0.1, Number(maxHz || 2));
  const minIntervalMs = 1000 / hz;
  return Number(nowMs || 0) - Number(lastSampleAtMs || 0) >= minIntervalMs;
}

function createDashboardSample({
  policy = DEFAULT_POLICY,
  slaReport = evaluateSla(),
  decision = null,
  freshnessMap = buildFreshnessMap(),
  metrics = {},
  sampledAt = nowIso(),
} = {}) {
  const normalizedPolicy = policy.contract === CONTRACTS.GOVERNOR_POLICY ? policy : normalizeThroughputPolicy(policy);
  const report = slaReport.contract === CONTRACTS.SLA_REPORT ? slaReport : evaluateSla(slaReport);
  return Object.freeze({
    contract: CONTRACTS.DASHBOARD_SAMPLE,
    sampledAt,
    maxHz: normalizedPolicy.dashboardMaxHz,
    mode: normalizedPolicy.mode,
    usefulFactsPerSec: Number(metrics.usefulFactsPerSec || decision?.throughput?.usefulFactsPerSec || 0),
    workerCount: normalizedPolicy.workerCount,
    chunkBytes: normalizedPolicy.chunkBytes,
    maxInFlightBytes: normalizedPolicy.maxInFlightBytes,
    maxReadConcurrency: normalizedPolicy.maxReadConcurrency,
    eventLoopDelayP95: Number(report.metrics.eventLoopDelayP95 || 0),
    eventLoopDelayP99: Number(report.metrics.eventLoopDelayP99 || 0),
    publishCriticalSectionMs: Number(report.metrics.snapshotPublishMs || 0),
    throttleReasons: freezeArray(decision?.throttleReasons || report.violations),
    freshness: freshnessMap,
  });
}

module.exports = {
  CONTRACTS,
  DEFAULT_POLICY,
  DEFAULT_SLA_BUDGETS,
  GOVERNOR_ACTION,
  PARTITION_FRESHNESS,
  SLA_MODE,
  THROTTLE_REASON,
  ThroughputGovernor,
  buildFreshnessMap,
  computeThroughputGain,
  createDashboardSample,
  createPartition,
  createResourceProfile,
  evaluateSla,
  getSlaBudget,
  normalizeThroughputPolicy,
  shouldSampleDashboard,
};
