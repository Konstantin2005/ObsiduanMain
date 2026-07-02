const { buildQueryPlan } = require("./graph-query-engine.js");
const { createFailureState, FAILURE_SEVERITY } = require("../Rendering/graph-critical-frame.js");
const { validateSnapshotDeep } = require("./graph-deep-validation.js");

function defer() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

class WorkerTaskController {
  constructor({ useWorker = false } = {}) {
    this.useWorker = useWorker;
    this.generation = 0;
    this.nextTaskId = 1;
    this.workerConfig = Object.freeze({
      workerCount: 2,
      chunkBytes: 4 * 1024 * 1024,
      maxInFlightBytes: 16 * 1024 * 1024,
      maxReadConcurrency: 2,
      pauseIoMs: 0,
      cacheOnlyLowPriority: false,
    });
  }

  setWorkerConfig(config = {}) {
    const next = { ...this.workerConfig };
    if (config.workerCount !== undefined) next.workerCount = Math.max(1, Math.floor(Number(config.workerCount)));
    if (config.chunkBytes !== undefined) next.chunkBytes = Math.max(64 * 1024, Math.floor(Number(config.chunkBytes)));
    if (config.maxInFlightBytes !== undefined) next.maxInFlightBytes = Math.max(next.chunkBytes, Math.floor(Number(config.maxInFlightBytes)));
    if (config.maxReadConcurrency !== undefined) next.maxReadConcurrency = Math.max(1, Math.floor(Number(config.maxReadConcurrency)));
    if (config.pauseIoMs !== undefined) next.pauseIoMs = Math.max(0, Number(config.pauseIoMs));
    if (config.cacheOnlyLowPriority !== undefined) next.cacheOnlyLowPriority = Boolean(config.cacheOnlyLowPriority);
    this.workerConfig = Object.freeze(next);
  }

  getWorkerConfig() {
    return this.workerConfig;
  }

  cancelStale(reason = "generation-cancelled") {
    this.generation += 1;
    return Object.freeze({
      generation: this.generation,
      reason,
    });
  }

  async scheduleTask({ type, payload = {}, handler }) {
    const taskId = this.nextTaskId;
    this.nextTaskId += 1;
    const generation = this.generation;
    try {
      await defer();
      const value = await handler(payload);
      if (generation !== this.generation) {
        return Object.freeze({
          ok: false,
          stale: true,
          taskId,
          generation,
          currentGeneration: this.generation,
          type,
          value: null,
          failureState: null,
        });
      }
      return Object.freeze({
        ok: true,
        stale: false,
        taskId,
        generation,
        currentGeneration: this.generation,
        type,
        value,
        failureState: null,
      });
    } catch (error) {
      return Object.freeze({
        ok: false,
        stale: false,
        taskId,
        generation,
        currentGeneration: this.generation,
        type,
        value: null,
        failureState: createFailureState({
          severity: FAILURE_SEVERITY.DEGRADED,
          code: "WORKER_TASK_FAILED",
          message: `${type} worker task failed`,
          cause: error,
        }),
      });
    }
  }

  runQuery(payload) {
    return this.scheduleTask({
      type: "query",
      payload,
      handler: ({ snapshot, filters = [], priorityNodeIds = [], edgePolicy = "visible", id = "worker-query" }) =>
        buildQueryPlan({ snapshot, filters, priorityNodeIds, edgePolicy, id }),
    });
  }

  runLayout(payload) {
    return this.scheduleTask({
      type: "layout",
      payload,
      handler: ({ snapshot }) => buildLayoutBounds(snapshot),
    });
  }

  runEdgeBatch(payload) {
    return this.scheduleTask({
      type: "edge-batch",
      payload,
      handler: ({ snapshot, nodeIds = [], edgeBudget = 1000, backboneOnly = false }) =>
        buildEdgeBatch({ snapshot, nodeIds, edgeBudget, backboneOnly }),
    });
  }

  runDeepValidation(payload) {
    return this.scheduleTask({
      type: "deep-validation",
      payload,
      handler: ({ snapshot, maxErrors = 100 }) => validateSnapshotDeep(snapshot, { maxErrors }),
    });
  }
}

function buildLayoutBounds(snapshot) {
  if (!snapshot || snapshot.contract !== "GraphSnapshot/v9.0") {
    throw new Error("layout task requires GraphSnapshot");
  }
  const { layoutX, layoutY } = snapshot.arrays;
  let minX = Infinity;
  let maxX = -Infinity;
  let minY = Infinity;
  let maxY = -Infinity;
  for (let index = 0; index < snapshot.nodeCount; index += 1) {
    const x = layoutX[index];
    const y = layoutY[index];
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
  return Object.freeze({
    minX: Number.isFinite(minX) ? minX : 0,
    maxX: Number.isFinite(maxX) ? maxX : 0,
    minY: Number.isFinite(minY) ? minY : 0,
    maxY: Number.isFinite(maxY) ? maxY : 0,
  });
}

function buildEdgeBatch({ snapshot, nodeIds = [], edgeBudget = 1000, backboneOnly = false } = {}) {
  if (!snapshot || snapshot.contract !== "GraphSnapshot/v9.0") {
    throw new Error("edge batch task requires GraphSnapshot");
  }
  const visible = new Uint8Array(snapshot.nodeCount);
  for (const nodeId of nodeIds) {
    const index = Number(nodeId);
    if (Number.isInteger(index) && index >= 0 && index < visible.length) visible[index] = 1;
  }
  const limit = Math.max(0, Math.floor(Number(edgeBudget)));
  const edges = new Uint32Array(limit);
  let count = 0;
  for (let edgeId = 0; edgeId < snapshot.edgeCount && count < limit; edgeId += 1) {
    const source = snapshot.arrays.edgeSources[edgeId];
    const target = snapshot.arrays.edgeTargets[edgeId];
    if (!visible[source] || !visible[target]) continue;
    if (backboneOnly && (snapshot.arrays.edgeFlags[edgeId] & 1) === 0) continue;
    edges[count] = edgeId;
    count += 1;
  }
  return Object.freeze({
    edges: edges.slice(0, count),
    skipped: Math.max(0, snapshot.edgeCount - count),
  });
}

module.exports = {
  WorkerTaskController,
  buildEdgeBatch,
  buildLayoutBounds,
};
