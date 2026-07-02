# Context: Shard Compaction & Manifest Recovery (#16)

## Source
GitHub Issue #16: Уплотнять shard-хранилище и восстанавливать manifest

## Цель
Сократить storage footprint граф-стора: merge + compress старые shards, надёжное восстановление manifest.

## Существующие файлы
- `Technical/Scripts/Obsidian/build-calendula-graph-store.js` — writeStore, loadGraphStore, manifest, journal

## Новые файлы
- `Technical/Scripts/Obsidian/shard-compaction.js` — compactStore + recoverManifest

## Статус
- [x] Architect — план, архитектура, ADR
- [x] Backend — compactStore + recoverManifest
- [x] Frontend — SAFE MODE диаграмма + 10 constraints
- [x] QA — 10 test cases + edge cases + failure scenarios
- [x] Code Review — approved

## Итог
- Новый файл: `Technical/Scripts/Obsidian/shard-compaction.js`
- All safety constraints соблюдены
- Production ready ✓
