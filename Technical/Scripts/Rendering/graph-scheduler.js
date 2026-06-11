const { buildRenderPlan } = require("./graph-render-plan.js");

function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = values.slice().sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[index];
}

function freezeSignalMap(signals) {
  return Object.freeze({
    frameOverBudget: Boolean(signals.frameOverBudget),
    memoryPressure: Boolean(signals.memoryPressure),
    workerLag: Boolean(signals.workerLag),
    inputBurst: Boolean(signals.inputBurst),
    profileSwitch: Boolean(signals.profileSwitch),
    indexStale: Boolean(signals.indexStale),
    rendererQueueTooLong: Boolean(signals.rendererQueueTooLong),
  });
}

class GraphScheduler {
  constructor({ maxHistory = 120, renderPlanBuilder = buildRenderPlan } = {}) {
    this.maxHistory = maxHistory;
    this.renderPlanBuilder = renderPlanBuilder;
    this.frameDurations = [];
    this.frameId = 0;
    this.generation = 0;
  }

  recordFrame(durationMs) {
    const value = Number(durationMs);
    if (!Number.isFinite(value) || value < 0) return;
    this.frameDurations.push(value);
    if (this.frameDurations.length > this.maxHistory) {
      this.frameDurations.splice(0, this.frameDurations.length - this.maxHistory);
    }
  }

  getFrameHistory() {
    return Object.freeze({
      count: this.frameDurations.length,
      p95FrameMs: percentile(this.frameDurations, 95),
      maxFrameMs: this.frameDurations.length ? Math.max(...this.frameDurations) : 0,
    });
  }

  detectBackpressure(input = {}) {
    const history = this.getFrameHistory();
    return freezeSignalMap({
      frameOverBudget: history.p95FrameMs > 24,
      memoryPressure: input.memoryPressure,
      workerLag: input.workerLagMs > 250 || input.workerLag === true,
      inputBurst: input.inputBurst === true || input.pointerEventsPerSecond > 60,
      profileSwitch: input.profileSwitch === true,
      indexStale: input.indexStale === true,
      rendererQueueTooLong: input.rendererQueueLength > 2,
    });
  }

  actionsFor(signals) {
    const actions = [];
    if (signals.profileSwitch || signals.rendererQueueTooLong) actions.push("drop-stale-frames");
    if (signals.inputBurst || signals.frameOverBudget || signals.memoryPressure) actions.push("cancel-labels");
    if (signals.inputBurst || signals.frameOverBudget || signals.rendererQueueTooLong) actions.push("cancel-low-priority-edges");
    if (signals.frameOverBudget || signals.memoryPressure) actions.push("increase-lod");
    if (signals.frameOverBudget || signals.inputBurst) actions.push("reduce-batch-size");
    if (signals.workerLag || signals.memoryPressure) actions.push("pause-background-index-work");
    if (signals.indexStale) actions.push("show-index-stale-badge");
    return Object.freeze([...new Set(actions)]);
  }

  adaptProfile(profile, signals) {
    const next = {
      ...profile,
      maxVisibleNodes: Number(profile?.maxVisibleNodes || 3000),
      maxVisibleEdges: Number(profile?.maxVisibleEdges || 5000),
    };

    if (signals.inputBurst || signals.rendererQueueTooLong) {
      next.maxVisibleEdges = Math.max(0, Math.floor(next.maxVisibleEdges * 0.25));
      next.labelPolicy = "none";
    }
    if (signals.frameOverBudget) {
      next.maxVisibleNodes = Math.max(100, Math.floor(next.maxVisibleNodes * 0.7));
      next.maxVisibleEdges = Math.max(0, Math.floor(next.maxVisibleEdges * 0.4));
      next.labelPolicy = "none";
    }
    if (signals.memoryPressure) {
      next.maxVisibleNodes = Math.min(next.maxVisibleNodes, 500);
      next.maxVisibleEdges = 0;
      next.labelPolicy = "none";
    }
    return Object.freeze(next);
  }

  scheduleFrame({ storeRoot, profile, camera, input = {} } = {}) {
    if (input.profileSwitch) {
      this.generation += 1;
    }
    this.frameId += 1;
    const signals = this.detectBackpressure(input);
    const actions = this.actionsFor(signals);
    const adaptiveProfile = this.adaptProfile(profile || {}, signals);
    const plan = this.renderPlanBuilder({
      storeRoot,
      profile: adaptiveProfile,
      camera,
      frameHistory: this.getFrameHistory(),
      memoryPressure: signals.memoryPressure,
      frameId: this.frameId,
    });
    return Object.freeze({
      frameId: this.frameId,
      generation: this.generation,
      signals,
      actions,
      adaptiveProfile,
      plan,
    });
  }
}

module.exports = {
  GraphScheduler,
  percentile,
};
