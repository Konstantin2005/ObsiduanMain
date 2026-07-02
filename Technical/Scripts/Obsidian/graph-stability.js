const fs = require("fs");
const path = require("path");
const { FAILURE_SEVERITY, createFailureState } = require("../Rendering/graph-critical-frame.js");

const STABILITY_STATE = Object.freeze({
  NORMAL: "NORMAL",
  STORE_DEGRADED: "STORE_DEGRADED",
  RENDERER_DEGRADED: "RENDERER_DEGRADED",
  FRAME_PRESSURE: "FRAME_PRESSURE",
  PAUSED: "PAUSED",
  SAFE_NATIVE: "SAFE_NATIVE",
});

const SAFE_NATIVE_PROFILE = Object.freeze({
  name: "fast-backbone",
  search: "path:Calendula OR path:\"Соц Капитал\"",
  showTags: false,
  showAttachments: false,
  hideUnresolved: true,
  showOrphans: false,
  animate: false,
  centerStrength: 0.05,
  repelStrength: 6,
  linkStrength: 0.35,
  linkDistance: 80,
  scale: 0.8,
  closeUltraGraph: true,
});

function nowIso() {
  return new Date().toISOString();
}

function safeMessage(error) {
  return String(error && (error.message || error.stack) ? error.message || error.stack : error);
}

function freezeIncident(entry) {
  return Object.freeze({
    at: entry.at || nowIso(),
    state: entry.state || STABILITY_STATE.NORMAL,
    severity: entry.severity || FAILURE_SEVERITY.RECOVERABLE,
    code: entry.code || "GRAPH_STABILITY_EVENT",
    message: entry.message || "",
    action: entry.action || "observe",
    frameId: entry.frameId ?? null,
    details: Object.freeze({ ...(entry.details || {}) }),
  });
}

class IncidentLog {
  constructor({ filePath = null, maxEntries = 200 } = {}) {
    this.filePath = filePath ? path.resolve(filePath) : null;
    this.maxEntries = Math.max(1, Number(maxEntries || 200));
    this.entries = [];
  }

  record(entry) {
    const frozen = freezeIncident(entry);
    this.entries.push(frozen);
    if (this.entries.length > this.maxEntries) {
      this.entries.splice(0, this.entries.length - this.maxEntries);
    }
    if (this.filePath) {
      try {
        fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
        fs.appendFileSync(this.filePath, `${JSON.stringify(frozen)}\n`, "utf8");
      } catch (error) {
        const logFailure = freezeIncident({
          state: STABILITY_STATE.STORE_DEGRADED,
          severity: FAILURE_SEVERITY.RECOVERABLE,
          code: "INCIDENT_LOG_WRITE_FAILED",
          message: safeMessage(error),
          action: "keep-in-memory-log",
        });
        this.entries.push(logFailure);
      }
    }
    return frozen;
  }

  snapshot() {
    return Object.freeze({
      count: this.entries.length,
      entries: Object.freeze(this.entries.slice()),
    });
  }
}

function stateForFailure(failureState) {
  if (!failureState) return STABILITY_STATE.NORMAL;
  if (failureState.severity === FAILURE_SEVERITY.FATAL) return STABILITY_STATE.SAFE_NATIVE;
  if (failureState.severity === FAILURE_SEVERITY.BLOCKING) return STABILITY_STATE.PAUSED;
  if (failureState.code && failureState.code.startsWith("CANVAS")) return STABILITY_STATE.RENDERER_DEGRADED;
  return STABILITY_STATE.STORE_DEGRADED;
}

function actionForState(state) {
  if (state === STABILITY_STATE.SAFE_NATIVE) return "apply-safe-native-profile";
  if (state === STABILITY_STATE.PAUSED) return "pause-ultra-graph-and-offer-rebuild";
  if (state === STABILITY_STATE.RENDERER_DEGRADED) return "disable-expensive-rendering";
  if (state === STABILITY_STATE.FRAME_PRESSURE) return "reduce-frame-work";
  if (state === STABILITY_STATE.STORE_DEGRADED) return "continue-with-recovered-store";
  return "observe";
}

class GraphStabilityController {
  constructor({ incidentLog = new IncidentLog(), recoveryFrames = 5 } = {}) {
    this.incidentLog = incidentLog;
    this.recoveryFrames = Math.max(1, Number(recoveryFrames || 5));
    this.state = STABILITY_STATE.NORMAL;
    this.lastFailure = null;
    this.stableFrames = 0;
    this.transitions = 0;
  }

