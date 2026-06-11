const crypto = require("crypto");

const CONTRACTS = Object.freeze({
  OPERATION_LOG: "IndexOperationLog/v14.0",
  OPERATION_EVENT: "IndexOperationEvent/v14.0",
  TRUST_DECISION: "IndexTrustDecision/v14.0",
  CHANGED_SET_PLAN: "IndexChangedSetPlan/v14.0",
  READ_AMPLIFICATION: "IndexReadAmplification/v14.0",
  SNAPSHOT_COMPATIBILITY: "IndexSnapshotCompatibility/v14.0",
});

const INDEX_MODE = Object.freeze({
  INTERACTIVE_LIGHT: "INTERACTIVE_LIGHT",
  BACKGROUND_NORMAL: "BACKGROUND_NORMAL",
  BACKGROUND_HEAVY: "BACKGROUND_HEAVY",
  VALIDATION_ONLY: "VALIDATION_ONLY",
  REPAIR: "REPAIR",
  FULL_REBUILD: "FULL_REBUILD",
});

const EVENT_CODE = Object.freeze({
  INDEX_RUN_STARTED: "INDEX_RUN_STARTED",
  MANIFEST_LOADED: "MANIFEST_LOADED",
  TRUST_CLASSIFIED: "TRUST_CLASSIFIED",
  RECORD_SHARD_CORRUPT: "RECORD_SHARD_CORRUPT",
  FILES_PARSED: "FILES_PARSED",
  RESOLVER_INVALIDATED: "RESOLVER_INVALIDATED",
  SNAPSHOT_STAGING_WRITTEN: "SNAPSHOT_STAGING_WRITTEN",
  SNAPSHOT_PUBLISHED: "SNAPSHOT_PUBLISHED",
  SNAPSHOT_REJECTED: "SNAPSHOT_REJECTED",
  FALLBACK_FULL_SCAN: "FALLBACK_FULL_SCAN",
  WARM_CACHE_DISABLED: "WARM_CACHE_DISABLED",
});

const TRUST_STATE = Object.freeze({
  UNCHANGED_TRUSTED: "UNCHANGED_TRUSTED",
  UNCHANGED_SUSPECT: "UNCHANGED_SUSPECT",
  CHANGED_STAT: "CHANGED_STAT",
  CHANGED_HASH: "CHANGED_HASH",
  DELETED: "DELETED",
  ADDED: "ADDED",
  RENAMED: "RENAMED",
  UNKNOWN: "UNKNOWN",
});

const TRUST_REASON = Object.freeze({
  QUICK_KEY_MATCH: "QUICK_KEY_MATCH",
  QUICK_KEY_CHANGED: "QUICK_KEY_CHANGED",
  MTIME_BACKWARDS: "MTIME_BACKWARDS",
  MTIME_RESOLUTION_RISK: "MTIME_RESOLUTION_RISK",
  CACHE_TOO_OLD: "CACHE_TOO_OLD",
  VAULT_EPOCH_CHANGED: "VAULT_EPOCH_CHANGED",
  SYNC_STORM_DETECTED: "SYNC_STORM_DETECTED",
  PARSER_VERSION_CHANGED: "PARSER_VERSION_CHANGED",
  RESOLVER_VERSION_CHANGED: "RESOLVER_VERSION_CHANGED",
  SCHEMA_VERSION_CHANGED: "SCHEMA_VERSION_CHANGED",
  RECORD_SHARD_MISSING: "RECORD_SHARD_MISSING",
  RECORD_SHARD_CORRUPT: "RECORD_SHARD_CORRUPT",
  SOURCE_DELETED: "SOURCE_DELETED",
  SOURCE_ADDED: "SOURCE_ADDED",
  RENAME_CANDIDATE: "RENAME_CANDIDATE",
  WARM_CACHE_DISABLED: "WARM_CACHE_DISABLED",
});

const TRUST_ACTION = Object.freeze({
  REUSE_RECORD: "REUSE_RECORD",
  HASH_VERIFY: "HASH_VERIFY",
  READ_AND_PARSE: "READ_AND_PARSE",
  REPARSE_AFFECTED: "REPARSE_AFFECTED",
  REBUILD_RESOLVER: "REBUILD_RESOLVER",
  FALLBACK_FULL_SCAN: "FALLBACK_FULL_SCAN",
  DISABLE_WARM_CACHE_FOR_RUN: "DISABLE_WARM_CACHE_FOR_RUN",
});

