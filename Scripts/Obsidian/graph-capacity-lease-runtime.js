const crypto = require("crypto");
const os = require("os");

const CONTRACTS = Object.freeze({
  CAPACITY_ENVELOPE: "GraphCapacityEnvelope/v21.0",
  ADMISSION_DECISION: "GraphAdmissionDecision/v21.0",
  RESOURCE_LEASE: "GraphResourceLease/v21.0",
  WATERMARK_POLICY: "GraphWatermarkPolicy/v21.0",
  WATERMARK_DECISION: "GraphWatermarkDecision/v21.0",
  BROWNOUT_DECISION: "GraphBrownoutDecision/v21.0",
  SHEDDING_PLAN: "GraphSheddingPlan/v21.0",
  SNAPSHOT_TRUTH: "GraphSnapshotTruth/v21.0",
  CONTAINMENT_DECISION: "GraphContainmentDecision/v21.0",
});

const ADMISSION_DECISION = Object.freeze({
  START_NOW: "START_NOW",
  START_DEGRADED: "START_DEGRADED",
  DEFER: "DEFER",
  REJECT: "REJECT",
  REPAIR_ONLY: "REPAIR_ONLY",
});

const LEASE_STATUS = Object.freeze({
  ACTIVE: "active",
  REDUCED: "reduced",
  REVOKED: "revoked",
  EXPIRED: "expired",
  RELEASED: "released",
  DENIED: "denied",
});

const WATERMARK_LEVEL = Object.freeze({
  NORMAL: "NORMAL",
  SOFT: "SOFT",
  HARD: "HARD",
  CRITICAL: "CRITICAL",
  RECOVERY: "RECOVERY",
});

const BROWNOUT_LEVEL = Object.freeze({
  NONE: "NONE",
  LIGHT: "LIGHT",
  MODERATE: "MODERATE",
  SEVERE: "SEVERE",
});

const TRUTH_LABEL = Object.freeze({
  COMPLETE: "COMPLETE",
  PARTIAL_FRESH: "PARTIAL_FRESH",
  PARTIAL_STALE: "PARTIAL_STALE",
  DEGRADED_CACHE_ONLY: "DEGRADED_CACHE_ONLY",
  PREVIOUS_ACTIVE: "PREVIOUS_ACTIVE",
  REPAIR_ONLY: "REPAIR_ONLY",
});

const CONTAINMENT_ACTION = Object.freeze({
  ALLOW: "ALLOW",
  PUBLISH_WITHOUT_PARTITION: "PUBLISH_WITHOUT_PARTITION",
  KEEP_PREVIOUS_PARTITION: "KEEP_PREVIOUS_PARTITION",
  DISABLE_PRODUCER: "DISABLE_PRODUCER",
  OPEN_INCIDENT: "OPEN_INCIDENT",
  REPAIR_ONLY: "REPAIR_ONLY",
});

const DEFAULT_CAPACITY = Object.freeze({
  workers: 4,
  memoryMb: 1024,
  ioMbSec: 120,
  queueBytes: 64 * 1024 * 1024,
  publishBudgetMs: 8,
});

function nowIso(nowMs = Date.now()) {
  return new Date(nowMs).toISOString();
}

function newId(prefix) {
  if (typeof crypto.randomUUID === "function") return `${prefix}-${crypto.randomUUID()}`;
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
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

function positiveNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) && number >= 0 ? number : fallback;
}

function normalizeResources(resources = {}) {
  return Object.freeze({
    workers: Math.max(0, Math.floor(Number(resources.workers || 0))),
    memoryMb: positiveNumber(resources.memoryMb, 0),
    ioMbSec: positiveNumber(resources.ioMbSec, 0),
    queueBytes: positiveNumber(resources.queueBytes, 0),
    publishBudgetMs: positiveNumber(resources.publishBudgetMs, 0),
  });
}

