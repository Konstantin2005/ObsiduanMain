# Plan: Unified AI Development OS

## Goals
- Один Orchestrator управляет ВСЕМИ репозиториями
- Multi-Repo Router определяет target
- Repository Adapters для каждого типа репо
- Единый shared context

## Этапы

### Phase 1 — Architect
- [x] Unified Architecture
- [x] Control Plane Design
- [x] Router + Adapter specs

### Phase 2 — Backend
- [ ] runtime/control-plane/ (3 JS)
- [ ] runtime/router/multi-repo-router.js
- [ ] adapters/ (3 JS)
- [ ] shared/global-context.json
- [ ] central-logs/

### Phase 3 — Frontend
- [ ] Migration plan
- [ ] Architecture docs

### Phase 4 — QA
- [ ] Failure modes
- [ ] Risks analysis

### Phase 5 — Review
- [ ] Final verdict
