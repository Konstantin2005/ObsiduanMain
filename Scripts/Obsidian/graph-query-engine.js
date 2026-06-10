function makeBitset(size, fill = 0) {
  const bitset = new Uint8Array(Math.max(0, Number(size || 0)));
  if (fill) bitset.fill(1);
  return bitset;
}

function toNumberSet(values = []) {
  const out = new Set();
  for (const value of values) {
    const number = Number(value);
    if (Number.isInteger(number) && number >= 0) out.add(number);
  }
  return out;
}

function applyFilter(snapshot, candidateNodes, excludedNodes, filter, reasons) {
  const nodeCount = snapshot.nodeCount;
  const arrays = snapshot.arrays;
  if (!filter || typeof filter !== "object") return;

  if (filter.type === "nodeType") {
    const allowed = toNumberSet(filter.values || []);
    for (let index = 0; index < nodeCount; index += 1) {
      if (!allowed.has(arrays.nodeTypes[index])) {
        candidateNodes[index] = 0;
        reasons.NODE_TYPE_FILTER = (reasons.NODE_TYPE_FILTER || 0) + 1;
      }
    }
    return;
  }

  if (filter.type === "nodeFlagsAll") {
    const mask = Number(filter.mask || 0);
    for (let index = 0; index < nodeCount; index += 1) {
      if ((arrays.nodeFlags[index] & mask) !== mask) {
        candidateNodes[index] = 0;
        reasons.NODE_FLAGS_FILTER = (reasons.NODE_FLAGS_FILTER || 0) + 1;
      }
    }
    return;
  }

  if (filter.type === "nodeIdRange") {
    const min = Number(filter.min ?? 0);
    const max = Number(filter.max ?? nodeCount - 1);
    for (let index = 0; index < nodeCount; index += 1) {
      const nodeId = arrays.nodeIds[index] ?? index;
      if (nodeId < min || nodeId > max) {
        candidateNodes[index] = 0;
        reasons.NODE_ID_RANGE_FILTER = (reasons.NODE_ID_RANGE_FILTER || 0) + 1;
      }
    }
    return;
  }

  if (filter.type === "nodeIdSet") {
    const allowed = toNumberSet(filter.ids || []);
    for (let index = 0; index < nodeCount; index += 1) {
      const nodeId = arrays.nodeIds[index] ?? index;
      if (!allowed.has(nodeId)) {
        candidateNodes[index] = 0;
        reasons.NODE_ID_SET_FILTER = (reasons.NODE_ID_SET_FILTER || 0) + 1;
      }
    }
    return;
  }

  if (filter.type === "excludeNodeIds") {
    const excluded = toNumberSet(filter.ids || []);
    for (let index = 0; index < nodeCount; index += 1) {
      const nodeId = arrays.nodeIds[index] ?? index;
      if (excluded.has(nodeId)) {
        candidateNodes[index] = 0;
        excludedNodes[index] = 1;
        reasons.EXCLUDED_NODE_ID = (reasons.EXCLUDED_NODE_ID || 0) + 1;
      }
    }
    return;
  }

  reasons.UNKNOWN_FILTER = (reasons.UNKNOWN_FILTER || 0) + 1;
}

function buildQueryPlan({
  snapshot,
  filters = [],
  priorityNodeIds = [],
  edgePolicy = "visible",
  id = "query-default",
} = {}) {
  if (!snapshot || snapshot.contract !== "GraphSnapshot/v9.0") {
    return Object.freeze({
      contract: "QueryPlan/v9.0",
      id,
      ok: false,
      candidateNodes: new Uint8Array(0),
      excludedNodes: new Uint8Array(0),
      priorityNodes: new Uint32Array(0),
      edgePolicy: "none",
      filters: Object.freeze([]),
      reasons: Object.freeze({ SNAPSHOT_MISSING: 1 }),
      stats: Object.freeze({ candidates: 0, excluded: 0, priority: 0 }),
    });
  }

  const hasFilters = filters.length > 0;
  const candidateNodes = hasFilters ? makeBitset(snapshot.nodeCount, 1) : null;
  const excludedNodes = hasFilters ? makeBitset(snapshot.nodeCount, 0) : null;
  const reasons = {};
  for (const filter of filters) {
    applyFilter(snapshot, candidateNodes, excludedNodes, filter, reasons);
  }

  const priority = [];
  const requestedPriority = toNumberSet(priorityNodeIds);
  for (const nodeId of requestedPriority) {
    if (nodeId < snapshot.nodeCount && (!candidateNodes || candidateNodes[nodeId])) priority.push(nodeId);
  }

  let candidates = hasFilters ? 0 : snapshot.nodeCount;
  let excluded = 0;
  if (hasFilters) {
    for (let index = 0; index < snapshot.nodeCount; index += 1) {
      if (candidateNodes[index]) candidates += 1;
      if (excludedNodes[index]) excluded += 1;
    }
  }

  return Object.freeze({
    contract: "QueryPlan/v9.0",
    id,
    ok: true,
    candidateNodes,
    excludedNodes,
    priorityNodes: Uint32Array.from(priority),
    edgePolicy: ["visible", "backbone", "none"].includes(edgePolicy) ? edgePolicy : "visible",
    filters: Object.freeze(filters.map((filter) => Object.freeze({ ...filter }))),
    reasons: Object.freeze(reasons),
    stats: Object.freeze({
      candidates,
      excluded,
      priority: priority.length,
    }),
  });
}

module.exports = {
  buildQueryPlan,
  makeBitset,
};
