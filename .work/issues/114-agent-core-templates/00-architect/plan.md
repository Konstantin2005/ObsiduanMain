# Plan: Agent Core Templates (#114)

## Goals
- Создать отдельный репозиторий `agent-core/` с JS Agent Core системой
- Разработать полноценный Template Engine
- Портировать и расширить шаблоны из `Main/.work/templates/`
- Отрефакторить агентов на использование шаблонов
- Подготовить к коммиту 114

## Implementation Plan

### Phase 1 — Architect
- [x] Спроектировать структуру `agent-core/`
- [x] Определить API Template Engine
- [x] Создать план, архитектуру, решения

### Phase 2 — Backend
- [x] TemplateEngine (variables, conditionals, loops)
- [x] TemplateLoader (filesystem)
- [x] TemplateRegistry (объединение)
- [x] Интеграция с Pipeline

### Phase 3 — Frontend
- [x] 8 шаблонов в формате .md
- [x] Портирование из Main
- [x] Расширение (plan, decisions, review)

### Phase 4 — QA
- [x] 13 тестов (TemplateEngine, Loader, Registry, Orchestrator)
- [x] Все проходят

### Phase 5 — Review
- [x] Финальное ревью
- [x] Проверка production readiness