function addResources(a = {}, b = {}) {
  return {
    workers: positiveNumber(a.workers) + positiveNumber(b.workers),
    memoryMb: positiveNumber(a.memoryMb) + positiveNumber(b.memoryMb),
    ioMbSec: positiveNumber(a.ioMbSec) + positiveNumber(b.ioMbSec),
    queueBytes: positiveNumber(a.queueBytes) + positiveNumber(b.queueBytes),
    publishBudgetMs: positiveNumber(a.publishBudgetMs) + positiveNumber(b.publishBudgetMs),
  };
}

function subtractResources(a = {}, b = {}) {
  return {
    workers: Math.max(0, positiveNumber(a.workers) - positiveNumber(b.workers)),
    memoryMb: Math.max(0, positiveNumber(a.memoryMb) - positiveNumber(b.memoryMb)),
    ioMbSec: Math.max(0, positiveNumber(a.ioMbSec) - positiveNumber(b.ioMbSec)),
    queueBytes: Math.max(0, positiveNumber(a.queueBytes) - positiveNumber(b.queueBytes)),
    publishBudgetMs: Math.max(0, positiveNumber(a.publishBudgetMs) - positiveNumber(b.publishBudgetMs)),
  };
}

function fitsWithin(requested = {}, capacity = {}, used = {}) {
  const after = addResources(used, requested);
  return (
    after.workers <= positiveNumber(capacity.workers) &&
    after.memoryMb <= positiveNumber(capacity.memoryMb) &&
    after.ioMbSec <= positiveNumber(capacity.ioMbSec) &&
    after.queueBytes <= positiveNumber(capacity.queueBytes) &&
    after.publishBudgetMs <= positiveNumber(capacity.publishBudgetMs)
  );
}

function createCapacityEnvelope({
  staticCapacity = {},
  observed = {},
  effective = {},
  confidence = 0.5,
  ttlMs = 30000,
  nowMs = Date.now(),
  lastCalibration = null,
} = {}) {
  const logicalCores = Math.max(1, Math.floor(Number(staticCapacity.logicalCores || os.cpus()?.length || 1)));
  const totalMemoryMb = Math.max(1, Math.floor(Number(staticCapacity.totalMemoryMb || os.totalmem() / 1024 / 1024)));
  const normalizedTtlMs = Math.max(0, Number(ttlMs || 0));
  const expiresAtMs = Number(nowMs) + normalizedTtlMs;
  const observedRead = positiveNumber(observed.readMbSec, 0);
  const observedCompiler = positiveNumber(observed.compilerFactsSec, 0);
  const observedPublish = positiveNumber(observed.publishCriticalSectionMs, 0);

  return Object.freeze({
    contract: CONTRACTS.CAPACITY_ENVELOPE,
    static: Object.freeze({
      logicalCores,
      totalMemoryMb,
      platform: staticCapacity.platform || process.platform,
    }),
    observed: Object.freeze({
      readMbSec: observedRead,
      compilerFactsSec: observedCompiler,
      publishCriticalSectionMs: observedPublish,
      diskLatencyMs: positiveNumber(observed.diskLatencyMs, 0),
      memoryPressure: Boolean(observed.memoryPressure),
    }),
    effective: Object.freeze({
      maxWorkersNow: Math.max(1, Math.floor(Number(effective.maxWorkersNow || Math.max(1, Math.floor(logicalCores / 2))))),
      maxReadMbSecNow: positiveNumber(effective.maxReadMbSecNow, observedRead || DEFAULT_CAPACITY.ioMbSec),
      maxQueueBytesNow: positiveNumber(effective.maxQueueBytesNow, DEFAULT_CAPACITY.queueBytes),
      maxMemoryMbNow: positiveNumber(effective.maxMemoryMbNow, Math.min(totalMemoryMb * 0.25, DEFAULT_CAPACITY.memoryMb)),
      publishBudgetMs: positiveNumber(effective.publishBudgetMs, DEFAULT_CAPACITY.publishBudgetMs),
    }),
    confidence: clampNumber(confidence, 0, 1),
    ttlMs: normalizedTtlMs,
    expiresAt: nowIso(expiresAtMs),
    expiresAtMs,
    lastCalibration: lastCalibration || nowIso(nowMs),
  });
}

