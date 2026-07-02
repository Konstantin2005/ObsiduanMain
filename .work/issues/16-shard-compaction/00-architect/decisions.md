# Architectural Decisions — Shard Compaction

## ADR-1: Compaction как отдельный модуль
**Контекст:** writeStore уже сложный. Compaction — отдельная операция.
**Решение:** `shard-compaction.js` — standalone модуль, не встроен в writeStore.
**Альтернатива:** Встроить в writeStore — отклонено (SRP, риск поломки).

## ADR-2: Не compress .bin массивы на лету
**Контекст:** TypedArray → Buffer → zlib → file. decompress → read дорого.
**Решение:** Compress только при compaction (редкая операция), keep raw для hot path.
**Portfolio:** Raw для чтения, compressed для хранения старых версий.

## ADR-3: Manifest recovery через journal replay
**Контекст:** journal.jsonl содержит историю операций.
**Решение:** recoverManifest читает journal, находит последний build-complete, восстанавливает manifest.
**Альтернатива:** Только checksum scan — slow, journal быстрее.

## ADR-4: Atomic swap через rename
**Контекст:** writeStore уже использует graph.next → rename → graph.current.
**Решение:** Compaction пишет в graph.compact → verify → rename → graph.current.
**Альтернатива:** In-place mutation — риск невосстановимой поломки.

## ADR-5: Dedup только для JSON-файлов
**Контекст:** .bin файлы — разные массивы, dedup невозможен.
**Решение:** Сравниваем strings.json, stats.json, fingerprints.json между current и previous. Если идентичны — удаляем из previous.
**Риск:** Разные ссылки — проверять по checksum.
