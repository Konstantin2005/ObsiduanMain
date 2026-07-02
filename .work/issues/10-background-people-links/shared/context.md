# Issue Context: #10 - Готовить связи людей в фоне и сохранять их в кэш

## Issue Metadata
- **Issue Number**: 10
- **Title**: Готовить связи людей в фоне и сохранять их в кэш
- **Priority**: p1 (High)
- **Type**: perf
- **Labels**: type:perf, area:storage, area:indexing, area:people-graph, priority:p1, scale:20k+, status:ready, area:developer
- **Author**: Konstantin2005 (kostya)
- **Created**: 2026-06-11T08:29:12Z
- **URL**: https://github.com/Konstantin2005/ObsiduanMain/issues/10

## Issue Body
```
## Development Plan

Feature:
Готовить связи людей в фоне и сохранять их в кэш.

Goal:
Вынести expensive link generation из foreground path.

Business Value:
- Быстрее открытие и обновление графа.
- Меньше лагов в UI.

Risks:
- Cache invalidation может ломать актуальность данных.
- Фоновая генерация может конфликтовать с live edits.

Dependencies:
- Background worker.
- Cache storage and invalidation policy.

Complexities:
- Нужно контролировать stale data.
- Необходимо предотвращать гонки между генерацией и чтением.
```

## Pipeline Status
- **Current Status**: CODE_REVIEWER_ACTIVE
- **Created**: 2026-06-27T14:41:00Z
- **Pipeline Steps**:
  - [x] ARCHITECT (00-architect/)
  - [x] BACKEND ENGINEER (01-backend-engineer/)
  - [x] FRONTEND ENGINEER (02-frontend-engineer/)
  - [x] QA ENGINEER (03-qa-engineer/)
  - [ ] CODE REVIEWER (04-code-reviewer/)
- **Last Updated**: 2026-06-27T14:41:00Z
- **Shared Architecture File**: Located at ./shared/architecture.md
- **Completed Backend Files**:
  - API implementation with endpoint definitions
  - PeopleLinkCache with Redis integration
  - PeopleLinkService with generation logic
  - Type definitions and performance specs
- **Completed Frontend Files**:
  - PeopleLinksPanel component with generation triggers
  - usePeopleLinks hook for API integration
  - useGenerationStatus hook for tracking
  - PeopleLinkNode and PeopleLinkEdge components
- **Completed QA Files**:
  - Test strategy and framework
  - Comprehensive test cases documentation
  - Edge case scenarios
  - Failure scenarios
  - Validation rules
- **Review Progress**: Code reviewer has reviewed architect and engineer deliverables

## Tracking Issues
- Architect: TBD
- Backend: TBD
- Frontend: TBD
- QA: TBD
- Reviewer: TBD

## Shared Files
- architecture.md: Created
- decisions-log.md: Created