function isEnvelopeExpired(envelope, nowMs = Date.now()) {
  return !envelope || Number(nowMs) >= Number(envelope.expiresAtMs || 0);
}

function createAdmissionDecision({ decision, reasons = [], allowedResources = {}, degraded = false } = {}) {
  return Object.freeze({
    contract: CONTRACTS.ADMISSION_DECISION,
    decision,
    degraded: Boolean(degraded),
    reasons: freezeArray([...new Set(reasons)]),
    allowedResources: normalizeResources(allowedResources),
    decidedAt: nowIso(),
  });
}

function evaluateAdmission({
  intent = {},
  envelope = createCapacityEnvelope(),
  pressure = {},
  activeLeases = [],
  thresholds = {},
  nowMs = Date.now(),
} = {}) {
  const reasons = [];
  const changedFiles = Math.max(0, Number(intent.changedFiles || 0));
  const fullRebuild = Boolean(intent.fullRebuild || changedFiles >= Number(thresholds.fullRebuildFiles || 100000));
  const uiActive = Boolean(intent.userActive || pressure.uiActive);
  const diskLatencyHigh = Number(pressure.diskLatencyMs || envelope.observed.diskLatencyMs || 0) > Number(thresholds.diskLatencyMs || 60);
  const memoryPressure = Boolean(pressure.memoryPressure || envelope.observed.memoryPressure);
  const repairOnly = Boolean(intent.repairOnly);

  if (repairOnly) {
    reasons.push("repair-only-intent");
    return createAdmissionDecision({
      decision: ADMISSION_DECISION.REPAIR_ONLY,
      reasons,
      allowedResources: { workers: 1, memoryMb: 128, queueBytes: 1024 * 1024, publishBudgetMs: envelope.effective.publishBudgetMs },
      degraded: true,
    });
  }

  if (isEnvelopeExpired(envelope, nowMs)) {
    reasons.push("capacity-envelope-expired");
    return createAdmissionDecision({ decision: ADMISSION_DECISION.DEFER, reasons, degraded: true });
  }

  if (pressure.critical || Number(pressure.eventLoopDelayP95 || 0) > Number(thresholds.eventLoopDelayP95 || 64)) {
    reasons.push("critical-pressure");
    return createAdmissionDecision({ decision: ADMISSION_DECISION.REJECT, reasons, degraded: true });
  }

  if (fullRebuild && uiActive && diskLatencyHigh) {
    reasons.push("full-rebuild-ui-active-disk-latency");
    return createAdmissionDecision({ decision: ADMISSION_DECISION.DEFER, reasons, degraded: true });
  }

  const used = activeLeases
    .filter((lease) => lease.status === LEASE_STATUS.ACTIVE || lease.status === LEASE_STATUS.REDUCED)
    .reduce((sum, lease) => addResources(sum, lease.resources), normalizeResources());
  const allowedResources = normalizeResources({
    workers: Math.max(1, envelope.effective.maxWorkersNow - used.workers),
    memoryMb: Math.max(0, envelope.effective.maxMemoryMbNow - used.memoryMb),
    ioMbSec: Math.max(0, envelope.effective.maxReadMbSecNow - used.ioMbSec),
    queueBytes: Math.max(0, envelope.effective.maxQueueBytesNow - used.queueBytes),
    publishBudgetMs: envelope.effective.publishBudgetMs,
  });

  if (envelope.confidence < Number(thresholds.minConfidence || 0.75) || memoryPressure || diskLatencyHigh) {
    if (envelope.confidence < Number(thresholds.minConfidence || 0.75)) reasons.push("low-capacity-confidence");
    if (memoryPressure) reasons.push("memory-pressure");
    if (diskLatencyHigh) reasons.push("disk-latency-high");
    return createAdmissionDecision({
      decision: ADMISSION_DECISION.START_DEGRADED,
      reasons,
      degraded: true,
      allowedResources: {
        ...allowedResources,
        workers: Math.max(1, Math.floor(allowedResources.workers / 2)),
        queueBytes: Math.max(1024 * 1024, Math.floor(allowedResources.queueBytes / 2)),
      },
    });
  }

  reasons.push("capacity-admitted");
  return createAdmissionDecision({
    decision: ADMISSION_DECISION.START_NOW,
    reasons,
    allowedResources,
  });
}

