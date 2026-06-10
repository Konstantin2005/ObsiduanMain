function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = values.slice().sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[index];
}

function createCanvasBottleneckReport({ samples = [] } = {}) {
  const draw = [];
  const renderPlan = [];
  const storage = [];
  const query = [];
  for (const sample of samples) {
    draw.push(Number(sample.drawMs || 0));
    renderPlan.push(Number(sample.renderPlanMs || 0));
    storage.push(Number(sample.storageMs || 0));
    query.push(Number(sample.queryMs || 0));
  }
  return Object.freeze({
    contract: "CanvasBottleneckReport/v9.0",
    samples: samples.length,
    p95: Object.freeze({
      drawMs: Number(percentile(draw, 95).toFixed(3)),
      renderPlanMs: Number(percentile(renderPlan, 95).toFixed(3)),
      storageMs: Number(percentile(storage, 95).toFixed(3)),
      queryMs: Number(percentile(query, 95).toFixed(3)),
    }),
  });
}

function evaluateRendererUpgrade({
  report,
  targetFrameMs = 16,
  maxRenderPlanMs = 8,
  maxStorageMs = 50,
  maxQueryMs = 4,
} = {}) {
  const reasons = {};
  if (!report || report.contract !== "CanvasBottleneckReport/v9.0" || report.samples < 3) {
    reasons.NOT_ENOUGH_BENCHMARK_DATA = 1;
  }
  const p95 = report?.p95 || {};
  if (Number(p95.drawMs || 0) <= targetFrameMs) reasons.CANVAS_WITHIN_BUDGET = 1;
  if (Number(p95.renderPlanMs || 0) > maxRenderPlanMs) reasons.RENDERPLAN_NOT_READY = 1;
  if (Number(p95.storageMs || 0) > maxStorageMs) reasons.STORAGE_NOT_READY = 1;
  if (Number(p95.queryMs || 0) > maxQueryMs) reasons.QUERY_NOT_READY = 1;

  const allowed = Object.keys(reasons).length === 0;
  return Object.freeze({
    contract: "RendererUpgradeGate/v9.0",
    allowed,
    nextBackend: allowed ? "webgl-node-backend-prototype" : null,
    reasons: Object.freeze(reasons),
    report,
  });
}

module.exports = {
  createCanvasBottleneckReport,
  evaluateRendererUpgrade,
  percentile,
};
