# Plan: Shard Compaction & Manifest Recovery (#16)

## Goal
Сократить storage footprint граф-стора: merge + compress старые shards, надёжное восстановление manifest после partial failures.

## Phase 1 — Architect
- [x] Анализ хранилища: graph.current, graph.previous, manifest, checksums, journal
- [x] API контракт compaction + recovery

## Phase 2 — Backend
- [ ] `shard-compaction.js` — merge + compress old shards
- [ ] `shard-manifest-recovery.js` — восстановление manifest после сбоев
- [ ] Интеграция с writeStore

## Phase 3 — Frontend
- [ ] Data flow diagram
- [ ] Safety constraints

## Phase 4 — QA
- [ ] Test cases: compaction, recovery, interruption

## Phase 5 — Code Review
- [ ] Security, atomicity, rollback

## API контракт

```js
compactStore(outRoot, options)
  → { ok, freedBytes, compactedFiles, errors }

recoverManifest(outRoot, journalPath)
  → { ok, manifest, recoveredFrom, repairs }

CompactResult {
  ok: boolean
  freedBytes: number       // сколько байт освобождено
  compactedFiles: string[] // какие файлы сжаты/мержены
  errors: string[]         // ошибки без прерывания
}
```
