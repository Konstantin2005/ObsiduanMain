# PITS — Shared Context

## Статус: ✅ DONE

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| Архитектура | ✅ DONE | plan.md, architecture.md, decisions.md |
| Memory Core | ✅ DONE | database, models, storage, search |
| Ingestion Engine | ✅ DONE | loader, parser, cleaner |
| Analyzer Agent | ✅ DONE | Ollama integration, prompts, parser, validator |
| Decision Engine | ✅ DONE | router, dedup, feedback learner |
| User Model | ✅ DONE | profile, learner (self-learning thresholds) |
| Reflection Engine | ✅ DONE | daily review, weekly review |
| Nirvana Client | ✅ DONE | REST bridge to Nirvana MCP |
| API (FastAPI) | ✅ DONE | analyze, memory, suggestions, feedback, health |
| CLI | ✅ DONE | analyze, ingest, memory, tasks, suggestions |
| Human Approval | ✅ DONE | Interactive approval mode |
| Tests | ✅ DONE | 77 tests, all passing |

## Ключевые решения
- SQLite + numpy vectors (not chromadb on v1)
- Ollama for LLM (fallback LM Studio)
- 85/50 confidence thresholds (configurable)
- 3-tier routing: auto/suggest/memory
- Strict module isolation

## Найденные и исправленные баги
1. Analyzer crash on None input → fixed
2. Dedup similarity for 2-word phrases → fixed
3. Learner threshold off-by-one → fixed
