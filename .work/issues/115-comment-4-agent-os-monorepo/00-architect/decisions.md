# Decisions — Agent OS Monorepo

| # | Decision | Rationale | Status |
|---|----------|-----------|--------|
| 1 | Monorepo structure | Единая точка входа, общие configs | ✅ |
| 2 | orchestration/ excluded from index | Read-only reference, не runtime | ✅ |
| 3 | lifecycle.js orchestrates flow | Единый entry point для error→task→execution | ✅ |
| 4 | No cross-import между runtime модулями | Bridge как единственный интегратор | ✅ |
| 5 | telemetry + task-queue data excluded | Runtime output не индексируется | ✅ |
