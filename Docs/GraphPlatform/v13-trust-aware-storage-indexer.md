# Trust-Aware Storage Indexer v13

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

Evolution note: v13 remains the warm-index and trust-model layer. It makes cached indexing safer, but it is still allowed to materialize a full snapshot from cached records. The next layer, `v14 Incremental Graph Compiler`, adds dependency tracking, operation logs, read amplification budgets, record addressing, and publish verification so the system can update graph facts rather than rebuild every derived structure.

## Main Verdict

The previous storage-indexing plan had the right direction:

```txt
Do not read 30K markdown files when only 1 file changed.
```

But it was too optimistic. It accelerated the happy path without fully protecting the correctness path.

v13 reframes the work:

```txt
Do not optimize full scan.
Build a trust-aware incremental indexer.
```

Core formula:

```txt
A fast indexer is not the one that reads faster.
A fast indexer is the one that knows which data can be trusted.
```

## Problem Statement

The current graph-store builder still behaves mostly like a full scanner:

```txt
walk markdown
-> read every file
-> stat every file
-> hash every file
-> parse links
-> resolve links
-> rebuild arrays
-> write snapshot
```

The target warm path is:

```txt
stat planner
-> classify trust
-> read only required files
-> reuse versioned note records
-> update resolver structures
-> build/publish validated snapshot
```

The hard part is not only speed. The hard part is staying correct when:

- files are renamed or moved;
- sync tools preserve or distort `mtime`;
- cache shards are partially corrupt;
- parser/resolver/schema versions change;
- duplicate basenames appear or disappear;
- Obsidian is already rendering the previous snapshot;
- external sync mutates files during a background index.

## Revised Performance Targets

Do not promise a universal `300ms` index for every machine and filesystem.

Use scenario-specific budgets:

```txt
No-change planner:
  target <= 300ms
  acceptable <= 1000ms

No-change full warm index:
  target <= 1s

1 changed note:
  target <= 500ms

100 changed notes:
  target <= 2-5s background

Renderer wait:
  always 0ms
```

Primary KPI:

```txt
first visual never waits for index
```

Secondary KPI:

```txt
trusted no-change path reads 0 markdown files
```

## Non-Negotiable Invariants

- Renderer reads only published snapshots.
- Renderer never reads note record cache.
- Renderer never reads indexer staging.
- Indexer writes only staging until validation passes.
- `path + size + mtime` is a heuristic, not a proof.
- Every note record has parser/resolver/schema version fields.
- Rename/move must preserve identity where evidence allows it.
- Resolver cache has its own invalidation model.
- Corrupt cache degrades selectively before full rebuild.
- External Node builder and plugin runtime metadata paths are separate.
- Warm cache can be disabled or deleted without corrupting the published graph.

## Layer 1 - Published Snapshot Isolation

Two worlds must stay separate:

```txt
published graph snapshot
index working cache
```

Rules:

```txt
renderer reads current snapshot only
indexer writes staging only
publish is atomic pointer swap
previous fallback remains available
staging is never read by renderer
planner never blocks first visual
```

Runtime flow:

```txt
open graph
-> load current published snapshot
-> render immediately
-> planner checks freshness in background
-> indexer writes staging
-> validate staging
-> publish between frames
```

## Layer 2 - File Manifest Planner

The planner must classify every file with a trust state.

States:

```txt
UNCHANGED_TRUSTED
UNCHANGED_SUSPECT
CHANGED_STAT
CHANGED_HASH
DELETED
ADDED
RENAMED
UNKNOWN
```

`path + size + mtime` is only `quickKey`.

Quick key can be trusted only if:

- previous manifest is valid;
- parser/resolver/schema versions match;
- no vault epoch/sync marker changed;
- mtime did not move backwards suspiciously;
- cache age is within policy;
- no external invalidation reason exists.

If trust is broken:

```txt
quickKey suspicious
-> selective hash validation
-> parse only files that remain uncertain or changed
```

## Layer 3 - Versioned Note Record Cache

Note records must be versioned. Otherwise the warm cache can become fast but false.