function createLeaseRecord({
  leaseId = newId("lease"),
  owner,
  resources = {},
  priority = 0,
  ttlMs = 5000,
  nowMs = Date.now(),
  revocable = true,
  status = LEASE_STATUS.ACTIVE,
  reason = null,
} = {}) {
  if (!owner) throw new Error("GraphResourceLease requires owner");
  const expiresAtMs = Number(nowMs) + Math.max(0, Number(ttlMs || 0));
  return Object.freeze({
    contract: CONTRACTS.RESOURCE_LEASE,
    leaseId,
    owner,
    resources: normalizeResources(resources),
    priority: Number(priority || 0),
    expiresAt: nowIso(expiresAtMs),
    expiresAtMs,
    revocable: Boolean(revocable),
    status,
    reason,
  });
}

class ResourceLeaseManager {
  constructor({ capacity = DEFAULT_CAPACITY } = {}) {
    this.capacity = normalizeResources(capacity);
    this.leases = new Map();
    this.events = [];
  }

  snapshot(nowMs = Date.now()) {
    this.expireLeases(nowMs);
    const leases = Array.from(this.leases.values());
    return Object.freeze({
      capacity: this.capacity,
      used: this.usedResources(nowMs),
      leases: freezeArray(leases),
      events: freezeArray(this.events),
    });
  }

  usedResources(nowMs = Date.now()) {
    this.expireLeases(nowMs);
    return normalizeResources(
      Array.from(this.leases.values())
        .filter((lease) => lease.status === LEASE_STATUS.ACTIVE || lease.status === LEASE_STATUS.REDUCED)
        .reduce((sum, lease) => addResources(sum, lease.resources), normalizeResources()),
    );
  }

  requestLease(request = {}) {
    const nowMs = Number(request.nowMs || Date.now());
    this.expireLeases(nowMs);
    const requested = normalizeResources(request.resources || {});
    const revoked = [];

    if (!fitsWithin(requested, this.capacity, this.usedResources(nowMs))) {
      const candidates = Array.from(this.leases.values())
        .filter((lease) => lease.revocable && lease.priority < Number(request.priority || 0) && lease.status === LEASE_STATUS.ACTIVE)
        .sort((a, b) => a.priority - b.priority || a.expiresAtMs - b.expiresAtMs);
      for (const lease of candidates) {
        const revokedLease = this.revokeLease(lease.leaseId, "preempted-by-higher-priority-lease");
        revoked.push(revokedLease);
        if (fitsWithin(requested, this.capacity, this.usedResources(nowMs))) break;
      }
    }

    if (!fitsWithin(requested, this.capacity, this.usedResources(nowMs))) {
      const denied = createLeaseRecord({
        ...request,
        resources: requested,
        nowMs,
        status: LEASE_STATUS.DENIED,
        reason: "capacity-exceeded",
      });
      this.events.push(Object.freeze({ event: "LEASE_DENIED", leaseId: denied.leaseId, owner: denied.owner, at: nowIso(nowMs) }));
      return Object.freeze({ granted: false, lease: denied, revoked: freezeArray(revoked) });
    }

    const lease = createLeaseRecord({ ...request, resources: requested, nowMs, status: LEASE_STATUS.ACTIVE });
    this.leases.set(lease.leaseId, lease);
    this.events.push(Object.freeze({ event: "LEASE_GRANTED", leaseId: lease.leaseId, owner: lease.owner, at: nowIso(nowMs) }));
    return Object.freeze({ granted: true, lease, revoked: freezeArray(revoked) });
  }

