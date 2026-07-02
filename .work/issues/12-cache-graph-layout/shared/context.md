# Issue Context: #12 - Кэшировать раскладку графа для 20K-50K узлов

## Issue Metadata
- **Issue Number**: 12
- **Title**: Кэшировать раскладку графа для 20K-50K узлов
- **Priority**: p1 (High)
- **Type**: perf
- **Labels**: type:perf, area:rendering, area:storage, area:graph-runtime, priority:p1, scale:20k+, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:29:15Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/12

## Issue Body
```
## Development Plan

Feature:
Кэшировать раскладку графа для 20K-50K узлов.

Goal:
Избежать повторного дорогого layout calculation.

Business Value:
- Значительно быстрее повторные открытия и обновления.
- Стабильнее UX на больших графах.

Risks:
- Cache key может быть неточным.
- Layout reuse может визуально устаревать.

Dependencies:
- Keying strategy for cached layouts.
- Storage for layout snapshots.

Complexities:
- Нужно учитывать изменение графа без полного пересчёта.
- Большие кэши увеличивают storage cost.
```

## Pipeline Status
- **Current Status**: ARCHITECT_DONE
- **Created**: 2026-06-27T14:41:00Z
- **Pipeline Steps**:
  - [x] ARCHITECT (00-architect/)
  - [ ] BACKEND ENGINEER (01-backend-engineer/)
  - [ ] FRONTEND ENGINEER (02-frontend-engineer/)
  - [ ] QA ENGINEER (03-qa-engineer/)
  - [ ] CODE REVIEWER (04-code-reviewer/)

## Tracking Issues
- Architect: TBD
- Backend: TBD
- Frontend: TBD
- QA: TBD
- Reviewer: TBD

## Shared Files
- architecture.md: Created
- decisions-log.md: Created
