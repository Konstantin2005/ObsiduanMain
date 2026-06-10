const {
  GraphStoreClient,
  buildCriticalRenderPlan,
  createFailureState,
} = require("./graph-critical-frame.js");
const { buildQueryPlan } = require("./graph-query-engine.js");

const DEFAULT_CAMERA = {
  x: 0,
  y: 0,
  width: 1600,
  height: 1000,
  zoom: 1,
};

const DEFAULT_PROFILE = {
  name: "fast-backbone",
  maxVisibleNodes: 3000,
  maxVisibleEdges: 5000,
  labelPolicy: "none",
  edgePolicy: "backbone",
  lodPolicy: "native-safe",
};

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function normalizeProfile(profile = {}) {
  return {
    ...DEFAULT_PROFILE,
    ...profile,
    maxVisibleNodes: Number(profile.maxVisibleNodes || DEFAULT_PROFILE.maxVisibleNodes),
    maxVisibleEdges: Number(profile.maxVisibleEdges || DEFAULT_PROFILE.maxVisibleEdges),
  };
}

function pickMode({ profile, frameHistory = {}, memoryPressure = false }) {
  const p95 = Number(frameHistory.p95FrameMs || 0);
  if (memoryPressure) return { mode: "memory-pressure", degraded: true, reason: "memory-pressure" };
  if (p95 > 32) return { mode: "emergency", degraded: true, reason: "p95-frame-over-32ms" };
  if (p95 > 24) return { mode: "degraded", degraded: true, reason: "p95-frame-over-24ms" };
  if (profile.maxVisibleNodes > 10000 || profile.maxVisibleEdges > 20000) {
    return { mode: "heavy", degraded: false, reason: "profile-heavy" };
  }
  return { mode: "normal", degraded: false, reason: "within-budget" };
}

function pickLod({ camera, mode, profile }) {
  const zoom = Number(camera.zoom || 1);
  if (mode === "emergency" || mode === "memory-pressure") return 0;
  if (mode === "degraded") return zoom < 1.5 ? 1 : 2;
  if (profile.lodPolicy === "aggressive") {
    if (zoom < 0.35) return 0;
    if (zoom < 1) return 1;
    if (zoom < 2) return 2;
    return 3;
  }
  if (zoom < 0.25) return 0;
  if (zoom < 0.75) return 1;
  if (zoom < 1.5) return 2;
  if (zoom < 3) return 3;
  return 4;
}

function makeBudgets(profile, mode, lod) {
  let nodeBudget = profile.maxVisibleNodes;
  let edgeBudget = profile.maxVisibleEdges;
  let labelBudget = profile.labelPolicy === "none" ? 0 : 250;

  if (lod === 0) {
    nodeBudget = Math.min(nodeBudget, 500);
    edgeBudget = Math.min(edgeBudget, 1500);
    labelBudget = 0;
  } else if (lod === 1) {
    nodeBudget = Math.min(nodeBudget, 3000);
    edgeBudget = Math.min(edgeBudget, 5000);
    labelBudget = 0;
  }

  if (mode === "degraded") {
    nodeBudget = Math.floor(nodeBudget * 0.6);
    edgeBudget = Math.floor(edgeBudget * 0.35);
    labelBudget = 0;
  } else if (mode === "emergency" || mode === "memory-pressure") {
    nodeBudget = Math.min(nodeBudget, 500);
    edgeBudget = 0;
    labelBudget = 0;
  }

  return {
    nodeBudget: Math.max(0, nodeBudget),
    edgeBudget: Math.max(0, edgeBudget),
    labelBudget: Math.max(0, labelBudget),
    frameBudgetMs: mode === "normal" ? 16 : 12,
  };
}

function loadIndexedGraph(storeRoot) {
  const loaded = new GraphStoreClient({ storeRoot, includeEdges: true }).loadSnapshot();
  if (!loaded.ok) {
    return {
      ok: false,
      failures: loaded.failures,
      failureState: loaded.failureState,
    };
  }
  return {
    ok: true,
    snapshot: loaded.snapshot,
    manifest: loaded.snapshot.manifest,
    recoveredFromPrevious: loaded.recoveredFromPrevious,
    activeDir: loaded.snapshot.activeDir,
    arrays: loaded.snapshot.arrays,
  };
}

function isInCamera(x, y, camera) {
  const zoom = Number(camera.zoom || 1);
  const halfWidth = Number(camera.width || DEFAULT_CAMERA.width) / Math.max(0.001, zoom) / 2;
  const halfHeight = Number(camera.height || DEFAULT_CAMERA.height) / Math.max(0.001, zoom) / 2;
  const minX = Number(camera.x || 0) - halfWidth;
  const maxX = Number(camera.x || 0) + halfWidth;
  const minY = Number(camera.y || 0) - halfHeight;
  const maxY = Number(camera.y || 0) + halfHeight;
  return x >= minX && x <= maxX && y >= minY && y <= maxY;
}