  reduceLease(leaseId, resources, reason = "lease-reduced") {
    const current = this.leases.get(leaseId);
    if (!current) return null;
    const reduced = Object.freeze({
      ...current,
      resources: normalizeResources(resources),
      status: LEASE_STATUS.REDUCED,
      reason,
    });
    this.leases.set(leaseId, reduced);
    this.events.push(Object.freeze({ event: "LEASE_REDUCED", leaseId, owner: current.owner, at: nowIso() }));
    return reduced;
  }

  revokeLease(leaseId, reason = "lease-revoked") {
    const current = this.leases.get(leaseId);
    if (!current) return null;
    const revoked = Object.freeze({ ...current, status: LEASE_STATUS.REVOKED, reason });
    this.leases.set(leaseId, revoked);
    this.events.push(Object.freeze({ event: "LEASE_REVOKED", leaseId, owner: current.owner, at: nowIso() }));
    return revoked;
  }

  expireLeases(nowMs = Date.now()) {
    const expired = [];
    for (const lease of this.leases.values()) {
      if ((lease.status === LEASE_STATUS.ACTIVE || lease.status === LEASE_STATUS.REDUCED) && Number(nowMs) >= lease.expiresAtMs) {
        const next = Object.freeze({ ...lease, status: LEASE_STATUS.EXPIRED, reason: "lease-expired" });
        this.leases.set(lease.leaseId, next);
        this.events.push(Object.freeze({ event: "LEASE_EXPIRED", leaseId: lease.leaseId, owner: lease.owner, at: nowIso(nowMs) }));
        expired.push(next);
      }
    }
    return freezeArray(expired);
  }
}

function createWatermarkPolicy({
  metric,
  soft,
  hard,
  critical,
  recovery,
  cooldownMs = 5000,
  hysteresisWindowMs = 10000,
} = {}) {
  if (!metric) throw new Error("GraphWatermarkPolicy requires metric");
  return Object.freeze({
    contract: CONTRACTS.WATERMARK_POLICY,
    metric,
    soft: Number(soft),
    hard: Number(hard),
    critical: Number(critical),
    recovery: Number(recovery),
    cooldownMs: Math.max(0, Number(cooldownMs || 0)),
    hysteresisWindowMs: Math.max(0, Number(hysteresisWindowMs || 0)),
  });
}

function evaluateWatermark({
  policy,
  value,
  previousLevel = WATERMARK_LEVEL.NORMAL,
  levelSinceMs = 0,
  nowMs = Date.now(),
} = {}) {
  const p = policy.contract === CONTRACTS.WATERMARK_POLICY ? policy : createWatermarkPolicy(policy);
  const numericValue = Number(value || 0);
  const elapsedMs = Math.max(0, Number(nowMs || 0) - Number(levelSinceMs || 0));
  let level = WATERMARK_LEVEL.NORMAL;
  const actions = [];

  if (numericValue >= p.critical) level = WATERMARK_LEVEL.CRITICAL;
  else if (numericValue >= p.hard) level = WATERMARK_LEVEL.HARD;
  else if (numericValue >= p.soft) level = WATERMARK_LEVEL.SOFT;
  else if (previousLevel !== WATERMARK_LEVEL.NORMAL && numericValue <= p.recovery) {
    level = elapsedMs >= p.hysteresisWindowMs ? WATERMARK_LEVEL.RECOVERY : previousLevel;
  }

  if (level === WATERMARK_LEVEL.SOFT) actions.push("stop-low-priority");
  if (level === WATERMARK_LEVEL.HARD) actions.push("reduce-producers", "enter-brownout");
  if (level === WATERMARK_LEVEL.CRITICAL) actions.push("emergency-mode", "revoke-low-priority");
  if (level === WATERMARK_LEVEL.RECOVERY) actions.push("recover-gradually");

  return Object.freeze({
    contract: CONTRACTS.WATERMARK_DECISION,
    metric: p.metric,
    value: numericValue,
    level,
    actions: freezeArray(actions),
    previousLevel,
    elapsedMs,
  });
}

