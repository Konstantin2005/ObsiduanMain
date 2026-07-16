# PITS — Decision Log

## ADR-1: SQLite
**Решение**: SQLite вместо PostgreSQL
**Reason**: Локальная система, один пользователь

## ADR-2: numpy vectors
**Решение**: Inline numpy vectors вместо chromadb
**Reason**: Ноль зависимостей на старте

## ADR-3: Ollama
**Решение**: Ollama API для LLM
**Reason**: Локальность, конфиденциальность

## ADR-4: FastAPI
**Решение**: FastAPI для REST API
**Reason**: Автовалидация, автодокументация

## ADR-5: Module isolation
**Решение**: Только Memory Core имеет доступ к БД
**Reason**: Тестируемость, отладка

## ADR-6: 85/50 thresholds
**Решение**: 85 auto, 50 suggest (configurable)
**Reason**: Баланс автоматизации и контроля

## ADR-7: Not using chromadb
**Решение**: Отложить chromadb до >1000 записей
**Reason**: YAGNI — не усложнять на старте
