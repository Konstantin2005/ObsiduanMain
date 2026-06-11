# Incremental Graph Compiler v14

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v13 is a good warm indexer.

It understands trust states, versioned records, rename safety, resolver cache invalidation, published/staging isolation, and cache recovery.

But v13 still thinks too much like a batch builder:

```txt
incremental parse
+ cached records
+ full graph materialization
```

That is a major improvement over reading every markdown file, but it can still become the next bottleneck at `100K` notes and `1M+` edges.

v14 reframes the system:

```txt
Do not build a faster builder.
Build a graph compiler with dependency tracking.
```

Core formula:

```txt
Do not only ask:
  which files changed?

Ask:
  which graph facts depend on these changes?
```

## Problem Statement

The dangerous hidden phrase is:

```txt
build snapshot from records
```

At scale, that can become:

```txt
read every cached record
resolve every link
write every array
```

This is better than:

```txt
read every markdown file
```

But it is still not a true incremental graph compiler.

v14 splits the journey honestly:

```txt
v13-A: incremental parse cache
v13-B/v14-A: incremental resolver
v14-B: incremental materialized graph
v14-C: delta graph snapshot
```

## Non-Negotiable Invariants

- Renderer reads only published snapshots.
- Indexer writes only staging.
- Every index run has an operation log.
- Every trust state has reason codes and chosen action.
- Read amplification is measured and budgeted.
- Record shards have address tables and shard manifests.
- Corrupt shards identify affected records without scanning every shard.
- Resolver invalidation is dependency-based.
- Snapshot manifests record source/indexer/parser/resolver/build IDs.
- Publish verifies the source manifest did not drift too far during build.
- Warm cache can be disabled safely for a run.
- External builder and plugin builder must have parity tests before sharing output contracts.

## Layer 1 - Operation Log

Benchmarks show the result. Operation logs explain why the result happened.

Every run writes:

```txt
runId
mode
startedAt
finishedAt
planner decision
trust states
trust reasons
files statted
files read
records reused
records rebuilt
resolver invalidations
snapshot decision
fallbacks
incidents
```

Event codes:

```txt
INDEX_RUN_STARTED
MANIFEST_LOADED
TRUST_CLASSIFIED
RECORD_SHARD_CORRUPT
FILES_PARSED
RESOLVER_INVALIDATED
SNAPSHOT_STAGING_WRITTEN
SNAPSHOT_PUBLISHED
SNAPSHOT_REJECTED
FALLBACK_FULL_SCAN
WARM_CACHE_DISABLED
```

This answers:

```txt
Why did a warm path become full rebuild?
Why was the cache not trusted?
Which resolver keys were invalidated?
Why was staging rejected?
```

## Layer 2 - Trust Reasons And Actions

Trust state alone is not enough.

Planner result:

```json
{
  "path": "Calendula/2026/June/01.md",
  "state": "UNCHANGED_SUSPECT",
  "reasons": [
    "MTIME_BACKWARDS",
    "CACHE_TOO_OLD"
  ],
  "action": "HASH_VERIFY"
}
```

Reason codes:

```txt
QUICK_KEY_MATCH
QUICK_KEY_CHANGED
MTIME_BACKWARDS
MTIME_RESOLUTION_RISK
CACHE_TOO_OLD
VAULT_EPOCH_CHANGED
SYNC_STORM_DETECTED
PARSER_VERSION_CHANGED
RESOLVER_VERSION_CHANGED
SCHEMA_VERSION_CHANGED
RECORD_SHARD_MISSING
RECORD_SHARD_CORRUPT
SOURCE_DELETED
SOURCE_ADDED
RENAME_CANDIDATE
```

Actions:

```txt
REUSE_RECORD
HASH_VERIFY
READ_AND_PARSE
REPARSE_AFFECTED
REBUILD_RESOLVER
FALLBACK_FULL_SCAN
DISABLE_WARM_CACHE_FOR_RUN
```

## Layer 3 - Read Amplification Budgets

Do not only budget markdown reads.

Budget all IO:

```txt
filesStatBudget
markdownReadBudget
recordShardReadBudget
overlayReadBudget
resolverReadBudget
snapshotWriteBudget
resolverRecomputeBudget
```

Example budgets:

```txt
no-change trusted:
  markdownRead = 0
  recordShardsRead <= 2
  resolverRecompute = 0

one changed file:
  markdownRead = 1
  recordOverlayAppend = 1
  affectedTargetKeys <= bounded

sync storm:
  stop interactive indexing
  switch BACKGROUND_HEAVY or FULL_REBUILD
```

Report metrics:

```json
{
  "readAmplification": {
    "filesStat": 33903,
    "markdownRead": 1,
    "recordShardsRead": 2,
    "overlayRecordsRead": 10,
    "resolverKeysRecomputed": 4,
    "snapshotBytesWritten": 12000000
  }
}
```

## Layer 4 - Record Store v2

JSONL shards are fine early, but one changed record must not require rewriting a huge shard.

Use:

```txt
records-base/
  records-000.jsonl
  records-001.jsonl

records-overlay/
  overlay-000.jsonl

record-address-table.json
shard-manifest.json
```

Record address table:

```json
{
  "byNoteUuid": {
    "note-uuid": {
      "shardId": "records-000",
      "offset": 12345,
      "length": 456,
      "recordVersion": 13
    }
  },
  "byPath": {
    "Calendula/A.md": "note-uuid"
  }
}
```

Shard manifest:

```json
{
  "shardId": "records-000",
  "recordCount": 1000,
  "noteUuids": ["uuid"],
  "paths": ["Calendula/A.md"],
  "checksum": "sha256"
}
```

If a shard is corrupt:

```txt
use shard manifest
-> identify affected paths
-> reparse affected files
```

Do not scan all shards to recover from one bad shard.

## Layer 5 - Overlay And Compaction

Do not build an LSM database early.

Use a simple overlay:

```txt
base record shards
+ overlay journal
+ manifest points to latest record version
```

Compaction trigger:

```txt
overlay records > threshold
overlay bytes > threshold
lookup slowdown > threshold
manual maintenance
```

Rules:

- append changed records to overlay;
- address table points to newest record;
- compaction rewrites base shards in background;
- failed compaction never corrupts current records.

## Layer 6 - Dependency Index

Resolver cache needs dependency tracking, not only maps.

Indexes:

```txt
targetKey -> sourceNoteIds
basename -> sourceNoteIds
alias -> sourceNoteIds
path -> sourceNoteIds
recordId -> outgoingTargetKeys
targetKey -> resolverInputs
```

Example:

```txt
link target "John"
depends on:
  basename index for John
  aliases matching John
  path map
  duplicate basename policy
```

If a second `John.md` appears:

```txt
invalidate targetKey:John
find sourceNoteIds depending on John
re-resolve only affected outgoing links
```

Without this, resolver cache becomes either stale or full rebuild.

## Layer 7 - Resolver Compiler

Resolver should compile affected links.

Inputs:

```txt
changed records
invalidated target keys
affected source records
dependency index
resolver policy version
```

Output:

```txt
updated edge groups
updated unresolved groups
updated dependency index entries
resolver incident report
```

Compiler flow:

```txt
changed records
+ invalidated target keys
+ affected source records
-> resolve only affected outgoing target keys
-> write updated edge groups
```

## Layer 8 - Rename Detection Trust Hierarchy

Rename detection needs explicit trust levels.

Levels:

```txt
Level 1: explicit noteUuid exact match
Level 2: sidecar UUID exact match
Level 3: contentHash exact match
Level 4: semanticHash + size + old path proximity
Level 5: basename heuristic
```

Strict rule:

```txt
basename alone cannot preserve identity
```

Conflict policy:

```txt
multiple candidates at same strong level -> UNKNOWN + manual/repair path
weak evidence only -> UNKNOWN
conflicting UUIDs -> reject rename and record incident
```

## Layer 9 - Snapshot Compatibility Contract

Published snapshot manifest must record build lineage.

Fields:

```txt
snapshotSchemaVersion
indexerVersion
parserVersion
resolverVersion
arrayVersion
sourceManifestId
recordSetId
resolverCacheId
dependencyIndexId
operationRunId
buildMode
materializationMode
```

This prevents renderer or tools from trusting a formally current snapshot built with incompatible parser/resolver logic.

## Layer 10 - Partial Success Policy

A large index run may partially fail.

Scenarios:

```txt
999 files updated successfully
1 file failed parse
```

Modes:

```txt
STRICT
BEST_EFFORT
SAFE_STALE
```

Policy:

```txt
STRICT:
  reject staging on any parse failure

BEST_EFFORT:
  publish with warnings only if failed records are non-critical

SAFE_STALE:
  keep old valid record for failed file
  publish if graph remains valid
```

Default for graph:

```txt
safe-stale is better than broken snapshot
```

Every partial success must be visible in operation log and manifest warnings.

## Layer 11 - Publish Protocol

Before publish:

```txt
validate staging
verify source manifest did not drift too far
verify build IDs
verify snapshot compatibility fields
write manifest
atomic pointer swap
```

Sync storm protection:

```txt
pre-build source manifest epoch
post-build source manifest verification
if changed too much during build:
  mark snapshot stale-on-publish
  or rerun planner
  or reject staging depending on mode
```

## Layer 12 - Indexing Modes

Modes:

```txt
INTERACTIVE_LIGHT
BACKGROUND_NORMAL
BACKGROUND_HEAVY
VALIDATION_ONLY
REPAIR
FULL_REBUILD
```

Each mode has budgets:

```txt
maxMarkdownReads
maxRecordShardReads
maxResolverInvalidations
maxSnapshotWriteBytes
maxCpuMsPerChunk
canPublishPartial
```

## Layer 13 - Downgrade Path

If warm cache becomes risky:

```txt
disable warm cache for this run
fall back to full scan
record incident
do not poison cache
```