const PUBLISH_DECISION = Object.freeze({
  PUBLISHED: "PUBLISHED",
  REJECTED: "REJECTED",
  STALE_ON_PUBLISH: "STALE_ON_PUBLISH",
});

const MATERIALIZATION_MODE = Object.freeze({
  FULL_FROM_RECORDS: "FULL_FROM_RECORDS",
  EDGE_GROUP_REPLACEMENT: "EDGE_GROUP_REPLACEMENT",
  DELTA_GRAPH: "DELTA_GRAPH",
});

const DEFAULT_VERSIONS = Object.freeze({
  recordVersion: 14,
  parserVersion: 1,
  resolverVersion: 1,
  schemaVersion: 14,
});

const DEFAULT_READ_BUDGETS = Object.freeze({
  filesStat: Number.POSITIVE_INFINITY,
  markdownRead: Number.POSITIVE_INFINITY,
  recordShardsRead: Number.POSITIVE_INFINITY,
  overlayRecordsRead: Number.POSITIVE_INFINITY,
  resolverKeysRecomputed: Number.POSITIVE_INFINITY,
  snapshotBytesWritten: Number.POSITIVE_INFINITY,
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

function makeQuickKey(entry = {}) {
  return `${entry.path || ""}:${Number(entry.size ?? 0)}:${Number(entry.mtimeMs ?? 0)}`;
}

function normalizeEntry(entry = null) {
  if (!entry) return null;
  return Object.freeze({
    path: String(entry.path || ""),
    noteUuid: entry.noteUuid || null,
    quickKey: entry.quickKey || makeQuickKey(entry),
    size: Number(entry.size ?? 0),
    mtimeMs: Number(entry.mtimeMs ?? 0),
    contentHash: entry.contentHash || entry.sha256 || null,
    recordVersion: Number(entry.recordVersion ?? DEFAULT_VERSIONS.recordVersion),
    parserVersion: Number(entry.parserVersion ?? DEFAULT_VERSIONS.parserVersion),
    resolverVersion: Number(entry.resolverVersion ?? DEFAULT_VERSIONS.resolverVersion),
    schemaVersion: Number(entry.schemaVersion ?? DEFAULT_VERSIONS.schemaVersion),
    shardStatus: entry.shardStatus || "ok",
    recordBuiltAtMs: Number(entry.recordBuiltAtMs ?? 0),
  });
}

function countBy(items, keyFn) {
  const out = {};
  for (const item of items || []) {
    const key = keyFn(item);
    out[key] = (out[key] || 0) + 1;
  }
  return Object.freeze(out);
}

function createOperationEvent({ event, at = nowIso(), details = {} } = {}) {
  if (!Object.values(EVENT_CODE).includes(event)) {
    throw new Error(`Unknown index operation event: ${event}`);
  }
  return Object.freeze({
    contract: CONTRACTS.OPERATION_EVENT,
    at,
    event,
    details: freezeObject(details),
  });
}

class IndexOperationLog {
  constructor({ runId = newId("index-run"), mode = INDEX_MODE.BACKGROUND_NORMAL, startedAt = nowIso() } = {}) {
    this.runId = runId;
    this.mode = Object.values(INDEX_MODE).includes(mode) ? mode : INDEX_MODE.BACKGROUND_NORMAL;
    this.startedAt = startedAt;
    this.events = [];
    this.record(EVENT_CODE.INDEX_RUN_STARTED, { mode: this.mode });
  }

  record(event, details = {}) {
    const entry = createOperationEvent({ event, details: { runId: this.runId, ...details } });
    this.events.push(entry);
    return entry;
  }

  snapshot(extra = {}) {
    const events = freezeArray(this.events);
    return Object.freeze({
      contract: CONTRACTS.OPERATION_LOG,
      runId: this.runId,
      mode: this.mode,
      startedAt: this.startedAt,
      finishedAt: extra.finishedAt || null,
      events,
      eventCounts: countBy(events, (event) => event.event),
      ...extra,
    });
  }
}

class ReadAmplificationTracker {
  constructor({ budgets = {} } = {}) {
    this.budgets = Object.freeze({ ...DEFAULT_READ_BUDGETS, ...budgets });
    this.counters = {
      filesStat: 0,
      markdownRead: 0,
      recordShardsRead: 0,
      overlayRecordsRead: 0,
      resolverKeysRecomputed: 0,
      snapshotBytesWritten: 0,
    };
  }

  add(metric, amount = 1) {
    if (!Object.prototype.hasOwnProperty.call(this.counters, metric)) {
      throw new Error(`Unknown read amplification metric: ${metric}`);
    }
    this.counters[metric] += Math.max(0, Number(amount || 0));
    return this.snapshot();
  }

  observeTrustDecision(decision) {
    if (!decision || decision.contract !== CONTRACTS.TRUST_DECISION) return this.snapshot();
    if (decision.action === TRUST_ACTION.READ_AND_PARSE) this.add("markdownRead", 1);
    if (decision.action === TRUST_ACTION.REPARSE_AFFECTED && decision.state !== TRUST_STATE.DELETED) {
      this.add("markdownRead", 1);
    }
    if (decision.action === TRUST_ACTION.REPARSE_AFFECTED || decision.state === TRUST_STATE.DELETED) {
      this.add("resolverKeysRecomputed", 1);
    }
    if (decision.action === TRUST_ACTION.REBUILD_RESOLVER) this.add("resolverKeysRecomputed", 1);
    return this.snapshot();
  }

  snapshot() {
    const overBudget = {};
    for (const [metric, value] of Object.entries(this.counters)) {
      const budget = this.budgets[metric];
      if (Number.isFinite(budget) && value > budget) overBudget[metric] = { value, budget };
    }
    return Object.freeze({
      contract: CONTRACTS.READ_AMPLIFICATION,
      counters: freezeObject(this.counters),
      budgets: freezeObject(this.budgets),
      overBudget: freezeObject(overBudget),
      ok: Object.keys(overBudget).length === 0,
    });
  }
}

function classifyTrust({
  previousEntry = null,
  nextEntry = null,
  versions = {},
  cachePolicy = {},
  cacheEnabled = true,
  nowMs = Date.now(),
} = {}) {
  const previous = normalizeEntry(previousEntry);
  const next = normalizeEntry(nextEntry);
  const expected = { ...DEFAULT_VERSIONS, ...versions };
  const reasons = [];
  let state = TRUST_STATE.UNKNOWN;
  let action = TRUST_ACTION.HASH_VERIFY;
  const path = next?.path || previous?.path || "";

  if (!cacheEnabled) {
    return freezeTrustDecision({
      path,
      state: TRUST_STATE.UNKNOWN,
      reasons: [TRUST_REASON.WARM_CACHE_DISABLED],
      action: TRUST_ACTION.DISABLE_WARM_CACHE_FOR_RUN,
      previous,
      next,
    });
  }

  if (previous && !next) {
    return freezeTrustDecision({
      path,
      state: TRUST_STATE.DELETED,
      reasons: [TRUST_REASON.SOURCE_DELETED],
      action: TRUST_ACTION.REPARSE_AFFECTED,
      previous,
      next,
    });
  }

  if (!previous && next) {
    return freezeTrustDecision({
      path,
      state: TRUST_STATE.ADDED,
      reasons: [TRUST_REASON.SOURCE_ADDED],
      action: TRUST_ACTION.READ_AND_PARSE,
      previous,
      next,
    });
  }

  if (!previous && !next) {
    return freezeTrustDecision({
      path,
      state: TRUST_STATE.UNKNOWN,
      reasons: [TRUST_REASON.SCHEMA_VERSION_CHANGED],
      action: TRUST_ACTION.FALLBACK_FULL_SCAN,
      previous,
      next,
    });
  }

  if (previous.recordVersion !== expected.recordVersion || next.recordVersion !== expected.recordVersion) {
    reasons.push(TRUST_REASON.SCHEMA_VERSION_CHANGED);
    state = TRUST_STATE.UNCHANGED_SUSPECT;
    action = TRUST_ACTION.READ_AND_PARSE;
  }

  if (previous.parserVersion !== expected.parserVersion || next.parserVersion !== expected.parserVersion) {
    reasons.push(TRUST_REASON.PARSER_VERSION_CHANGED);
    state = TRUST_STATE.UNCHANGED_SUSPECT;
    action = TRUST_ACTION.READ_AND_PARSE;
  }

  if (previous.resolverVersion !== expected.resolverVersion || next.resolverVersion !== expected.resolverVersion) {
    reasons.push(TRUST_REASON.RESOLVER_VERSION_CHANGED);
    if (action !== TRUST_ACTION.READ_AND_PARSE) {
      state = TRUST_STATE.UNCHANGED_SUSPECT;
      action = TRUST_ACTION.REBUILD_RESOLVER;
    }
  }

  if (previous.schemaVersion !== expected.schemaVersion || next.schemaVersion !== expected.schemaVersion) {
    reasons.push(TRUST_REASON.SCHEMA_VERSION_CHANGED);
    state = TRUST_STATE.UNCHANGED_SUSPECT;
    action = TRUST_ACTION.READ_AND_PARSE;
  }

  if (next.shardStatus === "missing") {
    reasons.push(TRUST_REASON.RECORD_SHARD_MISSING);
    state = TRUST_STATE.UNCHANGED_SUSPECT;
    action = TRUST_ACTION.REPARSE_AFFECTED;
  } else if (next.shardStatus === "corrupt") {
    reasons.push(TRUST_REASON.RECORD_SHARD_CORRUPT);
    state = TRUST_STATE.UNCHANGED_SUSPECT;
    action = TRUST_ACTION.REPARSE_AFFECTED;
  }

  if (next.mtimeMs < previous.mtimeMs) {
    reasons.push(TRUST_REASON.MTIME_BACKWARDS);
    if (action === TRUST_ACTION.REUSE_RECORD || action === TRUST_ACTION.HASH_VERIFY) {
      state = TRUST_STATE.UNCHANGED_SUSPECT;
      action = TRUST_ACTION.HASH_VERIFY;
    }
  }

  const maxCacheAgeMs = Number(cachePolicy.maxCacheAgeMs || 0);
  if (maxCacheAgeMs > 0 && next.recordBuiltAtMs > 0 && nowMs - next.recordBuiltAtMs > maxCacheAgeMs) {
    reasons.push(TRUST_REASON.CACHE_TOO_OLD);
    if (action === TRUST_ACTION.REUSE_RECORD || action === TRUST_ACTION.HASH_VERIFY) {
      state = TRUST_STATE.UNCHANGED_SUSPECT;
      action = TRUST_ACTION.HASH_VERIFY;
    }
  }

  if (previous.quickKey === next.quickKey) {
    if (reasons.length === 0) {
      reasons.push(TRUST_REASON.QUICK_KEY_MATCH);
      state = TRUST_STATE.UNCHANGED_TRUSTED;
      action = TRUST_ACTION.REUSE_RECORD;
    }
  } else if (!reasons.includes(TRUST_REASON.MTIME_BACKWARDS)) {
    reasons.push(TRUST_REASON.QUICK_KEY_CHANGED);
    state = TRUST_STATE.CHANGED_STAT;
    action = TRUST_ACTION.READ_AND_PARSE;
  }

  if (previous.path !== next.path && previous.contentHash && previous.contentHash === next.contentHash) {
    reasons.push(TRUST_REASON.RENAME_CANDIDATE);
    state = TRUST_STATE.RENAMED;
    action = TRUST_ACTION.REPARSE_AFFECTED;
  }

  if (reasons.length === 0) {
    reasons.push(TRUST_REASON.QUICK_KEY_CHANGED);
    state = TRUST_STATE.CHANGED_STAT;
    action = TRUST_ACTION.READ_AND_PARSE;
  }

  return freezeTrustDecision({ path, state, reasons, action, previous, next });
}

function freezeTrustDecision({ path, state, reasons, action, previous, next }) {
  return Object.freeze({
    contract: CONTRACTS.TRUST_DECISION,
    path,
    state,
    reasons: freezeArray(reasons),
    action,
    previous: previous ? freezeObject(previous) : null,
    next: next ? freezeObject(next) : null,
  });
}

function entriesByPath(entries = []) {
  const out = new Map();
  for (const entry of entries || []) {
    const normalized = normalizeEntry(entry);
    if (normalized?.path) out.set(normalized.path, normalized);
  }
  return out;
}

function buildChangedSetPlan({
  previousManifest = [],
  nextManifest = [],
  versions = {},
  cachePolicy = {},
  cacheEnabled = true,
  operationLog = null,
  readTracker = null,
} = {}) {
  const previousByPath = entriesByPath(previousManifest);
  const nextByPath = entriesByPath(nextManifest);
  const allPaths = Array.from(new Set([...previousByPath.keys(), ...nextByPath.keys()])).sort();
  const tracker = readTracker || new ReadAmplificationTracker();
  tracker.add("filesStat", nextByPath.size);

  const decisions = allPaths.map((filePath) => {
    const decision = classifyTrust({
      previousEntry: previousByPath.get(filePath),
      nextEntry: nextByPath.get(filePath),
      versions,
      cachePolicy,
      cacheEnabled,
    });
    tracker.observeTrustDecision(decision);
    if (operationLog) {
      operationLog.record(EVENT_CODE.TRUST_CLASSIFIED, {
        path: decision.path,
        state: decision.state,
        reasons: decision.reasons,
        action: decision.action,
      });
    }
    return decision;
  });

  const stateCounts = countBy(decisions, (decision) => decision.state);
  const actionCounts = countBy(decisions, (decision) => decision.action);
  const reasonCounts = {};
  for (const decision of decisions) {
    for (const reason of decision.reasons) reasonCounts[reason] = (reasonCounts[reason] || 0) + 1;
  }

  return Object.freeze({
    contract: CONTRACTS.CHANGED_SET_PLAN,
    decisions: freezeArray(decisions),
    stateCounts,
    actionCounts,
    reasonCounts: freezeObject(reasonCounts),
    readAmplification: tracker.snapshot(),
    stats: Object.freeze({
      filesPrevious: previousByPath.size,
      filesNext: nextByPath.size,
      filesPlanned: decisions.length,
      filesToRead: decisions.filter((decision) => decision.action === TRUST_ACTION.READ_AND_PARSE).length,
      recordsReused: decisions.filter((decision) => decision.action === TRUST_ACTION.REUSE_RECORD).length,
      resolverInvalidations: decisions.filter((decision) => decision.action === TRUST_ACTION.REBUILD_RESOLVER).length,
    }),
  });
}

function createSnapshotCompatibility({
  snapshotSchemaVersion = 14,
  indexerVersion = "14.0",
  parserVersion = DEFAULT_VERSIONS.parserVersion,
  resolverVersion = DEFAULT_VERSIONS.resolverVersion,
  arrayVersion = 1,
  sourceManifestId,
  recordSetId,
  resolverCacheId,
  dependencyIndexId = null,
  operationRunId,
  buildMode = INDEX_MODE.BACKGROUND_NORMAL,
  materializationMode = MATERIALIZATION_MODE.FULL_FROM_RECORDS,
} = {}) {
  const missing = [];
  for (const [key, value] of Object.entries({ sourceManifestId, recordSetId, resolverCacheId, operationRunId })) {
    if (!value) missing.push(key);
  }
  return Object.freeze({
    contract: CONTRACTS.SNAPSHOT_COMPATIBILITY,
    ok: missing.length === 0,
    missing: freezeArray(missing),
    snapshotSchemaVersion,
    indexerVersion,
    parserVersion,
    resolverVersion,
    arrayVersion,
    sourceManifestId: sourceManifestId || null,
    recordSetId: recordSetId || null,
    resolverCacheId: resolverCacheId || null,
    dependencyIndexId,
    operationRunId: operationRunId || null,
    buildMode,
    materializationMode,
  });
}

module.exports = {
  CONTRACTS,
  INDEX_MODE,
  EVENT_CODE,
  TRUST_STATE,
  TRUST_REASON,
  TRUST_ACTION,
  PUBLISH_DECISION,
  MATERIALIZATION_MODE,
  IndexOperationLog,
  ReadAmplificationTracker,
  buildChangedSetPlan,
  classifyTrust,
  createOperationEvent,
  createSnapshotCompatibility,
  makeQuickKey,
};