function decideBrownout({ watermarkDecisions = [], pressure = {}, admission = null } = {}) {
  const levels = Array.from(watermarkDecisions || []).map((decision) => decision.level || WATERMARK_LEVEL.NORMAL);
  let level = BROWNOUT_LEVEL.NONE;
  if (levels.includes(WATERMARK_LEVEL.CRITICAL) || pressure.critical) level = BROWNOUT_LEVEL.SEVERE;
  else if (levels.includes(WATERMARK_LEVEL.HARD) || pressure.hard) level = BROWNOUT_LEVEL.MODERATE;
  else if (levels.includes(WATERMARK_LEVEL.SOFT) || admission?.degraded) level = BROWNOUT_LEVEL.LIGHT;

  const disabled = [];
  const preserved = ["current graph safety", "changed-file core indexing", "snapshot integrity", "UI SLA", "quality gate"];
  if (level === BROWNOUT_LEVEL.LIGHT) disabled.push("dashboard-detail", "historical-metrics-export");
  if (level === BROWNOUT_LEVEL.MODERATE || level === BROWNOUT_LEVEL.SEVERE) {
    disabled.push("dashboard-detail", "deep-validation", "layout-prep", "speculative-prewarm", "people-scan");
  }
  if (level === BROWNOUT_LEVEL.SEVERE) disabled.push("archive-rebuild", "noncritical-validation");

  return Object.freeze({
    contract: CONTRACTS.BROWNOUT_DECISION,
    level,
    disabled: freezeArray([...new Set(disabled)]),
    preserved: freezeArray(preserved),
    reasons: freezeArray([...new Set([...(admission?.reasons || []), ...(watermarkDecisions || []).map((item) => `${item.metric}:${item.level}`)])]),
  });
}

function createSheddingPlan({ cancelTaskIds = [], dependencyGraph = {}, generation = null, reason = "load-shedding" } = {}) {
  const cancelled = new Set(cancelTaskIds);
  let changed = true;
  while (changed) {
    changed = false;
    for (const [taskId, dependencies] of Object.entries(dependencyGraph || {})) {
      if (cancelled.has(taskId)) continue;
      if ((dependencies || []).some((dependency) => cancelled.has(dependency))) {
        cancelled.add(taskId);
        changed = true;
      }
    }
  }

  return Object.freeze({
    contract: CONTRACTS.SHEDDING_PLAN,
    generation,
    reason,
    cancelledTaskIds: freezeArray(cancelled),
    propagated: cancelled.size > cancelTaskIds.length,
  });
}

function inferTruthLabel({ coverage = {}, freshness = {}, missingPartitions = [], stalePartitions = [], degradedCacheOnly = false, previousActive = false, repairOnly = false } = {}) {
  if (repairOnly) return TRUTH_LABEL.REPAIR_ONLY;
  if (previousActive) return TRUTH_LABEL.PREVIOUS_ACTIVE;
  if (degradedCacheOnly) return TRUTH_LABEL.DEGRADED_CACHE_ONLY;
  if ((missingPartitions || []).length > 0 || (stalePartitions || []).length > 0) return TRUTH_LABEL.PARTIAL_STALE;
  const coverageValues = Object.values(coverage || {}).map(Number);
  const allFresh = Object.values(freshness || {}).every((value) => value === "fresh" || value === "complete");
  const allCovered = coverageValues.length > 0 && coverageValues.every((value) => value >= 1);
  if (allCovered && allFresh) return TRUTH_LABEL.COMPLETE;
  return TRUTH_LABEL.PARTIAL_FRESH;
}

