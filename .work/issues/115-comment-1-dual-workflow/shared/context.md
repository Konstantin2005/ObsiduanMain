# Context: Dual-Workflow Architecture (#115-comment-1)

## Source
GitHub Issue #115, Comment 1: Integration of agent-core + ai-dev-orchestration-system

## Цель
Спроектировать dual-workflow архитектуру без смешивания runtime, watcher loop и мусора.

## Системы
| Система | Роль | Тип |
|---------|------|-----|
| agent-core | Runtime execution | LINE A |
| ai-dev-orchestration-system | Reference / Pattern library | LINE B |

## Статус
- [x] Architect — план, архитектура, решения
- [ ] Backend — bridge layer, mapping, configs
- [ ] Frontend — структура папок, .opencodeignore
- [ ] QA — проверка на loop, изоляция
- [ ] Code Review — финальное ревью
