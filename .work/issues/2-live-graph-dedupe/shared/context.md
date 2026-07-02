# Issue Context: #2 - Оставить один основной код Live Graph вместо дубликатов

## Issue Metadata
- **Issue Number**: 2
- **Title**: Оставить один основной код Live Graph вместо дубликатов
- **Priority**: p1 (High)
- **Type**: maintenance
- **Labels**: type:maintenance, area:live-graph, area:repo-health, priority:p1, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:25:23Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/2

## Issue Body
```
## Development Plan

Feature:
Оставить один основной код Live Graph вместо дубликатов.

Goal:
Определить canonical implementation и удалить расхождения между копиями.

Business Value:
- Меньше путаницы при поддержке.
- Меньше риск, что исправления попадут не в тот код.

Risks:
- Можно удалить не ту ветку логики.
- Дубликаты могут отличаться мелкими, но важными правками.

Dependencies:
- Полная инвентаризация всех копий.
- Проверка всех путей импорта и запуска.

Complexities:
- Нужно аккуратно сверить поведение перед удалением дублей.
- Обновление ссылок может затрагивать не несколько vault'ов.
```

## Pipeline Status
- **Current Status**: ARCHITECT_DONE
- **Created**: 2026-06-27T14:41:00Z
- **Updated**: 2026-06-27T14:50:00Z
- **Pipeline Steps**:
  - [x] ARCHITECT (00-architect/) ✅
  - [ ] BACKEND ENGINEER (01-backend-engineer/)
  - [ ] FRONTEND ENGINEER (02-frontend-engineer/)
  - [ ] QA ENGINEER (03-qa-engineer/)
  - [ ] CODE REVIEWER (04-code-reviewer/)

## Tracking Issues
- Architect: #201 (created)
- Backend: TBD
- Frontend: TBD
- QA: TBD
- Reviewer: TBD

## Shared Files
- architecture.md: Created
- decisions-log.md: Created