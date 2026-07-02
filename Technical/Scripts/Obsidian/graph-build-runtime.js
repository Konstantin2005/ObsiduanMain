const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const CONTRACTS = Object.freeze({
  BUILD_INTENT: "GraphBuildIntent/v16.0",
  SCHEDULER_DECISION: "GraphBuildSchedulerDecision/v16.0",
  COST_ESTIMATE: "GraphBuildCostEstimate/v16.0",
  EXECUTION_TRACE: "GraphBuildExecutionTrace/v16.0",
  RESOURCE_POLICY: "GraphBuildResourcePolicy/v16.0",
  RUNTIME_HEALTH: "GraphBuildRuntimeHealth/v16.0",
  QUALITY_REPORT: "GraphSnapshotQualityReport/v16.0",
  BUILD_HISTORY_RECORD: "GraphBuildHistoryRecord/v16.0",
  PRIORITY_PLAN: "GraphBuildPriorityPlan/v16.0",
});

const SCHEDULER_DECISION = Object.freeze({
  NOW: "NOW",
  DELAY: "DELAY",
  BACKGROUND: "BACKGROUND",
  IDLE_ONLY: "IDLE_ONLY",
  FULL_REBUILD_NIGHT: "FULL_REBUILD_NIGHT",
  SKIP: "SKIP",
});

const BUILD_MODE = Object.freeze({
  INTERACTIVE_LIGHT: "INTERACTIVE_LIGHT",
  BACKGROUND_NORMAL: "BACKGROUND_NORMAL",
  BACKGROUND_HEAVY: "BACKGROUND_HEAVY",
  VALIDATION_ONLY: "VALIDATION_ONLY",
  REPAIR: "REPAIR",
  FULL_REBUILD: "FULL_REBUILD",
});

const QUALITY_DECISION = Object.freeze({
  PUBLISH: "PUBLISH",
  REJECT: "REJECT",
  PUBLISH_PARTIAL: "PUBLISH_PARTIAL",
  KEEP_PREVIOUS: "KEEP_PREVIOUS",
  RETRY_BACKGROUND: "RETRY_BACKGROUND",
});

const RESOURCE_ACTION = Object.freeze({
  KEEP: "KEEP",
  REDUCE_WORKERS: "REDUCE_WORKERS",
  INCREASE_WORKERS: "INCREASE_WORKERS",
  PAUSE_IO: "PAUSE_IO",
  REDUCE_CHUNK_SIZE: "REDUCE_CHUNK_SIZE",
  SWITCH_MODE: "SWITCH_MODE",
});

const DEFAULT_RESOURCE_POLICY = Object.freeze({
  mode: "safe",
  workerCount: 4,
  maxInFlightChunks: 8,
  maxInFlightBytes: 32 * 1024 * 1024,
  targetChunkBytes: 4 * 1024 * 1024,
  maxReadConcurrency: 4,
  maxMemoryMb: 1024,
});

const DEFAULT_COST_MODEL = Object.freeze({
  baseMs: 50,
  msPerFile: 0.08,
  msPerReadMb: 2.5,
  cpuMsPerFile: 0.05,
  writeMbPerFile: 0.001,
});

const DEFAULT_QUALITY_THRESHOLDS = Object.freeze({
  minCoverage: 0.98,
  maxFailedFiles: 0,
  maxUnresolvedDelta: 25,
  maxEdgeDropRate: 0.01,
});

function newId(prefix) {
  if (typeof crypto.randomUUID === "function") return `${prefix}-${crypto.randomUUID()}`;
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
}

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

function createBuildIntent({
  buildId = newId("build"),
  reason = "manual",
  changedFiles = 0,
  changedBytes = 0,
  totalFiles = 0,
  syncStorm = false,
  userActive = false,
  obsidianFocused = false,
  requestedMode = BUILD_MODE.BACKGROUND_NORMAL,
} = {}) {
  return Object.freeze({
    contract: CONTRACTS.BUILD_INTENT,
    buildId,
    reason,
    changedFiles: Math.max(0, Math.floor(Number(changedFiles || 0))),
    changedBytes: Math.max(0, Number(changedBytes || 0)),
    totalFiles: Math.max(0, Math.floor(Number(totalFiles || 0))),
    syncStorm: Boolean(syncStorm),
    userActive: Boolean(userActive),
    obsidianFocused: Boolean(obsidianFocused),
    requestedMode,
    createdAt: nowIso(),
  });
}

