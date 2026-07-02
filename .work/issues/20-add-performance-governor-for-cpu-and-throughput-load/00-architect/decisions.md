# Key Architectural Decisions

## ADR-1: Policy-Based Governor over Fixed Limiter
- **Context:** Need to handle variable workloads
- **Decision:** Policy engine evaluates thresholds dynamically
- **Consequence:** More flexible, slightly more complex

## ADR-2: Structured Logging for Telemetry
- **Context:** Need observability without separate pipeline
- **Decision:** Reuse existing structured logging infrastructure
- **Consequence:** Consistent with system-wide observability

## ADR-3: Graceful Degradation
- **Context:** User experience should degrade smoothly
- **Decision:** Progressive throttling (reduce → block → fallback)
- **Consequence:** Better UX but more states to test

## ADR-4: Rollback Support via Governor Bypass
- **Context:** If governor causes issues, rollback must be possible
- **Decision:** Governor can be disabled at runtime via config flag
- **Consequence:** Simple escape hatch, minimal overhead
