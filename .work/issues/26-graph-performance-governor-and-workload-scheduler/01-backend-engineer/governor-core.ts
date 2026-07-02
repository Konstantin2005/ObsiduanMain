// Backend: Governor Core — Issue #26
// Resource monitoring and adaptive threshold engine

export class ResourceGovernor {
  private cpuMonitor: CPUMonitor;
  private memoryMonitor: MemoryMonitor;
  private throughputCounter: ThroughputCounter;
  private thresholdEngine: AdaptiveThresholdEngine;
  private throttleController: ThrottleController;

  constructor(config: GovernorConfig) {
    this.cpuMonitor = new CPUMonitor(config.maxCPUPercent);
    this.memoryMonitor = new MemoryMonitor(config.maxMemoryMB);
    this.throughputCounter = new ThroughputCounter();
    this.thresholdEngine = new AdaptiveThresholdEngine(config);
    this.throttleController = new ThrottleController(this.thresholdEngine);
  }

  async start(): Promise<void> {
    this.cpuMonitor.start();
    this.memoryMonitor.start();
    this.throughputCounter.start();
    this.thresholdEngine.start(this.getResourceSnapshot.bind(this));
  }

  async stop(): Promise<void> {
    this.cpuMonitor.stop();
    this.memoryMonitor.stop();
    this.throughputCounter.stop();
    this.thresholdEngine.stop();
  }

  private getResourceSnapshot(): ResourceUsage {
    return {
      cpuPercent: this.cpuMonitor.getUsage(),
      memoryMB: this.memoryMonitor.getUsage(),
      throughput: this.throughputCounter.getRate(),
    };
  }

  getCurrentUsage(): ResourceUsage {
    return this.getResourceSnapshot();
  }

  getThrottle(): ThrottleLevel {
    return this.throttleController.getCurrentThrottle();
  }

  getConfig(): GovernorConfig {
    return this.thresholdEngine.getConfig();
  }

  updateConfig(config: Partial<GovernorConfig>): void {
    this.thresholdEngine.updateConfig(config);
  }
}

export interface GovernorConfig {
  maxCPUPercent: number;
  maxMemoryMB: number;
  adaptive: boolean;
  backgroundQuota: number;
}

export interface ResourceUsage {
  cpuPercent: number;
  memoryMB: number;
  throughput: number;
}

export type ThrottleLevel = 'none' | 'light' | 'medium' | 'heavy' | 'critical';

class CPUMonitor {
  private interval: any = null;
  private usage: number = 0;
  private maxCPU: number;

  constructor(maxCPU: number) {
    this.maxCPU = maxCPU;
  }

  start(): void {
    this.interval = setInterval(() => {
      const usage = process.cpuUsage();
      this.usage = (usage.user + usage.system) / 1000000;
    }, 1000);
  }

  stop(): void {
    if (this.interval) clearInterval(this.interval);
  }

  getUsage(): number { return this.usage; }
}

class MemoryMonitor {
  private interval: any = null;
  private usage: number = 0;
  private maxMemory: number;

  constructor(maxMemory: number) {
    this.maxMemory = maxMemory;
  }

  start(): void {
    this.interval = setInterval(() => {
      const mem = process.memoryUsage();
      this.usage = Math.round(mem.heapUsed / 1024 / 1024);
    }, 1000);
  }

  stop(): void {
    if (this.interval) clearInterval(this.interval);
  }

  getUsage(): number { return this.usage; }
}

class ThroughputCounter {
  private ops: number[] = [];
  private interval: any = null;

  start(): void {
    this.interval = setInterval(() => {
      this.ops.push(0);
      if (this.ops.length > 10) this.ops.shift();
    }, 1000);
  }

  stop(): void {
    if (this.interval) clearInterval(this.interval);
  }

  increment(): void {
    if (this.ops.length > 0) {
      this.ops[this.ops.length - 1]++;
    }
  }

  getRate(): number {
    if (this.ops.length === 0) return 0;
    return this.ops.reduce((a, b) => a + b, 0) / this.ops.length;
  }
}

class AdaptiveThresholdEngine {
  private config: GovernorConfig;
  private baseline: ResourceUsage = { cpuPercent: 0, memoryMB: 0, throughput: 0 };
  private samples: ResourceUsage[] = [];
  private interval: any = null;

  constructor(config: GovernorConfig) {
    this.config = config;
  }

  start(snapshotFn: () => ResourceUsage): void {
    // Collect baseline over 30 seconds
    this.interval = setInterval(() => {
      this.samples.push(snapshotFn());
      if (this.samples.length > 30) this.samples.shift();
      this.computeBaseline();
    }, 1000);
  }

  stop(): void {
    if (this.interval) clearInterval(this.interval);
  }

  private computeBaseline(): void {
    if (this.samples.length === 0) return;
    this.baseline = {
      cpuPercent: this.samples.reduce((s, r) => s + r.cpuPercent, 0) / this.samples.length,
      memoryMB: this.samples.reduce((s, r) => s + r.memoryMB, 0) / this.samples.length,
      throughput: this.samples.reduce((s, r) => s + r.throughput, 0) / this.samples.length,
    };
  }

  getThresholds(): { cpuThreshold: number; memoryThreshold: number } {
    if (!this.config.adaptive) {
      return { cpuThreshold: this.config.maxCPUPercent, memoryThreshold: this.config.maxMemoryMB };
    }
    // Adaptive: 80% of max as warning, 95% as critical
    return {
      cpuThreshold: this.config.maxCPUPercent * 0.8,
      memoryThreshold: this.config.maxMemoryMB * 0.8,
    };
  }

  getConfig(): GovernorConfig { return this.config; }
  updateConfig(config: Partial<GovernorConfig>): void {
    Object.assign(this.config, config);
  }
}

class ThrottleController {
  private thresholdEngine: AdaptiveThresholdEngine;
  private currentThrottle: ThrottleLevel = 'none';

  constructor(engine: AdaptiveThresholdEngine) {
    this.thresholdEngine = engine;
  }

  getCurrentThrottle(): ThrottleLevel {
    return this.currentThrottle;
  }

  assessThrottle(usage: ResourceUsage): ThrottleLevel {
    const thresholds = this.thresholdEngine.getThresholds();
    const cpuRatio = usage.cpuPercent / thresholds.cpuThreshold;
    const memRatio = usage.memoryMB / thresholds.memoryThreshold;
    const maxRatio = Math.max(cpuRatio, memRatio);

    if (maxRatio >= 0.95) this.currentThrottle = 'critical';
    else if (maxRatio >= 0.85) this.currentThrottle = 'heavy';
    else if (maxRatio >= 0.75) this.currentThrottle = 'medium';
    else if (maxRatio >= 0.6) this.currentThrottle = 'light';
    else this.currentThrottle = 'none';

    return this.currentThrottle;
  }
}