function scheduleBuild({
  intent = createBuildIntent(),
  runtime = {},
  history = {},
  thresholds = {},
} = {}) {
  const reasons = [];
  const changedFiles = Number(intent.changedFiles || 0);
  const totalFiles = Math.max(1, Number(intent.totalFiles || changedFiles || 1));
  const changeRatio = changedFiles / totalFiles;
  const syncStorm = Boolean(intent.syncStorm || runtime.syncStorm);
  const userActive = Boolean(intent.userActive || runtime.userActive);
  const batterySaver = Boolean(runtime.batterySaver || runtime.onBattery);
  const memoryPressure = Boolean(runtime.memoryPressure);
  const previousFailureRate = Number(history.previousFailureRate || 0);
  const quietMs = Number(runtime.quietMs || 0);
  const quietThresholdMs = Number(thresholds.quietThresholdMs || 5000);

  let decision = SCHEDULER_DECISION.NOW;
  let mode = intent.requestedMode || BUILD_MODE.BACKGROUND_NORMAL;

  if (changedFiles === 0) {
    decision = SCHEDULER_DECISION.SKIP;
    mode = BUILD_MODE.VALIDATION_ONLY;
    reasons.push("no-changes");
  } else if (syncStorm || quietMs < quietThresholdMs) {
    decision = SCHEDULER_DECISION.DELAY;
    mode = BUILD_MODE.BACKGROUND_HEAVY;
    reasons.push(syncStorm ? "sync-storm" : "quiet-period-not-reached");
  } else if (changeRatio > 0.2 || changedFiles > Number(thresholds.fullRebuildFileThreshold || 10000)) {
    decision = userActive ? SCHEDULER_DECISION.FULL_REBUILD_NIGHT : SCHEDULER_DECISION.BACKGROUND;
    mode = BUILD_MODE.FULL_REBUILD;
    reasons.push("large-change-set");
  } else if (batterySaver || memoryPressure) {
    decision = SCHEDULER_DECISION.IDLE_ONLY;
    mode = BUILD_MODE.INTERACTIVE_LIGHT;
    reasons.push(batterySaver ? "battery-saver" : "memory-pressure");
  } else if (userActive || intent.obsidianFocused || runtime.obsidianFocused) {
    decision = SCHEDULER_DECISION.BACKGROUND;
    mode = BUILD_MODE.INTERACTIVE_LIGHT;
    reasons.push("user-active");
  } else if (previousFailureRate > Number(thresholds.failureRateThreshold || 0.25)) {
    decision = SCHEDULER_DECISION.BACKGROUND;
    mode = BUILD_MODE.REPAIR;
    reasons.push("previous-failures");
  } else {
    reasons.push("safe-to-run-now");
  }

  return Object.freeze({
    contract: CONTRACTS.SCHEDULER_DECISION,
    buildId: intent.buildId,
    decision,
    mode,
    reasons: freezeArray(reasons),
    changeRatio,
    inputs: Object.freeze({
      changedFiles,
      totalFiles,
      syncStorm,
      userActive,
      batterySaver,
      memoryPressure,
      previousFailureRate,
    }),
  });
}

function estimateBuildCost({
  affectedFiles = 0,
  affectedBytes = 0,
  historySummary = {},
  model = {},
  recommendedMode = BUILD_MODE.BACKGROUND_NORMAL,
} = {}) {
  const m = { ...DEFAULT_COST_MODEL, ...model };
  const files = Math.max(0, Number(affectedFiles || 0));
  const readMb = Math.max(0, Number(affectedBytes || 0)) / (1024 * 1024);
  const historyMultiplier = Number(historySummary.slowdownMultiplier || 1);
  const estimatedMs = Math.max(0, (m.baseMs + files * m.msPerFile + readMb * m.msPerReadMb) * historyMultiplier);
  const estimatedCpuMs = Math.max(0, files * m.cpuMsPerFile * historyMultiplier);
  const estimatedWriteMb = Math.max(0, files * m.writeMbPerFile);

  return Object.freeze({
    contract: CONTRACTS.COST_ESTIMATE,
    estimatedMs: Number(estimatedMs.toFixed(3)),
    estimatedReadMb: Number(readMb.toFixed(3)),
    estimatedCpuMs: Number(estimatedCpuMs.toFixed(3)),
    estimatedWriteMb: Number(estimatedWriteMb.toFixed(3)),
    recommendedMode,
    model: freezeObject(m),
    historyApplied: historyMultiplier !== 1,
  });
}

