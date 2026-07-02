# Context: Error → Task → Execution Pipeline (#115-comment-3)

## Source
GitHub Issue #115, Comment 5: Error → task → execution pipeline

## Цель
Любая ошибка из system автоматически превращается в подготовленную задачу для выполнения.

## Системы
| Компонент | Роль |
|-----------|------|
| Error Capture Layer | Перехват всех ошибок |
| Task Normalizer | Превращает error → structured task |
| TaskRunner | Выполняет задачу |
| TaskPicker | Выбирает следующую задачу |
| TaskStatusManager | Управляет жизненным циклом |

## Статус
- [x] Architect
- [ ] Backend — capture + normalizer + runner
- [ ] Frontend — repo structure + state machine
- [ ] QA — dedup + lifecycle
- [ ] Code Review