Record shape:

```json
{
  "recordVersion": 13,
  "parserVersion": 5,
  "resolverInputVersion": 2,
  "profilePolicyVersion": 1,
  "sourcePath": "Calendula/2026/June/01.md",
  "noteUuid": "uuid",
  "quickKey": "path:size:mtime",
  "contentHash": "sha256",
  "semanticHash": "normalized-content-hash",
  "linkScanHash": "link-relevant-content-hash",
  "outLinks": [],
  "tags": [],
  "aliases": [],
  "frontmatterKeys": [],
  "recordBuiltAt": "iso"
}
```

Invalidation:

```txt
recordVersion changed -> rebuild records
parserVersion changed -> rebuild records
resolverInputVersion changed -> rebuild resolver only if record inputs are compatible
profilePolicyVersion changed -> rebuild affected profile fields
```

## Layer 4 - Rename And Move Detection

Path-keyed records treat rename as delete plus add. That breaks layout, history, and identity.

Use identity evidence:

```txt
frontmatter noteUuid
sidecar identity map
same contentHash
same semanticHash
same basename
same previous fingerprint
same linkScanHash
```

Preferred identity:

```txt
noteUuid in frontmatter or shared sidecar identity map
```

Decision policy:

```txt
strong identity evidence -> RENAMED
weak identity evidence -> UNKNOWN + verify
conflicting identity evidence -> full affected rebuild
```

## Layer 5 - Resolver Cache

Removing markdown reads does not remove resolve cost.

The resolver can become the next bottleneck at `100K` notes or `1M+` edges.

Cache resolver structures:

```txt
pathToNodeId
basenameToNodeIds
aliasToNodeIds
linkTargetCache
unresolvedCache
duplicateBasenameIndex
```

Resolver invalidation:

```txt
content changed -> parse record + re-resolve outgoing links
path changed -> update path map + affected incoming links
basename collision changed -> affected basename targets
alias changed -> affected alias targets
parser version changed -> rebuild records
resolver version changed -> rebuild resolver only
schema changed -> migrate or rebuild
```

Do not treat resolver as a free stage.

## Layer 6 - Snapshot Builder Strategy

Early v13 is not true incremental graph mutation yet.

Phase A:

```txt
incremental parse
cached records
full array rebuild from records
```

Phase B:

```txt
edge group replacement
affected node groups
partial resolver update
```

Phase C:

```txt
delta layer
compaction
```

Be explicit:

```txt
incremental parse + full array rebuild
```

is better than full markdown scan, but it is not a fully incremental graph store.

## Layer 7 - Cache Physical Layout

Avoid one file per note on Windows.

Bad early layout:

```txt
notes/A.md.json
notes/B.md.json
...
```

Problems:

- high filesystem overhead;
- antivirus overhead;
- slow sync scans;
- poor batch IO.

Preferred early layout:

```txt
.graph-cache/{machineId}/index/
  manifest.json
  file-manifest.jsonl
  note-records/
    records-000.jsonl
    records-001.jsonl
    records-002.jsonl
  resolver/
    resolver-cache.json
  staging/
```

Later:

```txt
record table + offset index
binary column store only after bottleneck is proven
```

## Layer 8 - Hash Strategy

Do not add a separate read pass for hash.

For files that must be read:

```txt
read once
-> parse
-> compute contentHash while data is already in memory
-> compute semanticHash/linkScanHash from normalized content
```

Useful hash layers:

```txt
quickKey:
  path + size + mtime

contentHash:
  raw content hash when verification is required

semanticHash:
  normalized content excluding irrelevant volatility

linkScanHash:
  content relevant to links, aliases, and graph extraction
```

If only irrelevant metadata changed, link parsing can be skipped.

## Layer 9 - Cache Trust Model

Cache states:

```txt
fresh
stale
suspect
corrupt
incompatible
partial
```

Recovery policy:

```txt
bad manifest -> rebuild manifest
bad one record shard -> reparse affected files
bad resolver cache -> rebuild resolver from records
bad snapshot -> fallback previous snapshot
bad schema -> migrate or rebuild
```

