# PITS Architecture (Final)

## Системная архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    PERSONAL INTELLIGENCE                    │
│                       TASK SYSTEM                           │
│                                                             │
│  CLI/API ──▶ Ingestion ──▶ Analyzer ──▶ Decision ──▶ Nirvana│
│                  │            │             │               │
│                  ▼            ▼             ▼               │
│              ┌─────────────────────────────────────┐        │
│              │           MEMORY CORE              │        │
│              │  SQLite + numpy vector storage     │        │
│              └─────────────────────────────────────┘        │
│                                                             │
│  User Model ───▶ Reflection Engine ───▶ Human Approval     │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack
- Python 3.11+
- SQLite (structured data)
- numpy (vector similarity)
- FastAPI + uvicorn (API)
- Ollama (local LLM)
- pytest (tests)

## Data Flow
1. **Input**: Diary entries (manual, file, API)
2. **Ingestion**: Load → Parse → Clean → Store in Memory Core
3. **Analysis**: Memory → Analyzer Agent (Ollama) → JSON items
4. **Decision**: Items → Confidence check → Auto/Suggest/Memory
5. **Action**: Auto tasks → Nirvana Bridge; Suggest → Human Approval
6. **Learning**: Feedback → User Model → Threshold adjustment
7. **Reflection**: Daily/Weekly automatic reports

## Confidence Routing
- ≥85: automatic → Nirvana Bridge
- 50-85: suggested → Human Approval
- <50: memory only

## Модули (17 пакетов, ~1600 LOC)
Все модули в `personal_ai_system/` — готовы к запуску.
