const DEFAULT_LIMITS = Object.freeze({
  targetFrameMs: 16,
  warningFrameMs: 20,
  pressureFrameMs: 24,
  emergencyFrameMs: 32,
  maxSnapshotBytes: 256 * 1024 * 1024,
  maxColdLoadBytes: 32 * 1024 * 1024,
  manifestReadMs: 50,
  shallowValidationMs: 100,
  arrayLoadMs: 500,
});

function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = values.slice().sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[index];
}

function sumArrayBytes(arrays = {}) {
  let total = 0;
  const loadedArrays = [];
  for (const [name, value] of Object.entries(arrays)) {
    if (!value || typeof value.byteLength !== "number") continue;
    total += value.byteLength;
    loadedArrays.push(name);
  }
  return {
    bytes: total,
    loadedArrays: Object.freeze(loadedArrays),
  };
}

class BudgetPolicy {
  constructor({
    nodeBudget = 3000,
    edgeBudget = 1000,
    minNodeBudget = 250,
    minEdgeBudget = 0,
    targetFrameMs = DEFAULT_LIMITS.targetFrameMs,
  } = {}) {
    this.nodeBudget = Math.max(0, Number(nodeBudget));
    this.edgeBudget = Math.max(0, Number(edgeBudget));
    this.minNodeBudget = Math.max(0, Number(minNodeBudget));
    this.minEdgeBudget = Math.max(0, Number(minEdgeBudget));
    this.targetFrameMs = Math.max(1, Number(targetFrameMs));
  }

  resolve({ mode = "steady", framePressure = "normal", memoryPressure = false, ioPressure = false, inputBurst = false } = {}) {
    let nodeBudget = this.nodeBudget;
    let edgeBudget = this.edgeBudget;
    const reasons = {};

    if (inputBurst || mode === "interactive") {
      edgeBudget = 0;
      nodeBudget = Math.floor(nodeBudget * 0.75);
      reasons.INPUT_BURST = 1;
    }

    if (framePressure === "pressure" || mode === "degraded") {
      nodeBudget = Math.floor(nodeBudget * 0.45);
      edgeBudget = Math.floor(edgeBudget * 0.25);
      reasons.FRAME_PRESSURE = 1;
    } else if (framePressure === "warning") {
      nodeBudget = Math.floor(nodeBudget * 0.75);
      edgeBudget = Math.floor(edgeBudget * 0.5);
      reasons.FRAME_WARNING = 1;
    } else if (framePressure === "emergency" || mode === "emergency") {
      nodeBudget = Math.floor(nodeBudget * 0.16);
      edgeBudget = 0;
      reasons.FRAME_EMERGENCY = 1;
    }

    if (memoryPressure || mode === "memory-pressure") {
      nodeBudget = Math.min(nodeBudget, 500);
      edgeBudget = 0;
      reasons.MEMORY_PRESSURE = 1;
    }

    if (ioPressure) {
      edgeBudget = Math.floor(edgeBudget * 0.5);
      reasons.IO_PRESSURE = 1;
    }

    return Object.freeze({
      nodeBudget: Math.max(this.minNodeBudget, Math.floor(nodeBudget)),
      edgeBudget: Math.max(this.minEdgeBudget, Math.floor(edgeBudget)),
      labelBudget: 0,
      frameBudgetMs: this.targetFrameMs,
      reasons: Object.freeze(reasons),
    });
  }
}

class FrameGovernor {
  constructor({ maxHistory = 120, limits = DEFAULT_LIMITS } = {}) {
    this.maxHistory = Math.max(1, Number(maxHistory || 120));
    this.limits = { ...DEFAULT_LIMITS, ...limits };
    this.frames = [];
  }

