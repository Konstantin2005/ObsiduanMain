# Plan: Error → Task → Execution Pipeline

## Goals
- Автоматически превращать ошибки в задачи
- Выполнять задачи без дополнительного анализа
- Не блокировать system execution

## Этапы

### Phase 1 — Architect
- [x] Архитектура pipeline
- [x] Task schema
- [x] State machine

### Phase 2 — Backend
- [ ] ErrorCaptureLayer — async intercept
- [ ] TaskNormalizer — error → task
- [ ] TaskSchema (JSON)
- [ ] TaskRunner — execute fix
- [ ] TaskPicker — select next
- [ ] TaskStatusManager — lifecycle

### Phase 3 — Frontend
- [ ] error-task-queue/ repo structure
- [ ] State machine diagram
- [ ] Task lifecycle docs

### Phase 4 — QA
- [ ] Deduplication tests
- [ ] State machine transition tests
- [ ] Integration tests

### Phase 5 — Review
- [ ] Финальное ревью
