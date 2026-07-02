# Issue Context: #11 - Перенести расчёт запросов, раскладки и связей в worker pool

## Issue Metadata
- **Issue Number**: 11
- **Title**: Перенести расчёт запросов, раскладки и связей в worker pool
- **Priority**: p1 (High)
- **Type**: perf
- **Labels**: type:perf, area:rendering, area:workers, area:graph-runtime, priority:p1, scale:20k+, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:29:13Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/11

## Issue Body
```
## Development Plan

Feature:
Перенести расчёт запросов, раскладки и связей в worker pool.

Goal:
Освободить main thread от тяжёлых вычислений.

Business Value:
- Выше responsiveness интерфейса.
- Лучше масштабируемость на большие графы.

Risks:
- Синхронизация состояния между workers и UI.
- Сложность отложенного параллельного выполнения.

Dependencies:
- Worker API.
- Queue and work item model.

Complexities:
- Serializing large graph data may be expensive.
- Нужны лимиты на параллелизм и backpressure.
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
