const fs = require("fs");
const path = require("path");

let nodePerformance = null;
try {
  ({ performance: nodePerformance } = require("perf_hooks"));
} catch (_) {
  nodePerformance = null;
}

const DEFAULT_CAMERA = Object.freeze({
  x: 0,
  y: 0,
  width: 1600,
  height: 1000,
  zoom: 1,
});

const DEFAULT_BUDGETS = Object.freeze({
  nodeBudget: 3000,
  edgeBudget: 1000,
  labelBudget: 0,
  frameBudgetMs: 16,
});

const FAILURE_SEVERITY = Object.freeze({
  RECOVERABLE: "recoverable",
  DEGRADED: "degraded",
  BLOCKING: "blocking",
  FATAL: "fatal",
});

const NODE_ARRAY_SPECS = Object.freeze([
  Object.freeze({ key: "nodesIds", prop: "nodeIds", ctor: Uint32Array, count: "node" }),
  Object.freeze({ key: "nodesType", prop: "nodeTypes", ctor: Uint16Array, count: "node" }),
  Object.freeze({ key: "nodesFlags", prop: "nodeFlags", ctor: Uint32Array, count: "node" }),
  Object.freeze({ key: "layoutX", prop: "layoutX", ctor: Float32Array, count: "node" }),
  Object.freeze({ key: "layoutY", prop: "layoutY", ctor: Float32Array, count: "node" }),
]);

const EDGE_ARRAY_SPECS = Object.freeze([
  Object.freeze({ key: "edgesSource", prop: "edgeSources", ctor: Uint32Array, count: "edge" }),
  Object.freeze({ key: "edgesTarget", prop: "edgeTargets", ctor: Uint32Array, count: "edge" }),
  Object.freeze({ key: "edgesFlags", prop: "edgeFlags", ctor: Uint32Array, count: "edge" }),
]);

function nowMs() {
  const perf = globalThis.performance || nodePerformance;
  if (perf && typeof perf.now === "function") return perf.now();
  return Date.now();
}

function timed(fn) {
  const startedAt = nowMs();
  const value = fn();
  return {
    value,
    ms: Number((nowMs() - startedAt).toFixed(3)),
  };
}

function safeMessage(error) {
  return String(error && (error.message || error.stack) ? error.message || error.stack : error);
}

function createFailureState({
  severity = FAILURE_SEVERITY.BLOCKING,
  code = "GRAPH_FAILURE",
  message = "Graph operation failed",
  activeDir = null,
  failures = [],
  cause = null,
} = {}) {
  return Object.freeze({
    contract: "FailureState/v9.0",
    severity,
    code,
    message,
    activeDir,
    failures: Object.freeze(
      failures.map((failure) =>
        Object.freeze({
          activeDir: failure.activeDir || null,
          code: failure.code || "GRAPH_FAILURE",
          message: failure.message || failure.error || String(failure),
        }),
      ),
    ),
    cause: cause ? safeMessage(cause) : null,
  });
}

function normalizeCamera(camera = {}) {
  return Object.freeze({
    ...DEFAULT_CAMERA,
    ...camera,
    x: Number(camera.x ?? DEFAULT_CAMERA.x),
    y: Number(camera.y ?? DEFAULT_CAMERA.y),
    width: Math.max(1, Number(camera.width ?? DEFAULT_CAMERA.width)),
    height: Math.max(1, Number(camera.height ?? DEFAULT_CAMERA.height)),
    zoom: Math.max(0.001, Number(camera.zoom ?? DEFAULT_CAMERA.zoom)),
  });
}

function normalizeBudgets(budgets = {}) {
  return Object.freeze({
    nodeBudget: Math.max(0, Math.floor(Number(budgets.nodeBudget ?? DEFAULT_BUDGETS.nodeBudget))),
    edgeBudget: Math.max(0, Math.floor(Number(budgets.edgeBudget ?? DEFAULT_BUDGETS.edgeBudget))),
    labelBudget: 0,
    frameBudgetMs: Math.max(1, Number(budgets.frameBudgetMs ?? DEFAULT_BUDGETS.frameBudgetMs)),
  });
}

