# Architecture: Shard Compaction

## Текущее хранилище

```
graph-store/
├── graph.manifest.json     // центральный манифест
├── graph.lock              // блокировка записи
├── graph.journal.jsonl     // append-only журнал
├── graph.current/          // активная версия
│   ├── graph.nodes.ids.bin
│   ├── graph.nodes.type.bin
│   ├── ...
│   ├── graph.strings.json
│   ├── graph.stats.json
│   ├── graph.fingerprints.json
│   └── graph.manifest.json
└── graph.previous/         // предыдущая версия (fallback)
    └── ...
```

## Проблемы
1. **Рост объёма:** graph.previous хранит полную копию, дублирование данных
2. **Фрагментация:** journal.jsonl растёт без compact (append-only)
3. **После сбоя:** graph.current может быть невалидным, graph.previous может отсутствовать
4. **Нет GC:** старые fingerprints, stats, strings не чистятся

## Решение: Shard Compactor

```
compactStore()
│
├── 1. Анализ free space
│     └── diff fingerprints между current и previous
│
├── 2. Dedup общих строк/данных
│     └── merge strings.json → удалить одинаковые entries
│
├── 3. Compress .bin arrays (zlib deflate)
│     └── выбрать: >50% savings → compress, иначе keep raw
│
├── 4. Compact journal
│     └── оставить только build-complete записи
│
├── 5. Rebuild manifest
│     └── новые checksums + status
│
└── 6. Atomic swap
      └── write → verify → rename
```

## Manifest Recovery

```
recoverManifest()
│
├── 1. Проверить graph.current/manifest.json
│     └── если checksum ok → return
│
├── 2. Если current битый → проверить previous
│     └── если ok → activeDir = "graph.previous"
│
├── 3. Если оба битые → repair
│     └── scan shard files → rebuild checksums
│     └── create new manifest with status: "recovered"
│
└── 4. Log to journal
```

## SAFE MODE
- Никогда не удалять graph.current до успешной верификации нового
- Журналирование всех операций (можно replay)
- Atomic rename (write to temp → verify → rename)
- Compaction только когда loadStore ok (не при active failures)
