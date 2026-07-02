# SAFE MODE — Shard Compaction

## Data Flow

```
compactStore(outRoot)
│
├── 1. check health ──── corrupt? → error, run recoverManifest first
│
├── 2. read current + previous files
│
├── 3. for each file in current/
│   ├── .json + identical to previous/ → skip (dedup)
│   ├── .bin > 4KB → try compress
│   │   └── saved > 50%? → write compressed .bin
│   │   └── else → copy raw
│   └── else → copy raw
│
├── 4. merge stats + fingerprints
│
├── 5. rebuild manifest with new checksums
│
├── 6. validate compact dir ✓
│
├── 7. remove previous/ (old shards)
│
├── 8. atomic rename: graph.compact → graph.current
│
└── 9. journal: compact-complete

recoverManifest(outRoot)
│
├── 1. try graph.current/manifest.json
│   └── validate checksums → ok? return
│
├── 2. try graph.previous/manifest.json
│   └── validate → ok? restore
│
└── 3. repair: scan files → rebuild checksums → rewrite manifest
```

## 10 Hard Constraints

1. **No in-place mutation** — always write to graph.compact → atomic rename
2. **No data loss** — graph.current deleted only after graph.compact validated
3. **Journal always append-first** — replay-able history
4. **Compress only .bin > 4KB** — small arrays not worth overhead
5. **JSON dedup only by exact match** — no semantic diff
6. **Compaction aborted → graph.compact deleted** — no partial state
7. **recoverManifest never mutates data files** — only rewrites manifest.json
8. **loadStore still works during compaction** — graph.current untouched until rename
9. **Dry run mode** — simulate without writes
10. **Journal write failures are non-fatal** — compaction still succeeds