function assertInside(parent, child) {
  const relative = path.relative(parent, child);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`Refusing to read outside graph store: ${child}`);
  }
}

function resolveStoreFile(activeDir, fileName) {
  if (!fileName || typeof fileName !== "string") {
    throw new Error("Missing graph store file name");
  }
  const full = path.resolve(activeDir, fileName);
  assertInside(activeDir, full);
  return full;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function readTypedArray(filePath, Ctor, expectedLength) {
  const buffer = fs.readFileSync(filePath);
  const expectedBytes = expectedLength * Ctor.BYTES_PER_ELEMENT;
  if (buffer.byteLength !== expectedBytes) {
    throw new Error(`Array length mismatch for ${path.basename(filePath)}: expected ${expectedBytes}, got ${buffer.byteLength}`);
  }
  const sliced = buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);
  return new Ctor(sliced);
}

function getManifestStats(manifest) {
  const nodeCount = Number(manifest?.stats?.nodes ?? manifest?.arrays?.nodeCount);
  const edgeCount = Number(manifest?.stats?.edges ?? manifest?.arrays?.edgeCount ?? 0);
  return {
    nodeCount,
    edgeCount,
  };
}

function validateManifestShallow(manifest, activeDir, { includeEdges = true } = {}) {
  const errors = [];
  const warnings = [];
  if (!manifest || typeof manifest !== "object") {
    errors.push("manifest-not-object");
    return Object.freeze({ ok: false, errors: Object.freeze(errors), warnings: Object.freeze(warnings), nodeCount: 0, edgeCount: 0 });
  }

  if (!Number.isInteger(Number(manifest.schemaVersion))) errors.push("schema-version-missing");
  if (manifest.status && manifest.status !== "ready") warnings.push(`manifest-status:${manifest.status}`);
  if (!manifest.files || typeof manifest.files !== "object") errors.push("manifest-files-missing");

  const { nodeCount, edgeCount } = getManifestStats(manifest);
  if (!Number.isInteger(nodeCount) || nodeCount < 0) errors.push("node-count-invalid");
  if (!Number.isInteger(edgeCount) || edgeCount < 0) errors.push("edge-count-invalid");

  if (manifest.files) {
    const specs = includeEdges ? [...NODE_ARRAY_SPECS, ...EDGE_ARRAY_SPECS] : NODE_ARRAY_SPECS;
    for (const spec of specs) {
      const fileName = manifest.files[spec.key];
      if (!fileName) {
        errors.push(`file-missing:${spec.key}`);
        continue;
      }
      try {
        const full = resolveStoreFile(activeDir, fileName);
        if (!fs.existsSync(full)) {
          errors.push(`file-not-found:${spec.key}`);
          continue;
        }
        const expectedLength = spec.count === "node" ? nodeCount : edgeCount;
        const expectedBytes = expectedLength * spec.ctor.BYTES_PER_ELEMENT;
        const actualBytes = fs.statSync(full).size;
        if (actualBytes !== expectedBytes) {
          errors.push(`array-length:${spec.key}:expected-${expectedBytes}:actual-${actualBytes}`);
        }
      } catch (error) {
        errors.push(`file-invalid:${spec.key}:${safeMessage(error)}`);
      }
    }
  }

  return Object.freeze({
    ok: errors.length === 0,
    errors: Object.freeze(errors),
    warnings: Object.freeze(warnings),
    nodeCount: Number.isFinite(nodeCount) ? nodeCount : 0,
    edgeCount: Number.isFinite(edgeCount) ? edgeCount : 0,
  });
}