class ExecutionTrace {
  constructor({ buildId = newId("build"), schedulerDecision = null, resourcePolicy = null, startedAt = nowIso() } = {}) {
    this.buildId = buildId;
    this.startedAt = startedAt;
    this.schedulerDecision = schedulerDecision;
    this.resourcePolicy = resourcePolicy ? normalizeResourcePolicy(resourcePolicy) : null;
    this.events = [];
    this.record("TRACE_STARTED", { schedulerDecision: schedulerDecision?.decision || null });
  }

  record(event, details = {}) {
    const entry = Object.freeze({
      at: nowIso(),
      event: String(event || "EVENT"),
      details: freezeObject(details),
    });
    this.events.push(entry);
    return entry;
  }

  snapshot(extra = {}) {
    return Object.freeze({
      contract: CONTRACTS.EXECUTION_TRACE,
      buildId: this.buildId,
      startedAt: this.startedAt,
      finishedAt: extra.finishedAt || null,
      schedulerDecision: this.schedulerDecision,
      resourcePolicy: this.resourcePolicy,
      events: freezeArray(this.events),
      eventCounts: countBy(this.events, (event) => event.event),
      ...extra,
    });
  }
}

function countBy(items, keyFn) {
  const out = {};
  for (const item of items || []) {
    const key = keyFn(item);
    out[key] = (out[key] || 0) + 1;
  }
  return Object.freeze(out);
}

function normalizeResourcePolicy(policy = {}) {
  const next = { ...DEFAULT_RESOURCE_POLICY, ...policy };
  return Object.freeze({
    contract: CONTRACTS.RESOURCE_POLICY,
    mode: next.mode,
    workerCount: Math.max(1, Math.floor(Number(next.workerCount || 1))),
    maxInFlightChunks: Math.max(1, Math.floor(Number(next.maxInFlightChunks || 1))),
    maxInFlightBytes: Math.max(1024 * 1024, Math.floor(Number(next.maxInFlightBytes || DEFAULT_RESOURCE_POLICY.maxInFlightBytes))),
    targetChunkBytes: Math.max(256 * 1024, Math.floor(Number(next.targetChunkBytes || DEFAULT_RESOURCE_POLICY.targetChunkBytes))),
    maxReadConcurrency: Math.max(1, Math.floor(Number(next.maxReadConcurrency || 1))),
    maxMemoryMb: Math.max(128, Math.floor(Number(next.maxMemoryMb || DEFAULT_RESOURCE_POLICY.maxMemoryMb))),
  });
}

function createRuntimeHealth({
  eventLoopDelayP95 = 0,
  mainThreadBlockedMs = 0,
  gcPauseMs = 0,
  serializationMs = 0,
  queuePressure = "LOW",
  memoryPressure = false,
  diskPressure = "LOW",
  workerUtilization = 0,
} = {}) {
  return Object.freeze({
    contract: CONTRACTS.RUNTIME_HEALTH,
    eventLoopDelayP95: Number(eventLoopDelayP95 || 0),
    mainThreadBlockedMs: Number(mainThreadBlockedMs || 0),
    gcPauseMs: Number(gcPauseMs || 0),
    serializationMs: Number(serializationMs || 0),
    queuePressure,
    memoryPressure: Boolean(memoryPressure),
    diskPressure,
    workerUtilization: clampNumber(workerUtilization, 0, 1),
  });
}

class AdaptiveResourceGovernor {
  constructor({
    policy = DEFAULT_RESOURCE_POLICY,
    thresholds = {},
  } = {}) {
    this.policy = normalizeResourcePolicy(policy);
    this.thresholds = Object.freeze({
      eventLoopDelayP95: 32,
      serializationMs: 250,
      mainThreadBlockedMs: 100,
      ...thresholds,
    });
    this.actions = [];
  }

