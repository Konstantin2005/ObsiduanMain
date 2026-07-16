# PITS — Personal Intelligence Task System

## План реализации

### Цель
Локальная AI-система, которая анализирует дневники и заметки пользователя, находит скрытые задачи и намерения, управляет персональной памятью и создаёт задачи через Nirvana Bridge.

### Этапы реализации

| Этап | Модуль | Описание | Зависимости |
|------|--------|----------|-------------|
| 1 | Архитектура | plan.md, architecture.md, decisions.md | — |
| 2 | Memory Core | SQLite + Vector storage: database, models, storage, search | — |
| 3 | Ingestion Engine | Загрузка .txt/.md, парсинг, очистка, индексация | Memory Core |
| 4 | Analyzer Agent | AI-агент на Ollama: анализ текста, извлечение задач | Ingestion Engine |
| 5 | Decision Engine | Фильтр confidence: авто/предложение/память | Analyzer |
| 6 | API (FastAPI) | POST /analyze, GET /memory, GET /suggestions | Decision Engine |
| 7 | Nirvana Integration | Подключение через Nirvana Bridge MCP | Decision Engine |
| 8 | Reflection Engine | Daily/Weekly review | Memory Core |
| 9 | User Model | Профиль пользователя, обучение | Memory Core |
| 10 | Тестирование | pytest, тестовый сценарий | Все модули |

### Технологический стек
- **Язык**: Python 3.11+
- **БД**: SQLite + numpy-вектора (inline, без внешней vector DB на старте)
- **AI**: Ollama API (локально), fallback: LM Studio
- **API**: FastAPI + uvicorn
- **Тесты**: pytest
- **Конфиг**: YAML

### Правила
1. Каждый модуль строго изолирован.
2. Только Memory Core имеет доступ к БД.
3. Analyzer не пишет в БД — только возвращает JSON.
4. Decision Engine — единственный, кто может инициировать создание задачи.
5. Никакой модуль не обращается к Nirvana напрямую.
