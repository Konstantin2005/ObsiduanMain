# QA: Failure Modes & Risks

## Failure Modes
| Mode | Impact | Mitigation |
|------|--------|------------|
| Adapter fails | Issue не обработан | Retry 3x, fallback generic |
| Router misroutes | Неправильный target | Логирование, manual override |
| Validation rejects | Файл не записан | Error in log, агент уведомлён |
| GitHub API timeout | PR не создан | Retry, fallback commit only |
| Shared context corrupt | Потеря состояния | Backup global-context.json |

## Risks
| Risk | Severity | Mitigation |
|------|----------|------------|
| Single point of failure (Control Plane) | HIGH | Stateless design, StateManager persist |
| Cross-repo PR conflicts | MED | Branch naming: issue-{id}-{repo} |
| Agent execution in wrong repo | MED | Router validates target before execution |
| Central logger disk full | LOW | Rotate logs, max size per file |
| Global context stale | LOW | StateManager cache + TTL |
