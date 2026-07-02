# Context: Agent OS Monorepo (#115-comment-4)

## Source
GitHub Issue #115, Comment 7: объединить системы в единую AI Operating System

## Системы
| Система | Новая роль | Исходник |
|---------|-----------|----------|
| agent-core | agent-os/core/ | Execution engine |
| ai-dev-orchestration-system | agent-os/orchestration/ | Reference framework |
| error-telemetry | agent-os/telemetry/ | Error logging |
| error-task-queue | agent-os/task-queue/ | Error→task→execution |
| bridge layer | agent-os/bridge/ | Integration |

## Статус
- [x] Architect — plan, architecture, decisions
- [ ] Backend — monorepo structure + bridge
- [ ] Frontend — lifecycle diagram + docs
- [ ] QA — loop safety + isolation
- [ ] Code Review — финал