  observe(healthInput = {}) {
    const health = healthInput.contract === CONTRACTS.RUNTIME_HEALTH ? healthInput : createRuntimeHealth(healthInput);
    const reasons = [];
    const actions = [];
    let next = { ...this.policy };

    if (health.eventLoopDelayP95 > this.thresholds.eventLoopDelayP95 || health.mainThreadBlockedMs > this.thresholds.mainThreadBlockedMs) {
      reasons.push("EVENT_LOOP_DELAY");
      actions.push(RESOURCE_ACTION.REDUCE_WORKERS, RESOURCE_ACTION.PAUSE_IO);
      next.workerCount = Math.max(1, next.workerCount - 1);
      next.maxInFlightChunks = Math.max(1, Math.floor(next.maxInFlightChunks / 2));
    }

    if (health.serializationMs > this.thresholds.serializationMs) {
      reasons.push("SERIALIZATION_OVERHEAD");
      actions.push(RESOURCE_ACTION.REDUCE_CHUNK_SIZE);
      next.targetChunkBytes = Math.max(256 * 1024, Math.floor(next.targetChunkBytes / 2));
      next.maxInFlightBytes = Math.max(1024 * 1024, Math.floor(next.maxInFlightBytes / 2));
    }

    if (health.memoryPressure || health.diskPressure === "HIGH" || health.queuePressure === "HIGH") {
      reasons.push(health.memoryPressure ? "MEMORY_PRESSURE" : health.diskPressure === "HIGH" ? "DISK_PRESSURE" : "QUEUE_PRESSURE");
      actions.push(RESOURCE_ACTION.REDUCE_WORKERS);
      next.workerCount = Math.max(1, next.workerCount - 1);
      next.maxReadConcurrency = Math.max(1, next.maxReadConcurrency - 1);
    }

    if (actions.length === 0 && health.workerUtilization > 0.9 && this.policy.workerCount < 8) {
      reasons.push("HIGH_WORKER_UTILIZATION");
      actions.push(RESOURCE_ACTION.INCREASE_WORKERS);
      next.workerCount = this.policy.workerCount + 1;
    }

    if (actions.length === 0) {
      reasons.push("WITHIN_BUDGET");
      actions.push(RESOURCE_ACTION.KEEP);
    }

    this.policy = normalizeResourcePolicy(next);
    const decision = Object.freeze({
      health,
      actions: freezeArray([...new Set(actions)]),
      reasons: freezeArray(reasons),
      nextPolicy: this.policy,
    });
    this.actions.push(decision);
    return decision;
  }

  snapshot() {
    return Object.freeze({
      contract: CONTRACTS.RESOURCE_POLICY,
      policy: this.policy,
      decisions: freezeArray(this.actions),
    });
  }
}

function measureSerializationOverhead(value) {
  const startedAt = Date.now();
  const json = JSON.stringify(value ?? null);
  JSON.parse(json);
  const serializationMs = Date.now() - startedAt;
  return Object.freeze({
    serializationMs,
    bytes: Buffer.byteLength(json, "utf8"),
  });
}

function evaluateSnapshotQuality({
  previousStats = {},
  nextStats = {},
  failedFiles = 0,
  stalePartitions = 0,
  coverage = 1,
  thresholds = {},
} = {}) {
  const t = { ...DEFAULT_QUALITY_THRESHOLDS, ...thresholds };
  const previousEdges = Math.max(0, Number(previousStats.edges || 0));
  const nextEdges = Math.max(0, Number(nextStats.edges || 0));
  const previousUnresolved = Math.max(0, Number(previousStats.unresolved || 0));
  const nextUnresolved = Math.max(0, Number(nextStats.unresolved || 0));
  const unresolvedDelta = nextUnresolved - previousUnresolved;
  const edgeDropRate = previousEdges > 0 ? Math.max(0, previousEdges - nextEdges) / previousEdges : 0;
  const reasons = [];

  if (coverage < t.minCoverage) reasons.push("LOW_COVERAGE");
  if (failedFiles > t.maxFailedFiles) reasons.push("FAILED_FILES");
  if (unresolvedDelta > t.maxUnresolvedDelta) reasons.push("UNRESOLVED_SPIKE");
  if (edgeDropRate > t.maxEdgeDropRate) reasons.push("EDGE_DROP_RATE");
  if (stalePartitions > 0) reasons.push("STALE_PARTITIONS");

  let decision = QUALITY_DECISION.PUBLISH;
  if (reasons.includes("LOW_COVERAGE") || reasons.includes("UNRESOLVED_SPIKE") || reasons.includes("EDGE_DROP_RATE")) {
    decision = QUALITY_DECISION.KEEP_PREVIOUS;
  } else if (reasons.includes("FAILED_FILES") || reasons.includes("STALE_PARTITIONS")) {
    decision = QUALITY_DECISION.PUBLISH_PARTIAL;
  }

  return Object.freeze({
    contract: CONTRACTS.QUALITY_REPORT,
    decision,
    reasons: freezeArray(reasons.length ? reasons : ["QUALITY_OK"]),
    coverage: Number(coverage),
    stalePartitions: Math.max(0, Number(stalePartitions || 0)),
    failedFiles: Math.max(0, Number(failedFiles || 0)),
    unresolvedDelta,
    edgeDropRate: Number(edgeDropRate.toFixed(6)),
    previousStats: freezeObject(previousStats),
    nextStats: freezeObject(nextStats),
  });
}

