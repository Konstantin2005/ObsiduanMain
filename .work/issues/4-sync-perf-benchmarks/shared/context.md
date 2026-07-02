# Issue Context: #4 - Синхронизировать настройки производительности и бенчмарков

## Issue Metadata
- **Issue Number**: 4
- **Title**: Синхронизировать настройки производительности и бенчмарков
- **Priority**: p1 (High)
- **Type**: maintenance
- **Labels**: type:maintenance, area:benchmark, area:graph-runtime, priority:p1, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:25:27Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/4

## Issue Body
```
## Development Plan

Feature:
Синхронизировать настройки производительности и бенчмарков.

Goal:
Привести perf config, benchmark config и runtime behavior к одному контракту.

Business Value:
- Бенчмарки становятся сравнимыми.
- Проще принимать решения по оптимизациям.

Risks:
- Исторические настройки могут использоваться неявно.
- Неверная синхронизация исказит benchmarks.

Dependencies:
- Полный список perf toggles.
- Текущие benchmark сценарии.

Complexities:
- Разные vault'ы могут расходиться в конфигурации.
- Нужна проверка, что старые результаты остаются интерпретируемыми.
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