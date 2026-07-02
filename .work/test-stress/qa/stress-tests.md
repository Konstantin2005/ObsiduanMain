# Stress Tests (5)

## S-01: Conflict Avalanche
10 пользователей одновременно редактируют одну задачу
- Ожидание: 1 успех, 9 конфликтов 409
- Все 9 получают корректную conflict info
- 9 merge запросов → последовательное разрешение

## S-02: Offline Flood
20 изменений в offline режиме → sync
- Ожидание: queue сохраняется
- Sync push: 20 actions
- Если конфликты → 20 ConflictResolver диалогов (или batch resolve)

## S-03: Network Flip-Flop
Сеть отключается/включается каждые 2 секунды
- Ожидание: система стабильно переключается online/offline
- Нет duplicate actions
- Нет потери данных

## S-04: Bulk Create
1000 задач через bulk endpoint
- Ожидание: in-memory выдерживает
- Sync после bulk: корректный timestamp
- Dashboard с virtual scroll

## S-05: Zero Network + Full Flush
Полное отсутствие сети → 50 offline изменений
- Ожидание: все 50 сохраняются
- При восстановлении: flush по 10 actions/batch
- Конфликты обрабатываются sequentially
