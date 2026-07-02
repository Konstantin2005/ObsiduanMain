# Architectural Decisions — Error Telemetry

| # | Decision | Rationale | Status |
|---|----------|-----------|--------|
| 1 | Async buffer queue | Non-blocking execution | ✅ |
| 2 | JSONL files | Append-only, easy grep/search | ✅ |
| 3 | 3 retries on git push | Resilient to transient failures | ✅ |
| 4 | Local fallback | No data loss | ✅ |
| 5 | Separate severity levels | error, warning, critical | ✅ |
