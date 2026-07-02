# Unified AI OS — Migration Plan

## Шаг 1: Создать runtime/
Создана структура control-plane, router, agents, validation.

## Шаг 2: Создать adapters/
3 адаптера: GitHub, Obsidian, Generic.

## Шаг 3: Создать shared/global-context.json
Единый JSON со всеми репозиториями и состоянием.

## Шаг 4: Подключить central-logs/
CentralLogger пишет execution-trace, agent-performance, repo-routing.

## Шаг 5: Миграция существующих систем
| Система | Статус | Действие |
|---------|--------|----------|
| agent-core | ✅ Plugin | Адаптер уже есть |
| ai-dev-orchestration-system | ✅ Plugin | Reference, read-only |
| error-telemetry | ✅ Plugin | Через адаптер |
| error-task-queue | ✅ Plugin | Через адаптер |
| agent-os | ✅ Plugin | Monorepo как plugin |

## Структура после миграции
```
C:/obsidian/
├── runtime/          ← Unified Control Plane (NEW)
├── adapters/         ← Repository Adapters (NEW)
├── shared/           ← Global Context (NEW)
├── central-logs/     ← Central Logging (NEW)
├── agent-os/         ← Plugin
├── agent-core/       ← Plugin
├── error-telemetry/  ← Plugin
├── error-task-queue/ ← Plugin
├── Main/             ← Plugin
└── ai-dev-orchestration-system/ ← Plugin (read-only)
```
