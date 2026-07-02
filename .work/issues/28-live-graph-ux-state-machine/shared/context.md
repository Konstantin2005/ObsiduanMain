# Issue Context

## Issue #28: Live Graph UX State Machine

- **Title:** Live Graph UX State Machine
- **URL:** https://github.com/Konstantin2005/ObsiduanMain/issues/28
- **Author:** Konstantin2005
- **Created:** 2026-06-11T11:00:15Z
- **Labels:** (none)
- **Assignees:** (none)

## Description
Формализовать состояния панели «Жизнь» и их переходы.
Сделать UI понятным, управляемым и безопасным.

### Business Value
- Пользователь видит, что система делает.
- Меньше ошибок при остановке, восстановлении и preview.

### Risks
- Неправильные state transitions.
- Путаница между UI state и runtime state.

### Dependencies
- Runtime action model.
- UI state mapping.

### Complexities
- Нужна синхронизация между действиями пользователя и фоновыми процессами.
- Ошибки state machine часто проявляются только на длинных сценариях.

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
