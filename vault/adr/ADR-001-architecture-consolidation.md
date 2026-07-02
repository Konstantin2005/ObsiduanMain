# ADR-001: Архитектурная консолидация и Source of Truth

**Статус:** Принят  
**Дата:** 2026-06-25  
**Автор:** Architecture Board  
**Связанные задачи:** #2, #3, #4, #24, #30, #31, #98  

---

## Контекст

Репозиторий ObsiduanMain разросся без централизованной архитектуры. Анализ выявил:

1. **Множественные копии Live Graph плагина** — в `Life/Calendula/.obsidian/plugins/live-graph/`, `Life/Algoritm/.obsidian/plugins/live-graph/`, `Zetl/.obsidian/plugins/live-graph/` — каждая со своей версией `main.js` и `core.js`
2. **Дублирование генераторов графов** — 16 копий `generate_personality_map_final*.ps1`, дублирующие `generate.py` и `generate.ps1` в каждом подграфе
3. **Дублирование KnowledgeGraphs** — `KnowledgeGraphs/` и `KnowledgeGraphs_Core/` с одинаковыми генераторами
4. **Старое/ (архив)** — 21 поддиректория старых копий vault, которые больше не используются
5. **Размытый Source of Truth** — неясно, где основной код, где generated артефакты, где тестовые данные
6. **Нет единого Runtime контракта** — каждый компонент использует свои API

## Решение

### 1. Единый Source of Truth

| Категория | Source of Truth | Что делать с дубликатами |
|---|---|---|
| **Live Graph Plugin** | `Technical/Scripts/Rendering/live-graph/builtin-graph.js` | Удалить все копии из `.obsidian/plugins/live-graph/`, заменить на символические ссылки или скопировать при деплое |
| **Graph Runtime (.js)** | `Technical/Scripts/Obsidian/*.js` | Весь js-рантайм графа живёт здесь |
| **Генераторы графов (.py)** | `Zetl/generators/` унифицированные скрипты | Заменить дублирующиеся generate.py и generate.ps1 на единые entry points |
| **Генераторы графов (.ps1)** | `Technical/Scripts/Vault/` и `Technical/Scripts/Obsidian/` | 16 копий `generate_personality_map*.ps1` → один параметризованный скрипт |
| **PowerShell Automation** | `Technical/Scripts/Git/`, `Technical/Scripts/Vault/`, `Technical/Scripts/Discord/` | Удалить `vault/auto-commit.ps1`, `vault/snapshot.ps1` и др. корневые скрипты, оставить только в Technical |
| **Vault контент** | `Life/`, `Angl/`, `Zetl/`, `Technical/vault/` | Основной vault — в Life, Zetl, Angl |
| **KnowledgeGraphs** | `Zetl/KnowledgeGraphs/` | Удалить `Zetl/KnowledgeGraphs_Core/`, это устаревшая копия |
| **Архив** | `archive/` (новая директория) | Переименовать `Старое/` в `archive/` для единообразия |
| **Граф-стора (бинарный кэш)** | Игнорируется (.gitignore) | Должен пересобираться из Source of Truth |
| **Бенчмарки** | `Technical/Scripts/Obsidian/measure-*.js` | Вывод в stdout, не хранить в репозитории |

### 2. Единый Graph Runtime Contract

Все компоненты графа должны следовать единому контракту:

