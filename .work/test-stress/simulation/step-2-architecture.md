# Step 2: Architect

## Действия
1. Проанализированы требования: sync, offline, conflict resolution, version history
2. Рассмотрены 3 архитектурные альтернативы:
   - A: Event Sourcing + CQRS (сильная консистентность, избыточно для mock)
   - B: Version Vector + Merge (детектирование конфликтов, ручной merge)
   - C: Simple Lock + Timestamp (простота, не масштабируется)
3. Выбрана: **B — Version Vector + Merge**
4. Определён data model, sync strategy (polling), conflict flow

## Ключевые решения
- Version vector для точного отслеживания изменений
- Polling-based sync (3s) вместо WebSocket
- In-memory storage (требование задачи)
- Optimistic UI + rollback

## Результат
Архитектура готова. Backend и Frontend начинают параллельную работу.