Command:

```txt
Disable warm index cache temporarily
```

This is not failure. It is controlled degradation.

## Layer 14 - External/Plugin Parity Tests

External Node builder and plugin runtime must prove they produce equivalent graph facts.

Parity test:

```txt
same temp vault
external builder snapshot hash
plugin builder snapshot hash
compare normalized graph output
compare unresolved output
compare dependency index output
```

Without parity tests, the two paths will drift silently.

## First Slice

`V14-S1 Warm Index With Explainable Trust`

Tasks:

```txt
1. Add operation log.
2. Add trust reason codes.
3. Add versioned note records.
4. Add record address table.
5. Add shard manifest with checksums.
6. Add changed-set planner.
7. Reuse unchanged records.
8. Build snapshot from records.
9. Emit read amplification metrics.
10. Add post-build manifest verification.
```

Done:

```txt
No-change trusted reads 0 markdown.
One changed file reads 1 markdown.
Trust decisions are explainable.
Corrupt shard identifies affected files.
Warm cache can be disabled safely.
Snapshot manifest records source ids and versions.
```

## Implementation Progress

### V14-S1A - Explainable Trust Planner Foundation

Status: `DONE`

Completed:

```txt
IndexOperationLog/v14.0
IndexOperationEvent/v14.0
IndexTrustDecision/v14.0
IndexChangedSetPlan/v14.0
IndexReadAmplification/v14.0
IndexSnapshotCompatibility/v14.0
trust state classification
trust reason/action codes
warm-cache-disable action
parser/resolver/schema version invalidation
corrupt shard action routing
deleted file resolver invalidation without markdown read
read amplification tracker
snapshot compatibility lineage contract
synthetic index compiler benchmark
```

Measured:

```txt
50K synthetic files
100 changed
10 added
10 deleted
5 corrupt shards
changed-set planning: 299.181ms
total synthetic benchmark: 317.102ms
markdownRead: 115
resolverKeysRecomputed: 15
operation events: 50,011
unchanged trusted records: 49,885
```

Verified:

```txt
Pester: 45 passed, 0 failed
```

Remaining in `V14-S1`:

```txt
record address table
shard manifest checksums
overlay journal
post-build source manifest verification
operation log persistence
external/plugin parity fixture
resolver dependency index
```

## What To Defer

Do not do first:

- resolver cache full complexity;
- binary record store;
- worker pool;
- CSR incremental mutation;
- advanced rename heuristics;
- semantic hash overengineering.

Raise priority:

- operation log;
- trust reason codes;
- record address table;
- shard manifests;
- post-build verification;
- read amplification budgets;
- external/plugin parity tests.

## Tests

Required tests:

- operation log records planner decisions;
- trust state includes reason codes and action;
- no-change trusted path reads `0` markdown;
- one changed file reads `1` markdown;
- record address table resolves record location without shard scan;
- corrupt shard manifest identifies affected paths;
- basename-only rename does not preserve identity;
- explicit UUID rename preserves identity;
- sync storm between pre/post manifests blocks or marks stale publish;
- warm cache can be disabled for one run;
- partial parse failure uses safe-stale policy;
- snapshot manifest records parser/resolver/source IDs;
- external/plugin parity test compares normalized output.

## Benchmarks

Benchmark cases:

```txt
bench:v14-nochange-operation-log
bench:v14-one-file-address-lookup
bench:v14-corrupt-shard-recovery
bench:v14-resolver-targetkey-invalidation
bench:v14-sync-storm-reject
bench:v14-safe-stale-partial-success
bench:v14-read-amplification
```

Report schema:

```json
{
  "runId": "uuid",
  "mode": "BACKGROUND_NORMAL",
  "operationEvents": 12,
  "trust": {
    "UNCHANGED_TRUSTED": 33902,
    "CHANGED_STAT": 1
  },
  "trustReasons": {
    "QUICK_KEY_MATCH": 33902,
    "QUICK_KEY_CHANGED": 1
  },
  "readAmplification": {
    "filesStat": 33903,
    "markdownRead": 1,
    "recordShardsRead": 2,
    "overlayRecordsRead": 1,
    "resolverKeysRecomputed": 4,
    "snapshotBytesWritten": 12000000
  },
  "publish": {
    "decision": "PUBLISHED",
    "sourceManifestDrift": "none",
    "materializationMode": "FULL_FROM_RECORDS"
  }
}
```

## Open Bugs To Track

```txt
V14-B001: full snapshot materialization from cached records can become the new full scan.
V14-B002: resolver cache without dependency index becomes stale or forces full rebuild.
V14-B003: basename-only rename detection can create false identity merges.
V14-B004: missing operation log makes warm/full rebuild decisions unexplained.
V14-B005: no read amplification budget can hide large JSONL/resolver IO.
V14-B006: corrupt shard recovery is impossible without shard manifest/address table.
V14-B007: snapshot can be stale before publish during sync storm.
V14-B008: external builder and plugin runtime can drift without parity tests.
```