  recordFrameStats(frameStats) {
    if (!frameStats) return this.getSnapshot();
    const total = Number(frameStats.timingsMs?.total || frameStats.timingsMs?.draw || 0);
    if (!Number.isFinite(total) || total < 0) return this.getSnapshot();
    this.frames.push(total);
    if (this.frames.length > this.maxHistory) {
      this.frames.splice(0, this.frames.length - this.maxHistory);
    }
    return this.getSnapshot();
  }

  getPressureLevel() {
    const p95 = percentile(this.frames, 95);
    if (p95 > this.limits.emergencyFrameMs) return "emergency";
    if (p95 > this.limits.pressureFrameMs) return "pressure";
    if (p95 > this.limits.warningFrameMs) return "warning";
    return "normal";
  }

  getSnapshot() {
    const p95 = percentile(this.frames, 95);
    return Object.freeze({
      contract: "FrameGovernor/v9.0",
      count: this.frames.length,
      p95FrameMs: Number(p95.toFixed(3)),
      maxFrameMs: this.frames.length ? Number(Math.max(...this.frames).toFixed(3)) : 0,
      pressure: this.getPressureLevel(),
    });
  }
}

class MemoryGovernor {
  constructor({ maxSnapshotBytes = DEFAULT_LIMITS.maxSnapshotBytes, maxColdLoadBytes = DEFAULT_LIMITS.maxColdLoadBytes } = {}) {
    this.maxSnapshotBytes = Math.max(1, Number(maxSnapshotBytes));
    this.maxColdLoadBytes = Math.max(0, Number(maxColdLoadBytes));
    this.snapshotBytes = 0;
    this.loadedArrays = Object.freeze([]);
  }

  observeSnapshot(snapshot) {
    const usage = sumArrayBytes(snapshot?.arrays || {});
    this.snapshotBytes = usage.bytes;
    this.loadedArrays = usage.loadedArrays;
    return this.getSnapshot();
  }

  canLoadColdData(bytes = 0) {
    const requested = Math.max(0, Number(bytes));
    return !this.isUnderPressure() && requested <= this.maxColdLoadBytes;
  }

  isUnderPressure() {
    return this.snapshotBytes > this.maxSnapshotBytes;
  }

  getSnapshot() {
    return Object.freeze({
      contract: "MemoryGovernor/v9.0",
      snapshotBytes: this.snapshotBytes,
      maxSnapshotBytes: this.maxSnapshotBytes,
      loadedArrays: this.loadedArrays,
      pressure: this.isUnderPressure(),
      coldLoadsAllowed: this.canLoadColdData(0),
    });
  }
}

class IOGovernor {
  constructor({ limits = DEFAULT_LIMITS } = {}) {
    this.limits = { ...DEFAULT_LIMITS, ...limits };
    this.timingsMs = Object.freeze({});
  }

  observeSnapshot(snapshot) {
    this.timingsMs = Object.freeze({ ...(snapshot?.timingsMs || {}) });
    return this.getSnapshot();
  }

  isUnderPressure() {
    return (
      Number(this.timingsMs.manifestRead || 0) > this.limits.manifestReadMs ||
      Number(this.timingsMs.shallowValidation || 0) > this.limits.shallowValidationMs ||
      Number(this.timingsMs.arrayLoad || 0) > this.limits.arrayLoadMs
    );
  }

  canRunBeforeFirstFrame(operation) {
    return ["manifest", "shallow-validation", "minimal-array-load"].includes(operation);
  }

  shouldDefer(operation) {
    if (this.canRunBeforeFirstFrame(operation)) return false;
    return true;
  }

  getSnapshot() {
    return Object.freeze({
      contract: "IOGovernor/v9.0",
      timingsMs: this.timingsMs,
      pressure: this.isUnderPressure(),
      deferredByDefault: Object.freeze(["deep-validation", "strings", "labels", "query-indexes", "repair-rebuild"]),
    });
  }
}

module.exports = {
  BudgetPolicy,
  DEFAULT_LIMITS,
  FrameGovernor,
  IOGovernor,
  MemoryGovernor,
  percentile,
  sumArrayBytes,
};
