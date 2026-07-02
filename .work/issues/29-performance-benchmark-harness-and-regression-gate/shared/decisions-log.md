# Decisions Log

## ADR-1: Statistical comparison over absolute thresholds
- **Decision:** Mean + confidence intervals
- **Rationale:** Accounts for variance
- **Date:** 2026-06-27

## ADR-2: Dedicated test dataset over live data
- **Decision:** Stable, versioned synthetic datasets
- **Rationale:** Live data changes; incomparable
- **Date:** 2026-06-27

## ADR-3: Warmup runs to reduce noise
- **Decision:** 3-5 warmup runs before measuring
- **Rationale:** Stabilize JIT, cache, memory
- **Date:** 2026-06-27

## ADR-4: Markdown reports with trend visualization
- **Decision:** Markdown with ASCII charts
- **Rationale:** Native in PR comments; no deps
- **Date:** 2026-06-27