function readCurrentManifest(storeRoot, activeDirName) {
  const activeDir = path.join(storeRoot, activeDirName);
  const manifestPaths =
    activeDirName === "graph.current"
      ? [path.join(storeRoot, "graph.manifest.json"), path.join(activeDir, "graph.manifest.json")]
      : [path.join(activeDir, "graph.manifest.json")];
  let lastError = null;
  for (const manifestPath of manifestPaths) {
    try {
      if (!fs.existsSync(manifestPath)) continue;
      return readJson(manifestPath);
    } catch (error) {
      lastError = error;
    }
  }
  if (lastError) throw lastError;
  throw new Error(`Missing manifest for ${activeDirName}`);
}

function loadSnapshotArrays(manifest, activeDir, validation, { includeEdges = true } = {}) {
  const arrays = {};
  for (const spec of NODE_ARRAY_SPECS) {
    arrays[spec.prop] = readTypedArray(resolveStoreFile(activeDir, manifest.files[spec.key]), spec.ctor, validation.nodeCount);
  }
  if (includeEdges) {
    for (const spec of EDGE_ARRAY_SPECS) {
      arrays[spec.prop] = readTypedArray(resolveStoreFile(activeDir, manifest.files[spec.key]), spec.ctor, validation.edgeCount);
    }
  } else {
    arrays.edgeSources = new Uint32Array(0);
    arrays.edgeTargets = new Uint32Array(0);
    arrays.edgeFlags = new Uint32Array(0);
  }
  return Object.freeze(arrays);
}

function createGraphSnapshot({ storeRoot, activeDirName, activeDir, manifest, validation, arrays, recoveredFromPrevious, timingsMs }) {
  return Object.freeze({
    contract: "GraphSnapshot/v9.0",
    storeRoot,
    activeDir: activeDirName,
    activePath: activeDir,
    manifest,
    validation,
    nodeCount: validation.nodeCount,
    edgeCount: validation.edgeCount,
    arrays,
    recoveredFromPrevious,
    timingsMs: Object.freeze({ ...timingsMs }),
  });
}

class GraphStoreClient {
  constructor({ storeRoot, includeEdges = true } = {}) {
    if (!storeRoot) throw new Error("GraphStoreClient requires storeRoot");
    this.storeRoot = path.resolve(storeRoot);
    this.includeEdges = includeEdges;
  }

  loadSnapshot(options = {}) {
    const includeEdges = options.includeEdges ?? this.includeEdges;
    const failures = [];
    const attempts = ["graph.current", "graph.previous"];

    for (const activeDirName of attempts) {
      const activeDir = path.join(this.storeRoot, activeDirName);
      const timingsMs = {};
      try {
        const manifestTimed = timed(() => readCurrentManifest(this.storeRoot, activeDirName));
        timingsMs.manifestRead = manifestTimed.ms;
        const manifest = manifestTimed.value;

        const validationTimed = timed(() => validateManifestShallow(manifest, activeDir, { includeEdges }));
        timingsMs.shallowValidation = validationTimed.ms;
        const validation = validationTimed.value;
        if (!validation.ok) {
          throw new Error(`Shallow validation failed: ${validation.errors.join(", ")}`);
        }

        const arraysTimed = timed(() => loadSnapshotArrays(manifest, activeDir, validation, { includeEdges }));
        timingsMs.arrayLoad = arraysTimed.ms;
        const snapshot = createGraphSnapshot({
          storeRoot: this.storeRoot,
          activeDirName,
          activeDir,
          manifest,
          validation,
          arrays: arraysTimed.value,
          recoveredFromPrevious: activeDirName === "graph.previous",
          timingsMs,
        });

        return Object.freeze({
          ok: true,
          snapshot,
          failureState: null,
          recoveredFromPrevious: snapshot.recoveredFromPrevious,
          failures: Object.freeze(failures),
          timingsMs: Object.freeze(timingsMs),
        });
      } catch (error) {
        failures.push(
          Object.freeze({
            activeDir: activeDirName,
            code: "STORE_LOAD_FAILED",
            message: safeMessage(error),
          }),
        );
      }
    }

    return Object.freeze({
      ok: false,
      snapshot: null,
      recoveredFromPrevious: false,
      failureState: createFailureState({
        severity: FAILURE_SEVERITY.BLOCKING,
        code: "STORE_UNAVAILABLE",
        message: "Graph Store is missing or corrupt",
        failures,
      }),
      failures: Object.freeze(failures),
      timingsMs: Object.freeze({}),
    });
  }
}

