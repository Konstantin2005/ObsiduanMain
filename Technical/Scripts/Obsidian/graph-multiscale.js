const { buildQueryPlan } = require("./graph-query-engine.js");

const SCALE_LEVELS = Object.freeze({
  DOMAIN_OVERVIEW: 0,
  CLUSTERS: 1,
  BACKBONE: 2,
  IMPORTANT: 3,
  EGO: 4,
  DETAILS: 5,
});

function pushUnique(out, seen, nodeId, maxNodes = Infinity) {
  const id = Number(nodeId);
  if (!Number.isInteger(id) || id < 0 || seen.has(id) || out.length >= maxNodes) return;
  seen.add(id);
  out.push(id);
}

function computeBounds(snapshot) {
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

function buildDomainOverview(snapshot) {
  const byType = new Map();
  for (let index = 0; index < snapshot.nodeCount; index += 1) {
    const type = snapshot.arrays.nodeTypes[index] || 0;
    if (!byType.has(type)) byType.set(type, snapshot.arrays.nodeIds[index] ?? index);
  }
  return Uint32Array.from(byType.values());
}

function buildSpatialClusters(snapshot, { maxClusters = 512 } = {}) {
  const bounds = computeBounds(snapshot);
  const grid = Math.max(1, Math.ceil(Math.sqrt(maxClusters)));
  const width = Math.max(1, bounds.maxX - bounds.minX);
  const height = Math.max(1, bounds.maxY - bounds.minY);
  const buckets = new Map();
  for (let index = 0; index < snapshot.nodeCount; index += 1) {
    const gx = Math.max(0, Math.min(grid - 1, Math.floor(((snapshot.arrays.layoutX[index] - bounds.minX) / width) * grid)));
    const gy = Math.max(0, Math.min(grid - 1, Math.floor(((snapshot.arrays.layoutY[index] - bounds.minY) / height) * grid)));
    const key = `${gx}:${gy}`;
    if (!buckets.has(key)) buckets.set(key, snapshot.arrays.nodeIds[index] ?? index);
  }
  return Uint32Array.from(buckets.values());
}

function buildBackbone(snapshot) {
  const out = [];
  const seen = new Set();
  const { edgeSources, edgeTargets, edgeFlags, nodeIds } = snapshot.arrays;
  for (let edgeId = 0; edgeId < snapshot.edgeCount; edgeId += 1) {
    if ((edgeFlags[edgeId] & 1) === 0) continue;
    pushUnique(out, seen, nodeIds[edgeSources[edgeId]] ?? edgeSources[edgeId]);
    pushUnique(out, seen, nodeIds[edgeTargets[edgeId]] ?? edgeTargets[edgeId]);
  }
  return Uint32Array.from(out);
}

function buildImportant(snapshot, { maxNodes = 2000 } = {}) {
  const degree = new Uint32Array(snapshot.nodeCount);
  const { edgeSources, edgeTargets } = snapshot.arrays;
  for (let edgeId = 0; edgeId < snapshot.edgeCount; edgeId += 1) {
    const source = edgeSources[edgeId];
    const target = edgeTargets[edgeId];
    if (source < snapshot.nodeCount) degree[source] += 1;
    if (target < snapshot.nodeCount) degree[target] += 1;
  }
  const ranked = [];
  for (let index = 0; index < snapshot.nodeCount; index += 1) {
    if (degree[index] > 0) ranked.push(index);
  }
  ranked.sort((a, b) => degree[b] - degree[a] || a - b);
  return Uint32Array.from(ranked.slice(0, maxNodes).map((index) => snapshot.arrays.nodeIds[index] ?? index));
}

function buildEgo(snapshot, { centerNodeIds = [], maxNodes = 2000 } = {}) {
  const out = [];
  const seen = new Set();
  const centers = centerNodeIds.length ? centerNodeIds : [0];
  for (const center of centers) pushUnique(out, seen, center, maxNodes);
  const centerSet = new Set(centers.map((value) => Number(value)));
  for (let edgeId = 0; edgeId < snapshot.edgeCount && out.length < maxNodes; edgeId += 1) {
    const source = snapshot.arrays.edgeSources[edgeId];
    const target = snapshot.arrays.edgeTargets[edgeId];
    const sourceId = snapshot.arrays.nodeIds[source] ?? source;
    const targetId = snapshot.arrays.nodeIds[target] ?? target;
    if (centerSet.has(sourceId)) pushUnique(out, seen, targetId, maxNodes);
    if (centerSet.has(targetId)) pushUnique(out, seen, sourceId, maxNodes);
  }
  return Uint32Array.from(out);
}

function buildDetails(snapshot, { maxNodes = snapshot.nodeCount } = {}) {
  const count = Math.min(snapshot.nodeCount, Math.max(0, Number(maxNodes)));
  return snapshot.arrays.nodeIds.slice(0, count);
}

function makeLevel(level, name, nodes) {
  return Object.freeze({
    level,
    name,
    nodes,
    count: nodes.length,
  });
}

function buildMultiScaleModel({ snapshot, selectedNodeIds = [], maxClusters = 512, maxImportant = 2000, maxEgo = 2000 } = {}) {
  if (!snapshot || snapshot.contract !== "GraphSnapshot/v9.0") {
    return Object.freeze({
      contract: "MultiScaleModel/v9.0",
      ok: false,
      levels: Object.freeze({}),
      reason: "snapshot-missing",
    });
  }

  const levels = {
    0: makeLevel(0, "domain-overview", buildDomainOverview(snapshot)),
    1: makeLevel(1, "clusters", buildSpatialClusters(snapshot, { maxClusters })),
    2: makeLevel(2, "backbone", buildBackbone(snapshot)),
    3: makeLevel(3, "important", buildImportant(snapshot, { maxNodes: maxImportant })),
    4: makeLevel(4, "ego", buildEgo(snapshot, { centerNodeIds: selectedNodeIds, maxNodes: maxEgo })),
    5: makeLevel(5, "details", buildDetails(snapshot)),
  };

  return Object.freeze({
    contract: "MultiScaleModel/v9.0",
    ok: true,
    levels: Object.freeze(levels),
  });
}

function selectScaleNodes(model, { level = SCALE_LEVELS.DETAILS, budget = Infinity } = {}) {
  const scale = model?.levels?.[level] || model?.levels?.[SCALE_LEVELS.DETAILS];
  if (!scale) return new Uint32Array(0);
  const limit = Math.min(scale.nodes.length, Math.max(0, Number.isFinite(budget) ? budget : scale.nodes.length));
  return scale.nodes.slice(0, limit);
}

function buildScaleQueryPlan({ snapshot, level = SCALE_LEVELS.DETAILS, budget = Infinity, selectedNodeIds = [], edgePolicy = "visible", id = `scale-${level}` } = {}) {
  if (level === SCALE_LEVELS.DETAILS) {
    return buildQueryPlan({ snapshot, edgePolicy, id });
  }
  const model = buildMultiScaleModel({ snapshot, selectedNodeIds });
  const nodes = selectScaleNodes(model, { level, budget });
  return buildQueryPlan({
    snapshot,
    filters: [{ type: "nodeIdSet", ids: Array.from(nodes) }],
    priorityNodeIds: Array.from(nodes),
    edgePolicy: level === SCALE_LEVELS.BACKBONE ? "backbone" : edgePolicy,
    id,
  });
}

module.exports = {
  SCALE_LEVELS,
  buildMultiScaleModel,
  buildScaleQueryPlan,
  selectScaleNodes,
};