function createSnapshotTruth({
  truthLabel = null,
  coverage = {},
  freshness = {},
  missingPartitions = [],
  stalePartitions = [],
  queryLimitations = [],
  visualWarning = null,
  degradedCacheOnly = false,
  previousActive = false,
  repairOnly = false,
} = {}) {
  const label = truthLabel || inferTruthLabel({ coverage, freshness, missingPartitions, stalePartitions, degradedCacheOnly, previousActive, repairOnly });
  const defaultWarning = label === TRUTH_LABEL.COMPLETE ? null : "Graph snapshot is not complete; freshness and coverage limits apply.";
  return Object.freeze({
    contract: CONTRACTS.SNAPSHOT_TRUTH,
    truthLabel: label,
    coverage: freezeObject(coverage),
    freshness: freezeObject(freshness),
    missingPartitions: freezeArray(missingPartitions),
    stalePartitions: freezeArray(stalePartitions),
    queryLimitations: freezeArray(queryLimitations),
    visualWarning: visualWarning || defaultWarning,
  });
}

function evaluateContainment({ partitionId, producer = null, metrics = {}, thresholds = {} } = {}) {
  if (!partitionId) throw new Error("GraphContainmentDecision requires partitionId");
  const t = {
    edgeMultiplier: 10,
    unresolvedDelta: 5000,
    parserFailures: 100,
    coverageMin: 0.5,
    ...thresholds,
  };
  const reasons = [];
  const actions = [];

  if (Number(metrics.edgeMultiplier || 0) >= t.edgeMultiplier) reasons.push("edge-count-explosion");
  if (Number(metrics.unresolvedDelta || 0) >= t.unresolvedDelta) reasons.push("unresolved-spike");
  if (Number(metrics.parserFailures || 0) >= t.parserFailures) reasons.push("parser-failures");
  if (Number(metrics.coverage || 1) < t.coverageMin) reasons.push("partition-coverage-collapse");
  if (metrics.malformedResult) reasons.push("malformed-worker-result");
  if (metrics.layoutInvalid) reasons.push("layout-invalid");

  if (reasons.length === 0) {
    actions.push(CONTAINMENT_ACTION.ALLOW);
  } else {
    actions.push(CONTAINMENT_ACTION.KEEP_PREVIOUS_PARTITION, CONTAINMENT_ACTION.DISABLE_PRODUCER, CONTAINMENT_ACTION.OPEN_INCIDENT);
    if (metrics.malformedResult || metrics.parserFailures >= t.parserFailures) actions.push(CONTAINMENT_ACTION.REPAIR_ONLY);
  }

  return Object.freeze({
    contract: CONTRACTS.CONTAINMENT_DECISION,
    partitionId,
    producer,
    actions: freezeArray([...new Set(actions)]),
    reasons: freezeArray(reasons),
    contained: reasons.length > 0,
  });
}

module.exports = {
  ADMISSION_DECISION,
  BROWNOUT_LEVEL,
  CONTAINMENT_ACTION,
  CONTRACTS,
  DEFAULT_CAPACITY,
  LEASE_STATUS,
  ResourceLeaseManager,
  TRUTH_LABEL,
  WATERMARK_LEVEL,
  createAdmissionDecision,
  createCapacityEnvelope,
  createLeaseRecord,
  createSheddingPlan,
  createSnapshotTruth,
  createWatermarkPolicy,
  decideBrownout,
  evaluateAdmission,
  evaluateContainment,
  evaluateWatermark,
  inferTruthLabel,
  isEnvelopeExpired,
  normalizeResources,
};
