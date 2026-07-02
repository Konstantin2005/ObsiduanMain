# Issue Context: #9 - Ускорить обновление графа без полной пересборки

## Issue Metadata
- **Issue Number**: 9
- **Title**: Ускорить обновление графа без полной пересборки
- **Priority**: p1 (High)
- **Type**: perf
- **Labels**: type:perf, area:storage, area:indexing, area:graph-runtime, priority:p1, scale:20k+, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:29:09Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/9

## Issue Body
```
## Development Plan

Feature:
Ускорить обновление графа без полной пересборки.

Goal:
Перейти к incremental update вместо full rebuild.

Business Value:
- Меньше времени ожидания.
- Лучше масштабируемость на большие vault'ы.

Risks:
- Можно сломать consistency индекса.
- Incremental path сложно тестировать.

Dependencies:
- Diff model изменений.
- Update pipeline for nodes and edges.

Complexities:
- Нужно корректно учитывать rename/move/delete.
- Сложно сохранить актуальность при частичных изменениях.
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