function isInCamera(x, y, camera) {
  const halfWidth = camera.width / camera.zoom / 2;
  const halfHeight = camera.height / camera.zoom / 2;
  const minX = camera.x - halfWidth;
  const maxX = camera.x + halfWidth;
  const minY = camera.y - halfHeight;
  const maxY = camera.y + halfHeight;
  return x >= minX && x <= maxX && y >= minY && y <= maxY;
}

function incrementReason(reasons, key, by = 1) {
  reasons[key] = (reasons[key] || 0) + by;
}

function freezeReasons(reasons) {
  return Object.freeze({ ...reasons });
}

function makeLineage(snapshot, frameId) {
  return Object.freeze({
    storeBuildId: snapshot.manifest.builtAt || snapshot.manifest.storeVersion || "unknown-store",
    layoutBuildId: snapshot.manifest.storeVersion || `schema-${snapshot.manifest.schemaVersion || "unknown"}`,
    renderPlanId: `critical-frame-${frameId}`,
    frameId,
  });
}

function buildCriticalRenderPlan({
  snapshot,
  camera = DEFAULT_CAMERA,
  budgets = DEFAULT_BUDGETS,
  frameId = 1,
  profileId = "critical-real-frame",
  mode = "normal",
  reason = "critical-path",
  lod = 2,
} = {}) {
  const startedAt = nowMs();
  if (!snapshot || snapshot.contract !== "GraphSnapshot/v9.0") {
    const failureState = createFailureState({
      severity: FAILURE_SEVERITY.BLOCKING,
      code: "SNAPSHOT_MISSING",
      message: "RenderPlan requires a GraphSnapshot",
    });
    return Object.freeze({
      contract: "RenderPlan/v9.0",
      id: frameId,
      frameId,
      profileId,
      lod: 0,
      mode: "snapshot-missing",
      reason: "snapshot-missing",
      camera: normalizeCamera(camera),
      nodes: new Uint32Array(0),
      edges: new Uint32Array(0),
      labels: new Uint32Array(0),
      clusters: new Uint32Array(0),
      nodeIds: new Uint32Array(0),
      nodeX: new Float32Array(0),
      nodeY: new Float32Array(0),
      nodeTypes: new Uint16Array(0),
      nodeFlags: new Uint32Array(0),
      edgeIds: new Uint32Array(0),
      edgeSourceIds: new Uint32Array(0),
      edgeTargetIds: new Uint32Array(0),
      edgeX1: new Float32Array(0),
      edgeY1: new Float32Array(0),
      edgeX2: new Float32Array(0),
      edgeY2: new Float32Array(0),
      budgets: normalizeBudgets({ nodeBudget: 0, edgeBudget: 0, frameBudgetMs: 12 }),
      skipped: Object.freeze({ nodes: 0, edges: 0, labels: 0 }),
      skipReasons: freezeReasons({ SNAPSHOT_MISSING: 1 }),
      failureState,
      recoveredFromPrevious: false,
      lineage: Object.freeze({ renderPlanId: `critical-frame-${frameId}`, frameId }),
      stats: Object.freeze({ nodes: 0, edges: 0 }),
      timingsMs: Object.freeze({ visibleSet: 0, edgeBatch: 0, renderPlan: Number((nowMs() - startedAt).toFixed(3)) }),
    });
  }

  const normalizedCamera = normalizeCamera(camera);
  const normalizedBudgets = normalizeBudgets(budgets);
  const arrays = snapshot.arrays;
  const nodeCount = snapshot.nodeCount;
  const edgeCount = snapshot.edgeCount;
  const visibleMask = new Uint8Array(nodeCount);
  const maxNodes = Math.min(normalizedBudgets.nodeBudget, nodeCount);
  const nodeIds = new Uint32Array(maxNodes);
  const nodeX = new Float32Array(maxNodes);
  const nodeY = new Float32Array(maxNodes);
  const nodeTypes = new Uint16Array(maxNodes);
  const nodeFlags = new Uint32Array(maxNodes);
  const skipReasons = {};
  let selectedNodeCount = 0;
  let visibleCandidates = 0;
  const visibleStartedAt = nowMs();

  for (let index = 0; index < nodeCount; index += 1) {
    const x = arrays.layoutX[index];
    const y = arrays.layoutY[index];
    if (!isInCamera(x, y, normalizedCamera)) {
      incrementReason(skipReasons, "OUTSIDE_VIEWPORT");
      continue;
    }
    visibleCandidates += 1;
    if (selectedNodeCount >= maxNodes) {
      incrementReason(skipReasons, "NODE_BUDGET");
      continue;
    }
    visibleMask[index] = 1;
    nodeIds[selectedNodeCount] = arrays.nodeIds[index] ?? index;
    nodeX[selectedNodeCount] = x;
    nodeY[selectedNodeCount] = y;
    nodeTypes[selectedNodeCount] = arrays.nodeTypes[index] ?? 0;
    nodeFlags[selectedNodeCount] = arrays.nodeFlags[index] ?? 0;
    selectedNodeCount += 1;
  }

  if (selectedNodeCount === 0 && nodeCount > 0 && maxNodes > 0) {
    const fallbackCount = Math.min(maxNodes, nodeCount);
    incrementReason(skipReasons, "VIEWPORT_EMPTY_FALLBACK", fallbackCount);
    for (let index = 0; index < fallbackCount; index += 1) {
      visibleMask[index] = 1;
      nodeIds[selectedNodeCount] = arrays.nodeIds[index] ?? index;
      nodeX[selectedNodeCount] = arrays.layoutX[index];
      nodeY[selectedNodeCount] = arrays.layoutY[index];
      nodeTypes[selectedNodeCount] = arrays.nodeTypes[index] ?? 0;
      nodeFlags[selectedNodeCount] = arrays.nodeFlags[index] ?? 0;
      selectedNodeCount += 1;
    }
  }

  const visibleSetMs = Number((nowMs() - visibleStartedAt).toFixed(3));
  const maxEdges = Math.min(normalizedBudgets.edgeBudget, edgeCount);
  const edgeIds = new Uint32Array(maxEdges);
  const edgeSourceIds = new Uint32Array(maxEdges);
  const edgeTargetIds = new Uint32Array(maxEdges);
  const edgeX1 = new Float32Array(maxEdges);
  const edgeY1 = new Float32Array(maxEdges);
  const edgeX2 = new Float32Array(maxEdges);
  const edgeY2 = new Float32Array(maxEdges);
  let selectedEdgeCount = 0;
  const edgeStartedAt = nowMs();

  if (normalizedBudgets.edgeBudget <= 0) {
    incrementReason(skipReasons, "EDGE_BUDGET_ZERO", edgeCount);
  } else {
    for (let edgeId = 0; edgeId < edgeCount; edgeId += 1) {
      const source = arrays.edgeSources[edgeId];
      const target = arrays.edgeTargets[edgeId];
      if (source >= nodeCount || target >= nodeCount) {
        incrementReason(skipReasons, "INVALID_EDGE_ENDPOINT");
        continue;
      }
      if (!visibleMask[source] || !visibleMask[target]) {
        incrementReason(skipReasons, "EDGE_OUTSIDE_VISIBLE_SET");
        continue;
      }
      if (selectedEdgeCount >= maxEdges) {
        incrementReason(skipReasons, "EDGE_BUDGET");
        continue;
      }
      edgeIds[selectedEdgeCount] = edgeId;
      edgeSourceIds[selectedEdgeCount] = arrays.nodeIds[source] ?? source;
      edgeTargetIds[selectedEdgeCount] = arrays.nodeIds[target] ?? target;
      edgeX1[selectedEdgeCount] = arrays.layoutX[source];
      edgeY1[selectedEdgeCount] = arrays.layoutY[source];
      edgeX2[selectedEdgeCount] = arrays.layoutX[target];
      edgeY2[selectedEdgeCount] = arrays.layoutY[target];
      selectedEdgeCount += 1;
    }
  }

  incrementReason(skipReasons, "LABELS_DISABLED_FIRST_FRAME", selectedNodeCount);
  const edgeBatchMs = Number((nowMs() - edgeStartedAt).toFixed(3));
  const renderPlanMs = Number((nowMs() - startedAt).toFixed(3));
  const labels = new Uint32Array(0);
  const clusters = new Uint32Array(0);
  const nodes = nodeIds.slice(0, selectedNodeCount);
  const edges = edgeIds.slice(0, selectedEdgeCount);

  return Object.freeze({
    contract: "RenderPlan/v9.0",
    id: frameId,
    frameId,
    profileId,
    lod,
    mode,
    reason,
    camera: normalizedCamera,
    nodes,
    edges,
    labels,
    clusters,
    nodeIds: nodes,
    nodeX: nodeX.slice(0, selectedNodeCount),
    nodeY: nodeY.slice(0, selectedNodeCount),
    nodeTypes: nodeTypes.slice(0, selectedNodeCount),
    nodeFlags: nodeFlags.slice(0, selectedNodeCount),
    edgeIds: edges,
    edgeSourceIds: edgeSourceIds.slice(0, selectedEdgeCount),
    edgeTargetIds: edgeTargetIds.slice(0, selectedEdgeCount),
    edgeX1: edgeX1.slice(0, selectedEdgeCount),
    edgeY1: edgeY1.slice(0, selectedEdgeCount),
    edgeX2: edgeX2.slice(0, selectedEdgeCount),
    edgeY2: edgeY2.slice(0, selectedEdgeCount),
    budgets: normalizedBudgets,
    skipped: Object.freeze({
      nodes: Math.max(0, nodeCount - selectedNodeCount),
      edges: Math.max(0, edgeCount - selectedEdgeCount),
      labels: selectedNodeCount,
    }),
    skipReasons: freezeReasons(skipReasons),
    failureState: null,
    recoveredFromPrevious: snapshot.recoveredFromPrevious,
    lineage: makeLineage(snapshot, frameId),
    stats: Object.freeze({ ...snapshot.manifest.stats, nodes: nodeCount, edges: edgeCount, visibleCandidates }),
    timingsMs: Object.freeze({
      visibleSet: visibleSetMs,
      edgeBatch: edgeBatchMs,
      renderPlan: renderPlanMs,
    }),
  });
}