class BuildHistoryStore {
  constructor({ filePath = null, maxEntries = 100 } = {}) {
    this.filePath = filePath ? path.resolve(filePath) : null;
    this.maxEntries = Math.max(1, Number(maxEntries || 100));
    this.entries = [];
  }

  record(entry = {}) {
    const record = Object.freeze({
      contract: CONTRACTS.BUILD_HISTORY_RECORD,
      buildId: entry.buildId || newId("build"),
      at: entry.at || nowIso(),
      mode: entry.mode || BUILD_MODE.BACKGROUND_NORMAL,
      workers: Math.max(0, Number(entry.workers || 0)),
      durationMs: Math.max(0, Number(entry.durationMs || 0)),
      diskPressure: entry.diskPressure || "LOW",
      eventLoopDelayP95: Math.max(0, Number(entry.eventLoopDelayP95 || 0)),
      serializationMs: Math.max(0, Number(entry.serializationMs || 0)),
      snapshotDecision: entry.snapshotDecision || QUALITY_DECISION.PUBLISH,
      nextRecommendation: freezeObject(entry.nextRecommendation || {}),
    });
    this.entries.push(record);
    if (this.entries.length > this.maxEntries) this.entries.splice(0, this.entries.length - this.maxEntries);
    if (this.filePath) {
      fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
      fs.appendFileSync(this.filePath, `${JSON.stringify(record)}\n`, "utf8");
    }
    return record;
  }

  recommend(defaultPolicy = DEFAULT_RESOURCE_POLICY) {
    const recent = this.entries.slice(-10);
    if (!recent.length) return normalizeResourcePolicy(defaultPolicy);
    const highPressure = recent.filter(
      (entry) => entry.diskPressure === "HIGH" || entry.eventLoopDelayP95 > 32 || entry.serializationMs > 250,
    ).length;
    const avgWorkers = recent.reduce((sum, entry) => sum + Number(entry.workers || 0), 0) / recent.length;
    const next = { ...defaultPolicy };
    if (highPressure >= Math.ceil(recent.length / 2)) {
      next.workerCount = Math.max(1, Math.floor(avgWorkers || next.workerCount) - 1);
      next.targetChunkBytes = Math.max(256 * 1024, Math.floor(next.targetChunkBytes / 2));
    }
    return normalizeResourcePolicy(next);
  }

  snapshot() {
    return Object.freeze({
      entries: freezeArray(this.entries),
      count: this.entries.length,
    });
  }
}

function buildPriorityPlan(items = []) {
  const scored = Array.from(items || []).map((item) => {
    let priority = Number(item.priority || 0);
    if (item.currentWorkspace) priority += 100;
    if (item.visibleGraphNeighborhood) priority += 90;
    if (item.backbone) priority += 80;
    if (item.peopleIndex) priority += 70;
    if (item.currentYear) priority += 50;
    if (item.archive) priority += 10;
    return Object.freeze({ ...item, priority });
  });
  scored.sort((a, b) => b.priority - a.priority || String(a.path || "").localeCompare(String(b.path || ""), "en"));
  return Object.freeze({
    contract: CONTRACTS.PRIORITY_PLAN,
    items: freezeArray(scored),
    count: scored.length,
  });
}

module.exports = {
  CONTRACTS,
  SCHEDULER_DECISION,
  BUILD_MODE,
  QUALITY_DECISION,
  RESOURCE_ACTION,
  AdaptiveResourceGovernor,
  BuildHistoryStore,
  ExecutionTrace,
  buildPriorityPlan,
  createBuildIntent,
  createRuntimeHealth,
  estimateBuildCost,
  evaluateSnapshotQuality,
  measureSerializationOverhead,
  normalizeResourcePolicy,
  scheduleBuild,
};
