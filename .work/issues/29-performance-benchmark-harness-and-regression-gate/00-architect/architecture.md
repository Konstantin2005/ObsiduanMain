# Architecture: Performance Benchmark Harness and Regression Gate

## Module Structure
```
src/
  benchmark/
    harness/
      runner.ts        — Benchmark execution orchestrator
      scenarios.ts     — Predefined benchmark scenarios
      dataset.ts       — Test dataset loader
    metrics/
      render-time.ts   — Render performance measurement
      update-time.ts   — Update latency measurement
      memory.ts        — Memory profiler integration
      worker-load.ts   — Worker utilization metrics
      latency.ts       — Interaction latency measurement
    storage/
      baseline.ts      — Baseline data persistence
      history.ts       — Historical trend storage
    reporting/
      reporter.ts      — Report generator (markdown/HTML)
      comparator.ts    — Statistical comparison engine
    gate/
      thresholds.ts    — Regression threshold config
      checker.ts       — Gate check execution
      overrides.ts     — Allowlist/override mechanism
```

## API Design
```typescript
interface BenchmarkConfig {
  scenarios: string[];
  iterations: number;
  dataset: 'small' | 'medium' | 'large';
  warmupRuns: number;
  timeout: number;
}

interface BenchmarkResult {
  scenario: string;
  metrics: Record<string, MetricSample[]>;
  duration: number;
  timestamp: number;
  commit: string;
}

interface MetricSample {
  value: number;
  unit: string;
  label: string;
}

interface GateResult {
  passed: boolean;
  regressions: Regression[];
  thresholds: ThresholdConfig;
}
```
