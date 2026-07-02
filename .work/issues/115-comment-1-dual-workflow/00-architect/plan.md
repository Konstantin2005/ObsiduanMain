# Plan: Dual-Workflow Architecture

## Goals
- Разделить agent-core и ai-dev-orchestration-system
- Создать bridge layer
- Настроить изоляцию
- Исключить watcher loop, re-index, file feedback loops

## Этапы

### Phase 1 — Architect
- [x] Анализ требований
- [x] Проектирование архитектуры
- [x] Определение границ

### Phase 2 — Backend
- [ ] Bridge layer implementation (JS)
- [ ] Agent mapping
- [ ] Pipeline mapping
- [ ] Template adapter

### Phase 3 — Frontend
- [ ] Финальная структура папок
- [ ] .opencodeignore
- [ ] .gitignore
- [ ] opencode.jsonc

### Phase 4 — QA
- [ ] Loop detection test
- [ ] Isolation verification

### Phase 5 — Review
- [ ] Финальное ревью
