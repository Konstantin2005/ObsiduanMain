# Architectural Decisions — Dual-Workflow

| # | Decision | Rationale | Status |
|---|----------|-----------|--------|
| 1 | Reference system excluded from indexing | No re-index storm, no noise | ✅ |
| 2 | Bridge layer is part of agent-core | Единая codebase, без внешних зависимостей | ✅ |
| 3 | No runtime import between lines | Zero coupling, no loop risk | ✅ |
| 4 | Bridge reads reference patterns at build/design time only | Runtime не зависит от reference | ✅ |
