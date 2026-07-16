# PITS Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PERSONAL INTELLIGENCE                    │
│                       TASK SYSTEM                           │
│                                                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐│
│  │Ingestion │──▶│ Analyzer │──▶│Decision  │──▶│ Nirvana  ││
│  │ Engine   │   │ Agent    │   │ Engine   │   │ Bridge   ││
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘│
│        │              │              │                      │
│        ▼              ▼              ▼                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    MEMORY CORE                       │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │   │
│  │  │ SQLite   │  │ Vector   │  │   Relationships  │   │   │
│  │  │ Storage  │  │ Storage  │  │   Graph          │   │   │
│  │  └──────────┘  └──────────┘  └──────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────────┐           │
│  │  User    │   │Reflection│   │ Human        │           │
│  │  Model   │   │ Engine   │   │ Approval     │           │
│  └──────────┘   └──────────┘   └──────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Модули

### 1. Memory Core (`memory/`)
- **database.py** — SQLite connection, schema, migrations
- **models.py** — Pydantic models: Entry, Memory, Task, Suggestion
- **storage.py** — CRUD операции
- **search.py** — Semantic search через numpy cosine similarity

### 2. Ingestion Engine (`ingestion/`)
- **loader.py** — Чтение файлов (txt, md)
- **parser.py** — Разделение на записи, метаданные
- **cleaner.py** — Очистка: удаление шума, нормализация

### 3. Analyzer Agent (`analyzer/`)
- **agent.py** — Промпт + вызов Ollama
- **prompts.py** — Системные промпты
- **parser.py** — Извлечение JSON из ответа модели
- **validator.py** — Проверка структуры ответа

### 4. Decision Engine (`decision_engine/`)
- **router.py** — Маршрутизация по confidence
- **dedup.py** — Проверка дубликатов
- **feedback.py** — Обработка ответов пользователя

### 5. User Model (`user_model/`)
- **profile.py** — Профиль пользователя
- **learner.py** — Обучение на feedback
- **patterns.py** — Поиск паттернов

### 6. Reflection Engine (`reflection/`)
- **daily.py** — Ежедневный обзор
- **weekly.py** — Еженедельный обзор
- **report.py** — Генерация отчёта

### 7. Nirvana Client (`nirvana_client/`)
- **bridge.py** — Интерфейс к Nirvana Bridge MCP
- **mapper.py** — Маппинг PITS task → Nirvana task

### 8. API (`api/`)
- **main.py** — FastAPI приложение
- **routes.py** — Endpoints
- **schemas.py** — Pydantic схемы запросов/ответов

## Data Flow (полный цикл)

```
File/Input → loader → parser → cleaner → Memory Core
                                           ↓
Memory Core → Analyzer Agent → JSON items → Decision Engine
                                             ↓
                          ┌──────────────────┼──────────────────┐
                          ▼                  ▼                  ▼
                   confidence≥85     50≤confidence<85    confidence<50
                          │                  │                  │
                          ▼                  ▼                  ▼
                   Nirvana Bridge    Human Approval       Memory Only
                          │                  │
                          ▼                  ▼
                    Task Created      Feedback → User Model
```

## База данных

### SQLite Schema

```sql
-- entries: сырые записи
CREATE TABLE entries (
    id INTEGER PRIMARY KEY,
    source TEXT,
    raw_text TEXT,
    cleaned_text TEXT,
    created_at TIMESTAMP,
    source_file TEXT
);

-- memories: извлечённые факты/память
CREATE TABLE memories (
    id INTEGER PRIMARY KEY,
    entry_id INTEGER REFERENCES entries(id),
    content TEXT,
    embedding BLOB,       -- numpy float32 array
    memory_type TEXT,      -- fact/goal/problem/idea/promise
    confidence REAL,
    created_at TIMESTAMP
);

-- tasks: найденные задачи
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    memory_id INTEGER REFERENCES memories(id),
    title TEXT,
    description TEXT,
    confidence REAL,
    status TEXT,           -- suggested/approved/rejected/created
    source_entry_id INTEGER REFERENCES entries(id),
    created_at TIMESTAMP
);

-- relationships: связи между записями
CREATE TABLE relationships (
    id INTEGER PRIMARY KEY,
    source_memory_id INTEGER REFERENCES memories(id),
    target_memory_id INTEGER REFERENCES memories(id),
    relation_type TEXT,    -- repeats/continues/contradicts/related
    strength REAL
);

-- feedback: обратная связь
CREATE TABLE feedback (
    id INTEGER PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id),
    decision TEXT,          -- accepted/rejected
    reason TEXT,
    created_at TIMESTAMP
);
```

## API Contract

### POST /analyze
```json
// Request
{"text": "дневниковая запись..."}

// Response
{
  "items": [{
    "type": "task|idea|goal|problem|promise",
    "title": "Название",
    "confidence": 85,
    "reason": "Обоснование",
    "recommended_action": "что сделать"
  }]
}
```

### GET /memory
```json
// Response
{
  "entries": [...],
  "total": 42
}
```

### GET /suggestions
```json
// Response
{
  "suggestions": [{
    "id": 1,
    "type": "task",
    "title": "...",
    "confidence": 65,
    "status": "pending"
  }]
}
```

## Хранилище векторов (inline)

На старте используем numpy + cosine similarity в памяти.
При 1000+ записей — перейти на chromadb или faiss.