Full rebuild is a fallback, not the first recovery action.

## Layer 10 - External Builder vs Plugin Runtime

Do not mix these two paths.

External Node builder:

```txt
own parser
own file manifest
own note record cache
own resolver cache
```

Plugin runtime:

```txt
may use Obsidian metadataCache snapshot carefully
must not trust metadataCache as persistent source of truth
must still publish validated graph snapshots
```

Shared contract:

```txt
both produce the same published graph snapshot contract
```

## First Slice

`V13-S1 Trust-Aware Warm Index`

Tasks:

```txt
1. Add timing breakdown to graph build.
2. Add machine-local cache root contract.
3. Add file manifest with trust states.
4. Add versioned note record cache.
5. Add changed-set planner.
6. Parse only files whose trust state requires reading.
7. Load cached records for unchanged trusted files.
8. Build snapshot from records.
9. Emit filesRead/filesParsed/cacheHit/cacheMiss.
10. Add corrupt cache fallback.
```

Done:

```txt
No-change path reads 0 markdown when manifest is trusted.
One changed file reads 1 markdown.
Parser version bump invalidates records.
Corrupt record shard reparses affected files.
Renderer still reads only published snapshot.
```

## What To Defer

Defer from the immediate slice:

- worker pool;
- bounded parallel parsing;
- CSR incremental mutation;
- Windows prewarm;
- advanced full validation;
- binary record store.

Raise priority:

- record versioning;
- trust states;
- rename detection;
- resolver cache;
- published/staging isolation;
- Node integration tests.

## Tests

Node tests:

```txt
manifest planner
trust state classification
record cache read/write
parser version invalidation
rename detection
resolver invalidation
corrupt shard recovery
benchmark schema
external builder does not use Obsidian metadataCache
```

Pester tests:

```txt
scripts invoke correctly
files exist
Obsidian profile stays safe
published snapshot remains valid
renderer does not read index cache
```

Required scenarios:

- no-change trusted manifest reads `0` markdown files;
- no-change suspect manifest selectively verifies;
- one changed file reads/parses `1` markdown file;
- deleted file removes node and generated edges;
- renamed file preserves identity;
- changed link updates outgoing resolve;
- duplicate basename invalidates affected targets;
- parser version bump invalidates note records;
- resolver version bump rebuilds resolver without rereading markdown;
- corrupt shard reparses affected files;
- corrupt snapshot falls back to previous.

## Benchmarks

Benchmark cases:

```txt
bench:index-cold-30k
bench:index-warm-nochange-trusted
bench:index-warm-nochange-suspect
bench:index-one-file
bench:index-100-files
bench:index-rename
bench:index-delete
bench:index-parser-version-bump
bench:index-resolver-version-bump
bench:index-corrupt-cache
```

Report schema:

```json
{
  "filesTotal": 33903,
  "filesStat": 33903,
  "filesRead": 1,
  "filesParsed": 1,
  "cacheHit": 33902,
  "cacheMiss": 1,
  "trust": {
    "UNCHANGED_TRUSTED": 33902,
    "CHANGED_STAT": 1
  },
  "timingsMs": {
    "walk": 40,
    "stat": 120,
    "planner": 20,
    "recordLoad": 50,
    "parse": 10,
    "resolve": 80,
    "arrayBuild": 100,
    "write": 100,
    "total": 520
  }
}
```

## Open Bugs To Track

```txt
V13-B001: quickKey can lie when sync tools preserve mtime.
V13-B002: path-keyed records lose identity on rename/move.
V13-B003: resolver can become the new bottleneck after markdown reads are skipped.
V13-B004: stale note records can produce fast but wrong snapshots.
V13-B005: one-file-per-note cache layout can be slow on Windows.
V13-B006: renderer/indexer isolation can break if renderer reads staging or index cache.
V13-B007: Pester-only coverage is not enough for Node indexing internals.
V13-B008: external Node builder and Obsidian metadataCache can drift if contracts are mixed.
```
