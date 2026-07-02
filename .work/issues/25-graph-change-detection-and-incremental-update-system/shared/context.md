# Issue Context

## Issue #25: Graph Change Detection and Incremental Update System

- **Title:** Graph Change Detection and Incremental Update System
- **URL:** https://github.com/Konstantin2005/ObsiduanMain/issues/25
- **Author:** Konstantin2005
- **Created:** 2026-06-11T11:00:10Z
- **Labels:** (none)
- **Assignees:** (none)

## Description
Построить систему изменения графа по diff вместо полной пересборки.
Обновлять граф только по реально изменившимся данным.

### Business Value
- Значительно быстрее обновления.
- Меньше лишней работы для storage и render layers.

### Risks
- Consistency bugs after partial updates.
- Сложно корректно обработать rename, move и delete.

### Dependencies
- Change detection layer.
- Incremental pipeline for nodes, edges and layout.

### Complexities
- Нужно безопасно обновлять индекс и manifest по частям.
- Incremental path намного труднее тестировать.

## Pipeline Status

| Step | Status | Timestamp |
|------|--------|-----------|
| INITIALIZED | DONE | 2026-06-27 |
| ARCHITECT | DONE | 2026-06-27 |
| BACKEND | PENDING | - |
| FRONTEND | PENDING | - |
| QA | PENDING | - |
| REVIEWER | PENDING | - |

## Tracking Issues

- Architect: -
- Backend: -
- Frontend: -
- QA: -
- Reviewer: -