  transition(nextState, event = {}) {
    if (!nextState || nextState === this.state) {
      return this.getSnapshot();
    }
    this.state = nextState;
    this.transitions += 1;
    this.incidentLog.record({
      state: nextState,
      severity: event.severity,
      code: event.code || `STATE_${nextState}`,
      message: event.message || `Graph stability entered ${nextState}`,
      action: event.action || actionForState(nextState),
      frameId: event.frameId,
      details: event.details,
    });
    return this.getSnapshot();
  }

  recordStoreLoadResult(result) {
    if (!result || !result.ok) {
      const failureState =
        result?.failureState ||
        createFailureState({
          severity: FAILURE_SEVERITY.BLOCKING,
          code: "STORE_LOAD_RESULT_MISSING",
          message: "Store load result is missing or failed without FailureState",
          failures: result?.failures || [],
        });
      this.lastFailure = failureState;
      return this.transition(stateForFailure(failureState), {
        severity: failureState.severity,
        code: failureState.code,
        message: failureState.message,
        details: { failures: failureState.failures.length },
      });
    }

    this.lastFailure = null;
    if (result.recoveredFromPrevious) {
      return this.transition(STABILITY_STATE.STORE_DEGRADED, {
        severity: FAILURE_SEVERITY.RECOVERABLE,
        code: "STORE_RECOVERED_FROM_PREVIOUS",
        message: "Graph Store current failed and previous was used",
        action: "continue-with-recovered-store",
        details: { activeDir: result.snapshot?.activeDir || "graph.previous" },
      });
    }

    this.stableFrames += 1;
    if (this.state !== STABILITY_STATE.NORMAL && this.stableFrames >= this.recoveryFrames) {
      return this.transition(STABILITY_STATE.NORMAL, {
        severity: FAILURE_SEVERITY.RECOVERABLE,
        code: "STORE_RECOVERED",
        message: "Graph Store returned to normal",
        action: "resume-normal-rendering",
      });
    }
    return this.getSnapshot();
  }

  recordFrameStats(frameStats) {
    if (!frameStats) return this.getSnapshot();
    if (frameStats.failureState) {
      this.lastFailure = frameStats.failureState;
      this.stableFrames = 0;
      return this.transition(stateForFailure(frameStats.failureState), {
        severity: frameStats.failureState.severity,
        code: frameStats.failureState.code,
        message: frameStats.failureState.message,
        frameId: frameStats.frameId,
        details: { backendId: frameStats.backendId },
      });
    }

    const frameBudget = Number(frameStats.budgets?.frameBudgetMs || 16);
    const total = Number(frameStats.timingsMs?.total || frameStats.timingsMs?.draw || 0);
    if (total > frameBudget) {
      this.lastFailure = null;
      this.stableFrames = 0;
      return this.transition(STABILITY_STATE.FRAME_PRESSURE, {
        severity: FAILURE_SEVERITY.DEGRADED,
        code: "FRAME_BUDGET_EXCEEDED",
        message: `Frame exceeded budget: ${total}ms > ${frameBudget}ms`,
        action: "reduce-frame-work",
        frameId: frameStats.frameId,
        details: { total, frameBudget },
      });
    }

    this.stableFrames += 1;
    if (
      (this.state === STABILITY_STATE.FRAME_PRESSURE || this.state === STABILITY_STATE.RENDERER_DEGRADED) &&
      this.stableFrames >= this.recoveryFrames
    ) {
      return this.transition(STABILITY_STATE.NORMAL, {
        severity: FAILURE_SEVERITY.RECOVERABLE,
        code: "RENDERER_RECOVERED",
        message: "Renderer frame stats returned to budget",
        action: "resume-normal-rendering",
        frameId: frameStats.frameId,
      });
    }
    return this.getSnapshot();
  }

  shouldRender() {
    return this.state !== STABILITY_STATE.PAUSED && this.state !== STABILITY_STATE.SAFE_NATIVE;
  }

  getSafeFallbackProfile() {
    return SAFE_NATIVE_PROFILE;
  }

  getSnapshot() {
    return Object.freeze({
      contract: "GraphStability/v9.0",
      state: this.state,
      canRender: this.shouldRender(),
      safeFallbackProfile: this.state === STABILITY_STATE.SAFE_NATIVE || this.state === STABILITY_STATE.PAUSED ? SAFE_NATIVE_PROFILE : null,
      lastFailure: this.lastFailure,
      stableFrames: this.stableFrames,
      transitions: this.transitions,
      incidents: this.incidentLog.snapshot(),
    });
  }
}

module.exports = {
  GraphStabilityController,
  IncidentLog,
  SAFE_NATIVE_PROFILE,
  STABILITY_STATE,
};
