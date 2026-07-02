# Key Decisions: Performance Benchmark Harness and Regression Gate

## ADR-1: Statistical comparison over absolute thresholds
- **Decision:** Use mean + confidence intervals for regression detection
- **Rationale:** Absolute thresholds are noisy; statistical accounts for variance
- **Trade-off:** Requires multiple runs (at least 10) for statistical significance

## ADR-2: Dedicated test dataset over live data
- **Decision:** Use stable, versioned synthetic datasets
- **Rationale:** Live data changes between runs, makes comparison meaningless
- **Trade-off:** Synthetic data may not represent real-world patterns

## ADR-3: Warmup runs to reduce noise
- **Decision:** Execute 3-5 warmup runs before collecting measurements
- **Rationale:** JIT compilation, cache warming, and memory allocation stabilize after warmup
- **Trade-off:** Longer benchmark execution time

## ADR-4: Markdown reports with trend visualization
- **Decision:** Generate human-readable Markdown reports with ASCII trend charts
- **Rationale:** PR comments render Markdown natively; no external visualization dependency
- **Trade-off:** Limited visual fidelity compared to dedicated dashboard