function createFrameStats({ plan, backendId = "unknown", drawTimingsMs = {}, drawn = {}, failureState = null } = {}) {
  const emptyPlan = !plan;
  const counts = Object.freeze({
    nodes: emptyPlan ? 0 : plan.nodes.length,
    edges: emptyPlan ? 0 : plan.edges.length,
    labels: emptyPlan ? 0 : plan.labels.length,
  });
  return Object.freeze({
    contract: "FrameStats/v9.0",
    frameId: emptyPlan ? 0 : plan.frameId,
    renderPlanId: emptyPlan ? null : plan.lineage?.renderPlanId || null,
    backendId,
    mode: emptyPlan ? "no-plan" : plan.mode,
    counts,
    drawn: Object.freeze({
      nodes: Number(drawn.nodes ?? counts.nodes),
      edges: Number(drawn.edges ?? counts.edges),
      labels: Number(drawn.labels ?? counts.labels),
    }),
    budgets: emptyPlan ? normalizeBudgets({ nodeBudget: 0, edgeBudget: 0 }) : plan.budgets,
    skipped: emptyPlan ? Object.freeze({ nodes: 0, edges: 0, labels: 0 }) : plan.skipped,
    skipReasons: emptyPlan ? freezeReasons({ NO_PLAN: 1 }) : plan.skipReasons,
    timingsMs: Object.freeze({
      visibleSet: Number(plan?.timingsMs?.visibleSet || 0),
      edgeBatch: Number(plan?.timingsMs?.edgeBatch || 0),
      renderPlan: Number(plan?.timingsMs?.renderPlan || 0),
      draw: Number(drawTimingsMs.draw || 0),
      total: Number(drawTimingsMs.total ?? drawTimingsMs.draw ?? 0),
    }),
    failureState,
  });
}

