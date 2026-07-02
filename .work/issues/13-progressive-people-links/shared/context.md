# Issue Context: #13 - Постепенно подгружать связи в плотном графе людей

## Issue Metadata
- **Issue Number**: 13
- **Title**: Постепенно подгружать связи в плотном графе людей
- **Priority**: p1 (High)
- **Type**: perf
- **Labels**: type:perf, area:rendering, area:people-graph, area:graph-runtime, priority:p1, scale:20k+, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:29:17Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/13

## Issue Body
```
## Development Plan

Feature:
Постепенно подгружать связи в плотном графе людей.

Goal:
Перейти от eager loading к progressive loading.

Business Value:
- Быстрее initial render.
- Лучшая управляемость на очень плотных графах.

Risks:
- Пользователь может решить, что граф неполный.
- Сложно сохранить стабильный порядок отображения.

Dependencies:
- Threshold / paging policy.
- Incremental rendering strategy.

Complexities:
- Нужны хорошие loading indicators.
- Частичная загрузка усложняет navigation and search.
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
