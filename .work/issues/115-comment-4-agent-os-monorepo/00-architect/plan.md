# Plan: Agent OS Monorepo

## Goals
- Объединить 4 системы + bridge в единый monorepo
- Разделить execution, reference, telemetry, task-queue
- Добавить lifecycle: error → incoming → task → execution → archive

## Этапы

### Phase 1 — Architect
- [x] Финальная структура monorepo
- [x] Module responsibilities map

### Phase 2 — Backend
- [ ] Создать agent-os/ структуру
- [ ] Bridge lifecycle.js
- [ ] package.json
- [ ] Ignore configs

### Phase 3 — Frontend
- [ ] lifecycle.md
- [ ] README.md

### Phase 4 — QA
- [ ] Loop safety check
- [ ] Isolation verification

### Phase 5 — Review
- [ ] Финальное ревью
