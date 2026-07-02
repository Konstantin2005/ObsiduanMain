# Plan: Error Telemetry System

## Goals
- Добавить внешнюю систему логирования ошибок
- Не ломать execution
- Async, non-blocking
- Batching + flush

## Этапы

### Phase 1 — Architect
- [x] Архитектура telemetry layer
- [x] Определение компонентов

### Phase 2 — Backend
- [ ] ErrorLogger — сбор ошибок
- [ ] ErrorCollector — buffer queue
- [ ] Transport — git writer
- [ ] try/catch wrappers для агентов
- [ ] Pipeline error hooks
- [ ] Template engine error hooks

### Phase 3 — Frontend
- [ ] error-telemetry/ структура
- [ ] JSONL log format
- [ ] README

### Phase 4 — QA
- [ ] Unit tests
- [ ] Batch/flush timing tests
- [ ] Fallback tests

### Phase 5 — Review
- [ ] Финальное ревью