```
┌──────────────────────────────────────┐
│           Obsidian Plugin            │
│  (main.js — тонкий entrypoint)       │
└──────────────┬───────────────────────┘
               │ import
┌──────────────▼───────────────────────┐
│       Live Graph Core Runtime        │
│  Technical/Scripts/Rendering/        │
│  - graph-render-plan.js              │
│  - graph-scheduler.js                │
│  - graph-critical-frame.js           │
│  - graph-renderer-upgrade.js         │
│  - live-graph/builtin-graph.js       │
└──────────────┬───────────────────────┘
               │ consumes
┌──────────────▼───────────────────────┐
│       Graph Store + Query Engine     │
│  Technical/Scripts/Obsidian/         │
│  - graph-query-engine.js             │
│  - graph-index-compiler.js           │
│  - graph-build-runtime.js            │
│  - graph-worker-layer.js             │
│  - graph-governors.js                │
│  - graph-throughput-governor.js      │
│  - graph-capacity-lease-runtime.js   │
│  - graph-deep-validation.js          │
│  - graph-evidence-engine.js          │
│  - graph-multiscale.js               │
│  - graph-stability.js                │
└──────────────┬───────────────────────┘
               │ reads/writes
┌──────────────▼───────────────────────┐
│    .obsidian/graph-store/ (ignored)  │
│    Shard storage + manifest          │
└──────────────────────────────────────┘
```

**API контракт:**
- Все модули разделяют общий `GraphContext` объект (ноды, рёбра, кэш, конфиг)
- Рендеринг не парсит markdown напрямую (только через store)
- Workers изолированы через `graph-worker-layer.js`
- Governor-модули регулируют CPU/throughput через единый capacity lease интерфейс

### 3. Разделение кода и данных

```
repo-root/
├── src/                          # Исходный код (source of truth)
│   ├── graph-runtime/            # JS рантайм графа
│   ├── plugins/                  # Obsidian plugin entrypoints (только main.js)
│   ├── scripts/                  # PowerShell/Python автоматизация
│   └── generators/               # Генераторы контента (py/ps1)
├── content/                      # Пользовательский контент (markdown)
│   ├── vault-life/               # Основной vault Life
│   ├── vault-zetl/               # Zettelkasten vault
│   ├── vault-angl/               # English vault
│   └── technical/                # Technical vault
├── tests/                        # Тесты
├── docs/                         # Документация
│   ├── adr/                      # Architectural Decision Records
│   └── architecture/             # Архитектурные схемы
├── benchmarks/                   # Бенчмарк-данные (игнорируются)
├── archive/                      # Старые/неактуальные данные
└── dist/                         # Сгенерированные артефакты (игнорируются)
```

### 4. Политика управления дубликатами

1. **Live Graph плагин** — единый источник `Technical/Scripts/Rendering/live-graph/`. Копии в vault `.obsidian/plugins/live-graph/` синхронизируются при сборке.
2. **Генераторы personality_map** — 16 копий `generate_personality_map_final*.ps1` объединить в один `generate_personality_map.ps1` с параметрами `-Iteration N`.
3. **KnowledgeGraphs_Core** — удалить, т.к. это устаревшая копия `KnowledgeGraphs/`.
4. **generate.ps1 в подграфах** — заменить на единый entry point `Zetl/generate_all_graphs.py`.
5. **Корневые .ps1** — `update_developer_issue_plans.ps1`, `rebuild_mocs.py` перенести в `Technical/Scripts/`.

### 5. Риски

| Риск | Вероятность | Влияние | Митигация |
|---|---|---|---|
| Поломка Live Graph после удаления дубликатов | Средняя | Высокое | Поэтапная миграция: сначала синхронизация, потом удаление |
| Потеря данных в Старое/ | Низкая | Среднее | Перенести в archive/ без удаления контента |
| Сломанные пути в скриптах автоматизации | Высокая | Среднее | Обновить все пути в .ps1 до миграции |
| Конфликты при переименовании директорий | Средняя | Низкое | Использовать git mv для сохранения истории |

## Последствия

- **Позитивные:** единая архитектура, предсказуемые пути, уменьшение размера репозитория, упрощение CI/CD
- **Негативные:** требуется обновление путей во всех скриптах, временные неудобства при миграции
- **Нейтральные:** Старое/ → archive/ меняет только название

## Ссылки

- [ADR-002: Структура каталогов и план миграции](ADR-002-directory-structure-and-migration.md)
- [Engineering Blueprint 2026](../../docs/engineering-blueprint-2026.md)
- [Repository Policy (old)](../../Technical/Docs/GraphPlatform/repository-policy.md)
