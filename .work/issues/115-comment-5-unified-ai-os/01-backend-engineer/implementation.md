# Implementation — Unified AI OS

## Created

### runtime/control-plane/
| File | Description |
|------|-------------|
| orchestrator.js | UnifiedOrchestrator — единый для всех репо |
| state-manager.js | StateManager — глобальное состояние |
| scheduler.js | Scheduler — приоритетная очередь |
| central-logger.js | CentralLogger — централизованные логи |

### runtime/router/
| File | Description |
|------|-------------|
| multi-repo-router.js | Определяет source → target repo |

### runtime/agents/
| File | Description |
|------|-------------|
| unified-agent.js | UnifiedAgent — base class, не привязан к репо |

### runtime/validation/
| File | Description |
|------|-------------|
| zero-trust.js | Валидация расширений, паттернов, размера |

### runtime/index.js
Entry point — createDefaultOrchestrator()

### adapters/
| File | Description |
|------|-------------|
| github-repo-adapter.js | Для GitHub репозиториев |
| obsidian-repo-adapter.js | Для Obsidian/Main |
| generic-repo-adapter.js | Fallback |

### shared/
| File | Description |
|------|-------------|
| global-context.json | Единый state всех репо |
