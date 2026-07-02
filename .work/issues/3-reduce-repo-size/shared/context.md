# Issue Context: #3 - Уменьшить размер репозитория и убрать сгенерированные файлы

## Issue Metadata
- **Issue Number**: 3
- **Title**: Уменьшить размер репозитория и убрать сгенерированные файлы
- **Priority**: p1 (High)
- **Type**: maintenance
- **Labels**: type:maintenance, area:storage, area:repo-health, priority:p1, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:25:25Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/3

## Issue Body
```
## Development Plan

Feature:
Уменьшить размер репозитория и убрать сгенерированные файлы.

Goal:
Оставить в репозитории только source of truth и нужные артефакты.

Business Value:
- Репо быстрее и проще в поддержке.
- Меньше шума в ревью и синхронизациях.

Risks:
- Можно удалить полезный snapshot или recovery artifact.
- Generated и source файлы могут быть смешаны.

Dependencies:
- Политика хранения артефактов.
- Инвентаризация логов, билдов и snapshots.

Complexities:
- Требует аккуратной классификации файлов.
- Нужен правила, чтобы мусор не возвращался обратно.
```

## Pipeline Status
- **Current Status**: INITIALIZED
- **Created**: 2026-06-27T14:41:00Z
- **Pipeline Steps**:
  - [ ] ARCHITECT (00-architect/)
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
- architecture.md: TBD
- decisions-log.md: TBD