function selectNodes(indexed, camera, budgets, lod) {
  const { layoutX, layoutY, nodeClusters } = indexed.arrays;
  const selected = [];
  const selectedSet = new Set();
  const clusterRepresentatives = new Map();

  for (let id = 0; id < layoutX.length; id += 1) {
    if (!clusterRepresentatives.has(nodeClusters[id])) {
      clusterRepresentatives.set(nodeClusters[id], id);
    }
    const eligible = lod <= 1 ? clusterRepresentatives.get(nodeClusters[id]) === id : true;
    if (!eligible) continue;
    if (!isInCamera(layoutX[id], layoutY[id], camera)) continue;
    selected.push(id);
    selectedSet.add(id);
    if (selected.length >= budgets.nodeBudget) break;
  }

  if (!selected.length && layoutX.length) {
    const fallbackCount = Math.min(budgets.nodeBudget, Math.max(1, lod <= 1 ? clusterRepresentatives.size : layoutX.length));
    for (const id of lod <= 1 ? clusterRepresentatives.values() : layoutX.keys()) {
      selected.push(id);
      selectedSet.add(id);
      if (selected.length >= fallbackCount) break;
    }
  }

  const clusters = new Set();
  for (const id of selected) clusters.add(nodeClusters[id]);
  return {
    nodes: Uint32Array.from(selected),
    nodeSet: selectedSet,
    clusters: Uint32Array.from(clusters),
    skippedNodes: Math.max(0, layoutX.length - selected.length),
  };
}

function selectEdges(indexed, nodeSet, budgets, mode) {
  if (budgets.edgeBudget <= 0) {
    return { edges: new Uint32Array(0), skippedEdges: indexed.arrays.edgeSources.length };
  }
  const { edgeSources, edgeTargets, edgeFlags } = indexed.arrays;
  const backbone = [];
  const local = [];

  for (let edgeId = 0; edgeId < edgeSources.length; edgeId += 1) {
    const sourceVisible = nodeSet.has(edgeSources[edgeId]);
    const targetVisible = nodeSet.has(edgeTargets[edgeId]);
    if (!sourceVisible || !targetVisible) continue;
    if (edgeFlags[edgeId] & 1) backbone.push(edgeId);
    else if (mode !== "emergency" && mode !== "memory-pressure") local.push(edgeId);
    if (backbone.length >= budgets.edgeBudget) break;
  }

  const selected = backbone.slice(0, budgets.edgeBudget);
  const remaining = budgets.edgeBudget - selected.length;
  if (remaining > 0) {
    selected.push(...local.slice(0, remaining));
  }
  return {
    edges: Uint32Array.from(selected),
    skippedEdges: Math.max(0, edgeSources.length - selected.length),
  };
}

function selectLabels(nodes, budgets, lod, profile) {
  if (budgets.labelBudget <= 0 || lod < 4 || profile.labelPolicy === "none") {
    return {
      labels: new Uint32Array(0),
      skippedLabels: nodes.length,
    };
  }
  const labels = nodes.slice(0, budgets.labelBudget);
  return {
    labels,
    skippedLabels: Math.max(0, nodes.length - labels.length),
  };
}

function buildRenderPlan({
  storeRoot,
  profile = DEFAULT_PROFILE,
  camera = DEFAULT_CAMERA,
  frameHistory = {},
  memoryPressure = false,
  frameId = 1,
} = {}) {
  const normalizedProfile = normalizeProfile(profile);
  const indexed = loadIndexedGraph(storeRoot);
  if (!indexed.ok) {
    const failureState =
      indexed.failureState ||
      createFailureState({
        code: "INDEX_MISSING",
        message: "Graph index is missing",
        failures: indexed.failures,
      });
    return Object.freeze({
      contract: "RenderPlan/v9.0",
      id: frameId,
      frameId,
      profileId: normalizedProfile.name,
      lod: 0,
      mode: "index-missing",
      reason: "store-unavailable",
      nodes: new Uint32Array(0),
      edges: new Uint32Array(0),
      clusters: new Uint32Array(0),
      labels: new Uint32Array(0),
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
      budgets: Object.freeze({ nodeBudget: 0, edgeBudget: 0, labelBudget: 0, frameBudgetMs: 12 }),
      skipped: Object.freeze({ nodes: 0, edges: 0, labels: 0 }),
      skipReasons: Object.freeze({ STORE_UNAVAILABLE: 1 }),
      failureState,
      recoveredFromPrevious: false,
      failures: indexed.failures,
      stats: Object.freeze({ nodes: 0, edges: 0 }),
      timingsMs: Object.freeze({ visibleSet: 0, edgeBatch: 0, renderPlan: 0 }),
    });
  }

  const modeInfo = pickMode({ profile: normalizedProfile, frameHistory, memoryPressure });
  const lod = pickLod({ camera, mode: modeInfo.mode, profile: normalizedProfile });
  const budgets = makeBudgets(normalizedProfile, modeInfo.mode, lod);
  const queryPlan = buildQueryPlan({
    snapshot: indexed.snapshot,
    filters: normalizedProfile.nodeTypes ? [{ type: "nodeType", values: normalizedProfile.nodeTypes }] : [],
    priorityNodeIds: normalizedProfile.priorityNodeIds || [],
    edgePolicy: normalizedProfile.edgePolicy === "backbone" ? "backbone" : "visible",
    id: `${normalizedProfile.name || "profile"}-query`,
  });
  return buildCriticalRenderPlan({
    snapshot: indexed.snapshot,
    camera: { ...DEFAULT_CAMERA, ...camera },
    budgets,
    frameId,
    profileId: normalizedProfile.name,
    mode: modeInfo.mode,
    reason: modeInfo.reason,
    lod,
    queryPlan,
  });
}

module.exports = {
  buildRenderPlan,
  loadIndexedGraph,
  makeBudgets,
  pickLod,
  pickMode,
};
