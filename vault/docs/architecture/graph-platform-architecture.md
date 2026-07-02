# Graph Platform Architecture

**Версия:** 1.0.0  
**Дата:** 2026-06-25  
**Связанные ADR:** ADR-001, ADR-002  

---

## Общая архитектура

```
┌──────────────────────────────────────────────────────────────────┐
│                    Obsidian Application                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Obsidian Plugin (Life Graph)                │   │
│  │  main.js ──► builtin-graph.js ──► ItemView (панель)      │   │
│  │  [тонкий entrypoint]     [ядро плагина]                  │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │                                           │
└─────────────────────┼───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                     Rendering Layer                              │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ RenderPlan  │  │  Scheduler   │  │ Critical Frame        │   │
│  │ (LOD,       │  │ (backpressure│  │ (first-frame loading) │   │
│  │  policy)    │  │  adaptation) │  │                      │   │
│  └──────┬──────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         └────────────────┼─────────────────────┘               │
│                          ▼                                     │
│              ┌──────────────────────┐                          │
│              │ Canvas / WebGL Gate  │                          │
│              │ (backend selection)  │                          │
│              └──────────────────────┘                          │
└──────────────────────────┬────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│                    Graph Runtime Layer                          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Query Engine │  │ Index        │  │ Build Runtime      │   │
│  │ (запросы     │  │ Compiler     │  │ (построение графа) │   │
│  │  к графу)    │  │              │  │                    │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬───────────┘   │
│         └─────────────────┼───────────────────┘               │
│                           ▼                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Worker Layer │  │ Governors    │  │ Deep Validation    │   │
│  │ (воркер пул) │  │ (CPU/through-│  │ (целостность)      │   │
│  │              │  │  put control)│  │                    │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬───────────┘   │
│         └─────────────────┼───────────────────┘               │
│                           ▼                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Stability    │  │ Capacity     │  │ Evidence Engine    │   │
│  │ (стабильность│  │ Lease Runtime│  │ (аналитика связей) │   │
│  │  рендера)    │  │ (аренда рес.)│  │                    │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │            Multi-scale Engine                             │   │
│  │  (20K→50K→100K node adaptation, LOD, clustering)          │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│                    Storage Layer                                │
│                                                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────┐    │
│  │  Graph Store (shard)  │  │  Manifest + Recovery         │    │
│  │  .obsidian/graph-store│  │  live-graph-recovery/        │    │
│  │  [бинарный кэш]       │  │  [JSON бэкапы]              │    │
│  └──────────────────────┘  └──────────────────────────────┘    │
│                                                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────┐    │
│  │  Index Cache          │  │  Layout Cache                │    │
│  │  (собранные индексы)  │  │  (раскладка графа)          │    │
│  └──────────────────────┘  └──────────────────────────────┘    │
└────────────────────────────────────────────────────────────────┘
```

## Компоненты и их responsibility

### 1. Rendering Layer (src/rendering/)

| Компонент | Файл | Ответственность |
|---|---|---|
| RenderPlan | `graph-render-plan.js` | LOD, memory pressure, query integration |
| Scheduler | `graph-scheduler.js` | Render backpressure, frame budget |
| Critical Frame | `graph-critical-frame.js` | First-frame snapshot loading |
| Renderer Upgrade | `graph-renderer-upgrade.js` | Canvas/WebGL gate |
| Live Graph Plugin | `live-graph/builtin-graph.js` | Obsidian plugin (ItemView) |

### 2. Graph Runtime Layer (src/graph-runtime/)

| Компонент | Файл | Ответственность |
|---|---|---|
| Query Engine | `graph-query-engine.js` | Запросы к графу |
| Index Compiler | `graph-index-compiler.js` | Компиляция индексов |
| Build Runtime | `graph-build-runtime.js` | Построение графа |
| Worker Layer | `graph-worker-layer.js` | Параллельные вычисления |
| Governors | `graph-governors.js` | CPU governor |
| Throughput Governor | `graph-throughput-governor.js` | Пропускная способность |
| Capacity Lease | `graph-capacity-lease-runtime.js` | Аренда ресурсов |
| Deep Validation | `graph-deep-validation.js` | Валидация целостности |
| Evidence Engine | `graph-evidence-engine.js` | Аналитика связей |
| Multi-scale | `graph-multiscale.js` | Масштабирование 20K-100K |
| Stability | `graph-stability.js` | Стабильность рендера |

### 3. Automation Layer (src/scripts/)

| Группа | Назначение |
|---|---|
| `src/scripts/git/` | Git-автоматизация (daily-push, threshold, мониторинг) |
| `src/scripts/vault/` | Операции с vault (split diary, collect mentions, helpers) |
| `src/scripts/discord/` | Discord интеграция |
| `src/scripts/launchers/` | VBS-лаунчеры для Task Scheduler |
| `src/scripts/benchmarks/` | Бенчмарк-скрипты |

### 4. Generators (src/generators/)

| Компонент | Назначение |
|---|---|
| `generate_all_graphs.py` | Единый entry point для всех генераторов графов |
| `generate_personality_map.ps1` | Параметризованный генератор personality map |
| `rebuild_mocs.py` | Перестроение MOC |
| `generate_knowledge_graph.py` | Генерация графа знаний |

## Data Flow

```
Markdown Vault ──► Index Compiler ──► Graph Store ──► Query Engine ──► Rendering
     │                    │                │               │              │
     │              [индексы]        [shard bin]     [результаты]   [frame]
     │                    │                │               │              │
     ▼                    ▼                ▼               ▼              ▼
  Content/           src/graph-       .obsidian/       src/graph-     src/rendering/
  vault-*/           runtime/         graph-store/     runtime/       */
```

## Source of Truth Map

```
Категория          │ Source of Truth         │ Формат   │ Генер.? │ Куда сохраняется
───────────────────┼─────────────────────────┼──────────┼─────────┼────────────────
Vault контент      │ content/vault-*/        │ .md      │ Нет     │ —
JS Runtime         │ src/graph-runtime/      │ .js      │ Нет     │ —
Rendering          │ src/rendering/          │ .js      │ Нет     │ —
PS Automation      │ src/scripts/            │ .ps1     │ Нет     │ —
Генераторы         │ src/generators/         │ .py/.ps1 │ Нет     │ —
Тесты              │ tests/                  │ .ps1     │ Нет     │ —
Документация       │ docs/                   │ .md      │ Нет     │ —
CI/CD              │ .github/                │ .yml     │ Нет     │ —
Graph Store        │ (runtime)               │ .bin     │ Да      │ .obsidian/graph-store/
Benchmark данные   │ (stdout)               │ .json    │ Да      │ Не сохраняется
Recovery batches   │ (runtime)               │ .json    │ Да      │ .obsidian/plugins/live-graph/
Логи               │ (runtime)               │ .log     │ Да      │ src/scripts/launchers/Logs/
```

## Принципы

1. **Единый Source of Truth** — каждый артефакт имеет ровно одно место хранения
2. **Разделение кода и данных** — исходный код в `src/`, контент в `content/`
3. **Generated артефакты не коммитятся** — все в `.gitignore`
4. **Тонкие entrypoints** — Obsidian plugin `main.js` минимален, вся логика в runtime
5. **Параметризация вместо копирования** — один скрипт с параметрами вместо 16 копий
6. **Воркеры для тяжёлых операций** — расчёт запросов, раскладки и связей через worker pool