class NullBackend {
  constructor({ id = "null" } = {}) {
    this.id = id;
  }

  draw(plan) {
    return createFrameStats({ plan, backendId: this.id, drawTimingsMs: { draw: 0, total: 0 } });
  }

  dispose() {}
}

class CanvasBackend {
  constructor({ canvas = null, ctx = null, id = "canvas" } = {}) {
    this.id = id;
    this.canvas = canvas;
    this.ctx = ctx || canvas?.getContext?.("2d") || null;
  }

  draw(plan) {
    const startedAt = nowMs();
    if (!this.ctx) {
      return createFrameStats({
        plan,
        backendId: this.id,
        failureState: createFailureState({
          severity: FAILURE_SEVERITY.DEGRADED,
          code: "CANVAS_CONTEXT_MISSING",
          message: "Canvas 2D context is unavailable",
        }),
      });
    }

    try {
      const ctx = this.ctx;
      if (plan.edges.length && typeof ctx.beginPath === "function" && typeof ctx.moveTo === "function" && typeof ctx.lineTo === "function") {
        ctx.strokeStyle = "rgba(88, 132, 160, 0.24)";
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let i = 0; i < plan.edges.length; i += 1) {
          const x1 = (plan.edgeX1[i] - plan.camera.x) * plan.camera.zoom + plan.camera.width / 2;
          const y1 = (plan.edgeY1[i] - plan.camera.y) * plan.camera.zoom + plan.camera.height / 2;
          const x2 = (plan.edgeX2[i] - plan.camera.x) * plan.camera.zoom + plan.camera.width / 2;
          const y2 = (plan.edgeY2[i] - plan.camera.y) * plan.camera.zoom + plan.camera.height / 2;
          ctx.moveTo(x1, y1);
          ctx.lineTo(x2, y2);
        }
        ctx.stroke?.();
      }

      const radius = plan.camera.zoom < 0.45 ? 1.1 : 1.8;
      ctx.fillStyle = plan.mode === "memory-pressure" ? "rgba(255, 186, 96, 0.78)" : "rgba(96, 180, 255, 0.78)";
      ctx.beginPath?.();
      for (let i = 0; i < plan.nodes.length; i += 1) {
        const x = (plan.nodeX[i] - plan.camera.x) * plan.camera.zoom + plan.camera.width / 2;
        const y = (plan.nodeY[i] - plan.camera.y) * plan.camera.zoom + plan.camera.height / 2;
        ctx.rect?.(x - radius, y - radius, radius * 2, radius * 2);
      }
      ctx.fill?.();

      const drawMs = Number((nowMs() - startedAt).toFixed(3));
      return createFrameStats({
        plan,
        backendId: this.id,
        drawTimingsMs: { draw: drawMs, total: drawMs },
      });
    } catch (error) {
      const drawMs = Number((nowMs() - startedAt).toFixed(3));
      return createFrameStats({
        plan,
        backendId: this.id,
        drawTimingsMs: { draw: drawMs, total: drawMs },
        failureState: createFailureState({
          severity: FAILURE_SEVERITY.DEGRADED,
          code: "CANVAS_DRAW_FAILED",
          message: "Canvas draw failed",
          cause: error,
        }),
      });
    }
  }

  dispose() {
    this.ctx = null;
    this.canvas = null;
  }
}

module.exports = {
  CanvasBackend,
  DEFAULT_BUDGETS,
  DEFAULT_CAMERA,
  FAILURE_SEVERITY,
  GraphStoreClient,
  NullBackend,
  buildCriticalRenderPlan,
  createFailureState,
  createFrameStats,
  normalizeBudgets,
  normalizeCamera,
  validateManifestShallow,
};
