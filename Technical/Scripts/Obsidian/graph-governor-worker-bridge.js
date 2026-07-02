const os = require("os");
const {
  ThroughputGovernor,
  evaluateSla,
  createResourceProfile,
  createDashboardSample,
  shouldSampleDashboard,
  SLA_MODE,
  GOVERNOR_ACTION,
  DEFAULT_POLICY,
} = require("./graph-throughput-governor.js");

const MIN_OBSERVE_INTERVAL_MS = 100;
const MAX_DECISIONS_HISTORY = 100;

class GovernorWorkerBridge {
  constructor({
    governor = null,
    workerController = null,
    policy = DEFAULT_POLICY,
    thresholds = {},
  } = {}) {
    this.governor = governor || new ThroughputGovernor({ policy, thresholds });
    this.workerController = workerController || null;
    this.lastObserveAtMs = 0;
    this.lastDashboardAtMs = 0;
    this.currentDecision = null;
    this.decisions = [];
    this._emergency = false;
  }

  observe(sample = {}) {
    const now = Date.now();
    if (now - this.lastObserveAtMs < MIN_OBSERVE_INTERVAL_MS) {
      return this.currentDecision;
    }
    this.lastObserveAtMs = now;

    const profile = this.#collectResourceProfile(sample);
    const slaReport = evaluateSla({
      mode: this.governor.policy.mode,
      metrics: sample.metrics || {},
    });
    const previousSample = this.governor.decisions.length > 0
      ? { usefulFactsPerSec: this.governor.decisions[this.governor.decisions.length - 1]?.throughput?.usefulFactsPerSec || 0 }
      : {};

    const decision = this.governor.observe({
      slaReport,
      resourceProfile: profile,
      sample: { ...sample, ...this.#collectSystemSignals() },
      previousSample,
    });

    this.currentDecision = decision;
    this.decisions.push(decision);
    if (this.decisions.length > MAX_DECISIONS_HISTORY) {
      this.decisions.splice(0, this.decisions.length - MAX_DECISIONS_HISTORY);
    }

    this.#applyDecision(decision);

    if (this.workerController && shouldSampleDashboard({
      lastSampleAtMs: this.lastDashboardAtMs,
      nowMs: now,
      maxHz: this.governor.policy.dashboardMaxHz,
    })) {
      this.lastDashboardAtMs = now;
      this.dashboardSample = createDashboardSample({
        policy: this.governor.policy,
        slaReport,
        decision,
        metrics: sample.metrics || {},
      });
    }

    return decision;
  }

  #collectResourceProfile(sample) {
    return createResourceProfile({
      staticCaps: {
        logicalCores: os.cpus()?.length || 1,
        totalMemoryMb: Math.floor(os.totalmem() / 1024 / 1024),
        platform: process.platform,
        nodeVersion: process.version,
        arch: process.arch,
      },
      observedCaps: {
        eventLoopDelayP95: sample.metrics?.eventLoopDelayP95 || 0,
        eventLoopDelayP99: sample.metrics?.eventLoopDelayP99 || 0,
        usefulFactsPerSec: sample.metrics?.usefulFactsPerSec || 0,
        parseFilesPerSec: sample.metrics?.parseFilesPerSec || 0,
        readMbPerSec: sample.metrics?.readMbPerSec || 0,
        serializationMsPerMb: sample.metrics?.serializationMsPerMb || 0,
        gcPauseMs: sample.metrics?.gcPauseMs || 0,
        snapshotWriteMbPerSec: sample.metrics?.snapshotWriteMbPerSec || 0,
        publishCriticalSectionMs: sample.metrics?.publishCriticalSectionMs || 0,
      },
      confidence: sample.metrics?.confidence || 0.5,
    });
  }

  #collectSystemSignals() {
    const mem = process.memoryUsage();
    const freemem = os.freemem();
    const totalmem = os.totalmem();
    return {
      memoryPressure: freemem / totalmem < 0.15,
      memoryUsedRatio: 1 - freemem / totalmem,
      batterySafeMode: false,
    };
  }

  #applyDecision(decision) {
    if (!this.workerController) return;

    const policy = decision.nextPolicy;
    const actions = decision.actions;

    if (actions.includes(GOVERNOR_ACTION.EMERGENCY_THROTTLE)) {
      this._emergency = true;
      this.workerController.cancelStale("emergency-throttle");
      this.workerController.setWorkerConfig({
        workerCount: policy.workerCount,
        chunkBytes: policy.chunkBytes,
        maxInFlightBytes: policy.maxInFlightBytes,
        maxReadConcurrency: policy.maxReadConcurrency,
        pauseIoMs: policy.pauseIoMs,
        cacheOnlyLowPriority: policy.cacheOnlyLowPriority,
      });
      return;
    }

    if (this._emergency && !actions.includes(GOVERNOR_ACTION.EMERGENCY_THROTTLE)) {
      this._emergency = false;
    }

    this.workerController.setWorkerConfig({
      workerCount: policy.workerCount,
      chunkBytes: policy.chunkBytes,
      maxInFlightBytes: policy.maxInFlightBytes,
      maxReadConcurrency: policy.maxReadConcurrency,
      pauseIoMs: policy.pauseIoMs || 0,
      cacheOnlyLowPriority: policy.cacheOnlyLowPriority || false,
    });
  }

  getWorkerConfig() {
    return this.workerController ? this.workerController.getWorkerConfig() : null;
  }

  emergencyStop() {
    this._emergency = true;
    if (this.workerController) {
      this.workerController.cancelStale("emergency-stop");
      this.workerController.setWorkerConfig({
        workerCount: 1,
        chunkBytes: 256 * 1024,
        maxInFlightBytes: 256 * 1024,
        maxReadConcurrency: 1,
        pauseIoMs: 1000,
        cacheOnlyLowPriority: true,
      });
    }
  }

  resume() {
    this._emergency = false;
    if (this.workerController) {
      this.workerController.setWorkerConfig({
        workerCount: DEFAULT_POLICY.workerCount,
        chunkBytes: DEFAULT_POLICY.chunkBytes,
        maxInFlightBytes: DEFAULT_POLICY.maxInFlightBytes,
        maxReadConcurrency: DEFAULT_POLICY.maxReadConcurrency,
        pauseIoMs: 0,
        cacheOnlyLowPriority: false,
      });
    }
  }

  snapshot() {
    return {
      contract: "GovernorWorkerBridge/v1.0",
      emergency: this._emergency,
      decisionCount: this.decisions.length,
      currentDecision: this.currentDecision,
      dashboardSample: this.dashboardSample || null,
    };
  }
}

module.exports = {
  GovernorWorkerBridge,
};
