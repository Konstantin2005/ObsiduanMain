# Decisions Log

| # | Решение | Почему | Автор | Trade-off |
|---|---|---|---|---|
| 1 | CRDT вместо Event-Driven | Математическая гарантия consistency, offline-first | Architect | Сложность реализации |
| 2 | HLC вместо Lamport | Physical time context + logical ordering | Architect | Clock drift risk |
| 3 | Fractional index для позиций | O(1) insert between blocks | Architect | Precision overflow |
| 4 | LWW-Register для контента | Простота, предсказуемость | Backend | Data loss при concurrent edit |
| 5 | Tombstone deletion | CRDT requirement | Backend | Memory growth |
| 6 | Pull-based sync | Нет WebSocket (требование) | Backend | Задержка sync |
| 7 | Optimistic UI | UX важнее consistency | Frontend | Rollback complexity |
| 8 | API-level tenant isolation | Простота для mock | Backend | NOT production-safe |
