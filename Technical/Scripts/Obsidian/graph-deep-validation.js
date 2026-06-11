function pushError(errors, code, details, maxErrors) {
  if (errors.length >= maxErrors) return;
  errors.push(Object.freeze({ code, details: Object.freeze({ ...(details || {}) }) }));
}

function validateSnapshotDeep(snapshot, { maxErrors = 100 } = {}) {
  const errors = [];
  if (!snapshot || snapshot.contract !== "GraphSnapshot/v9.0") {
    pushError(errors, "SNAPSHOT_MISSING", {}, maxErrors);
    return Object.freeze({ contract: "DeepValidation/v9.0", ok: false, errors: Object.freeze(errors), stats: Object.freeze({}) });
  }

  const { nodeIds, edgeSources, edgeTargets, layoutX, layoutY } = snapshot.arrays;
  if (nodeIds.length !== snapshot.nodeCount) pushError(errors, "NODE_ID_LENGTH_MISMATCH", { actual: nodeIds.length, expected: snapshot.nodeCount }, maxErrors);
  if (layoutX.length !== snapshot.nodeCount) pushError(errors, "LAYOUT_X_LENGTH_MISMATCH", { actual: layoutX.length, expected: snapshot.nodeCount }, maxErrors);
  if (layoutY.length !== snapshot.nodeCount) pushError(errors, "LAYOUT_Y_LENGTH_MISMATCH", { actual: layoutY.length, expected: snapshot.nodeCount }, maxErrors);
  if (edgeSources.length !== snapshot.edgeCount) pushError(errors, "EDGE_SOURCE_LENGTH_MISMATCH", { actual: edgeSources.length, expected: snapshot.edgeCount }, maxErrors);
  if (edgeTargets.length !== snapshot.edgeCount) pushError(errors, "EDGE_TARGET_LENGTH_MISMATCH", { actual: edgeTargets.length, expected: snapshot.edgeCount }, maxErrors);

  const seenIds = new Set();
  let duplicateIds = 0;
  for (let index = 0; index < nodeIds.length; index += 1) {
    const nodeId = nodeIds[index];
    if (seenIds.has(nodeId)) {
      duplicateIds += 1;
      pushError(errors, "DUPLICATE_NODE_ID", { nodeId, index }, maxErrors);
    }
    seenIds.add(nodeId);
  }

  let invalidEdges = 0;
  for (let edgeId = 0; edgeId < Math.min(edgeSources.length, edgeTargets.length); edgeId += 1) {
    const source = edgeSources[edgeId];
    const target = edgeTargets[edgeId];
    if (source >= snapshot.nodeCount || target >= snapshot.nodeCount) {
      invalidEdges += 1;
      pushError(errors, "EDGE_ENDPOINT_OUT_OF_BOUNDS", { edgeId, source, target }, maxErrors);
    }
  }

  return Object.freeze({
    contract: "DeepValidation/v9.0",
    ok: errors.length === 0,
    errors: Object.freeze(errors),
    stats: Object.freeze({
      nodes: snapshot.nodeCount,
      edges: snapshot.edgeCount,
      duplicateIds,
      invalidEdges,
    }),
  });
}

function planStoreRepair(validation) {
  if (validation?.ok) {
    return Object.freeze({
      contract: "StoreRepairPlan/v9.0",
      required: false,
      action: "none",
      reason: "deep-validation-ok",
    });
  }
  const codes = new Set((validation?.errors || []).map((error) => error.code));
  const action = codes.has("SNAPSHOT_MISSING") ? "rebuild-store" : "rebuild-current-then-keep-previous";
  return Object.freeze({
    contract: "StoreRepairPlan/v9.0",
    required: true,
    action,
    reason: Array.from(codes).sort().join(","),
  });
}

module.exports = {
  planStoreRepair,
  validateSnapshotDeep,
};
