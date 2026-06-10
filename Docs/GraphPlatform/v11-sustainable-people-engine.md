# Sustainable People Engine v11

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v10 became strong on correctness, but too heavy operationally.

It protects against wrong data with stable IDs, provenance, invalidation, snapshot pinning, writer protocol, and quality metrics. That is useful. But if implemented literally too early, it becomes a custom graph database, search engine, event-sourcing system, incremental compiler, and observability platform inside Obsidian.

v11 keeps the correct parts and cuts the early complexity.

```txt
Correctness, but operationally survivable.
```

Core formula:

```txt
Fast is cache.
Correct is provenance.
Reliable is identity.
Maintainable is simplicity.
```

## What v11 Fixes In v10

v10 was afraid of bad people links. Correctly.

v11 also fears operational complexity:

- too many binary stores before contracts are proven;
- delta/compaction before append-and-swap is insufficient;
- confidence floats without feedback/statistical meaning;
- local lock semantics that break under sync, sleep, crash, or restore;
- no human correction loop;
- no migration engine;
- no local/shared storage split for multi-device use;
- no load shedding when the people engine is overwhelmed.

v11 principle:

```txt
Build the smallest durable people engine that can survive years of edits,
multiple devices, sync conflicts, cache deletion, and human corrections.
```

## Active Scope

The active path is not a full knowledge-graph platform.

v11 builds:

- identity layer;
- local/shared storage split;
- human correction store;
- decision pipeline;
- simple mention store;
- cached generated edges;
- adaptive build modes;
- migration registry;
- cache delete/rebuild safety;
- renderer isolation.

v11 does not build initially:

- binary column store for all metadata;
- LSM-style delta compaction;
- advanced confidence model;
- Windows Task Scheduler installer;
- semantic model;
- full event-sourced database;
- heavy provenance optimization.

## Non-Negotiable Invariants

- Renderer never links people.
- Renderer never reads markdown.
- Renderer never reads shared correction metadata directly.
- Renderer receives only cached graph arrays and `RenderPlan`.
- User corrections outrank rules.
- Rules outrank matcher output.
- Cache is local and safely deletable.
- Shared metadata is portable and sync-safe.
- Persistent identity is UUID-based.
- Runtime rendering uses numeric local IDs.
- A bad match can be rejected and must not poison future rebuilds.
- Schema migrations are explicit.
- Large change sets trigger load shedding, not UI stalls.

## Layer 1 - Entity Identity System

Stable numeric IDs alone are not enough across devices.

Use two IDs:

```txt
entityUuid = persistent portable identity
localId = runtime numeric ID for fast arrays
```

Entity kinds:

```txt
note
person
alias
cluster
```

Identity record:

```json
{
  "entityUuid": "uuid",
  "kind": "person",
  "stablePath": "People/Alice.md",
  "localIdHint": 100,
  "version": 1,
  "status": "active"
}
```

Rules:

- UUID survives rename.
- `localId` can be rebuilt per machine.
- renderer uses `localId`;
- shared metadata uses UUID;
- duplicate local IDs on different machines are harmless;
- deleted entities become tombstones before cleanup.

This avoids the multi-device collision:

```txt
PC1: Alice.md -> localId 100
PC2: Bob.md -> localId 100
Sync: no identity conflict because UUIDs differ
```

## Layer 2 - Storage Split

Separate portable knowledge from local performance cache.

Shared metadata:

```txt
.graph-meta/
  identities/
  corrections/
  policies/
  migrations/
```

Local cache:

```txt
.graph-cache/{machineId}/
  snapshots/
  layouts/
  indexes/
  temp/
  logs/
```

Shared metadata is small, human-inspectable where possible, and sync-safe.

Local cache is disposable:

```txt
Delete graph intelligence cache
-> keep identities/corrections/policies
-> rebuild local cache
```

This prevents sync tools from mixing:

```txt
current from one device
pointer from another
indices from a third
```

## Layer 3 - Human Correction Store

The autolinker will be wrong. The system must learn from human decisions without pretending to be ML.

Correction types:

```txt
ACCEPT_LINK
REJECT_LINK
NEVER_LINK_ALIAS_HERE
ALWAYS_LINK_ALIAS_HERE
MERGE_PEOPLE
SPLIT_PERSON
RENAME_ENTITY
DISABLE_ALIAS
```

Priority order:

```txt
human decision
> policy rule
> matcher result
```

Suggested shared files:

```txt
.graph-meta/corrections/
  link-accepts.jsonl
  link-rejects.jsonl
  alias-overrides.jsonl
  entity-merges.jsonl
```

Correction record:

```json
{
  "correctionId": "uuid",
  "type": "REJECT_LINK",
  "noteUuid": "uuid",
  "personUuid": "uuid",
  "aliasUuid": "uuid",
  "scope": "note",
  "createdAt": "iso",
  "reason": "user"
}
```

Done when:

```txt
User can reject a wrong link once and the next rebuild keeps it rejected.
```

## Layer 4 - Decision Engine

Replace early fake confidence floats with explicit decisions.

Do not start with:

```txt
confidence: 0.87
```

Start with:

```txt
decision:
  EXACT_UNIQUE_ALIAS
  RULE_ACCEPTED
  USER_ACCEPTED
  CONTEXT_ACCEPTED
  REJECTED_AMBIGUOUS
  REJECTED_SHORT
  REJECTED_COMMON_WORD
  REJECTED_INSIDE_CODE
  REJECTED_INSIDE_LINK
  USER_REJECTED
```

Decision record:

```json
{
  "decision": "EXACT_UNIQUE_ALIAS",
  "noteUuid": "uuid",
  "personUuid": "uuid",
  "aliasUuid": "uuid",
  "matcherVersion": 1,
  "policyVersion": 1,
  "source": "matcher"
}
```

Confidence can be added later only when the system has:

- feedback data;
- review statistics;
- stable heuristics;
- validation samples.

## Layer 5 - Context Levels

Do not hide complexity behind one magical `ContextValidator`.

Use explicit levels:

```txt
Level 0: exact unique alias
Level 1: nearby keywords / local textual context
Level 2: same cluster/domain/context note group
Level 3: semantic model, future only
```

Initial implementation target:

```txt
Level 0 + basic Level 1 rejection
```

Examples:

- accept exact unique full-name alias;
- reject short ambiguous alias;
- reject inside code, URLs, markdown links, wikilinks;
- require context for common words and short aliases.

## Layer 6 - Simple Mention Store

Start debuggable, then optimize.

Early format:

```txt
JSONL chunks or storage abstraction
```

Later format:

```txt
binary column store
```

The contract is more important than the first physical format.

Mention record:

```json
{
  "mentionId": "uuid",
  "noteUuid": "uuid",
  "personUuid": "uuid",
  "aliasUuid": "uuid",
  "offset": 120,
  "length": 5,
  "decision": "EXACT_UNIQUE_ALIAS",
  "policyVersion": 1,
  "matcherVersion": 1
}
```

Generated edge:

```json
{
  "sourceUuid": "noteUuid",
  "targetUuid": "personUuid",
  "edgeSource": "people-autolink",
  "decision": "EXACT_UNIQUE_ALIAS",
  "mentionIds": ["uuid"]
}
```

Renderer hot path still receives compact local numeric arrays, not JSONL.

## Layer 7 - Adaptive Build System

Not every update deserves the same rebuild strategy.

Modes:

```txt
SMALL_UPDATE
BATCH_UPDATE
FULL_REBUILD_LOW_PRIORITY
DISABLE_PEOPLE_REFRESH_TEMPORARILY
```

Decision policy:

```txt
changed files < 1%
  -> targeted update

changed files 1-20%
  -> batch rebuild

changed files > 20%
  -> background full rebuild

policy or matcher changed
  -> keep old snapshot while rebuilding

cache corrupt
  -> rebuild local cache from shared metadata
```

Load shedding rules:

- never block first visual;
- never monopolize CPU while user is interacting;
- pause or slow people refresh under frame pressure;
- publish only validated snapshots;
- expose freshness state without forcing action.

## Layer 8 - Migration Engine

`schemaVersion` is not enough.

Add `MigrationRegistry`.

Migration record:

```json
{
  "from": "11.0",
  "to": "11.1",
  "action": "add-decision-field",
  "mode": "metadata-migration"
}
```

Migration modes:

```txt
metadata-migration
cache-rebuild
people-relink
full-local-rebuild
manual-review-required
```

Rules:

- shared metadata migrations must be conservative;
- local cache can be deleted and rebuilt;
- failed migration keeps previous usable state;
- migration report is written to logs.

## Layer 9 - Privacy Boundary

People graph is sensitive.

It records:

- who appears where;
- who is connected to whom;
- when diary entries mention people;
- correction history.

Policy:

```txt
local only
no external calls
easy delete
rebuild possible
shared metadata is explicit and minimal
```

Required command:

```txt
Delete graph intelligence cache
```

Optional later command:

```txt
Delete graph identities and corrections
```

That second command is destructive and must require explicit user approval.

## First Slice

`V11-S1 Sustainable People Engine`

Tasks:

```txt
1. Create EntityIdentityStore contract.
2. Add UUID + runtime numeric IDs.
3. Separate `.graph-meta` shared metadata from `.graph-cache/{machineId}` local cache.
4. Create AliasDecision pipeline with decision enums.
5. Replace early confidence floats with decisions.
6. Add human correction storage.
7. Build simple JSONL/chunk mention store.
8. Add matcher with code/link/wiki exclusion.
9. Produce generated people edges from accepted mentions.
10. Load cached graph arrays for renderer only.
```

Done:

```txt
People survive rename.
Devices do not fight over numeric IDs.
Users can correct mistakes.
Bad matches do not poison future rebuilds.
Cache can be deleted and rebuilt.
Renderer remains isolated.
```

## Implementation Phases

### Phase 0 - Operational Baseline

Tasks:

```txt
define machineId
define shared/local directories
define cache delete/rebuild behavior
define migration registry skeleton
```

Done when:

```txt
Local cache can be removed without deleting identities or corrections.
```

### Phase 1 - Identity Layer

Tasks:

```txt
EntityIdentityStore
uuid/localId mapping
person rename preservation
tombstone records
localId rebuild
```

Done when:

```txt
Renaming a person file keeps the same person UUID and creates a new local ID only if needed.
```

### Phase 2 - Decision Pipeline

Tasks:

```txt
AliasDecision enum
policy decisions
matcher decisions
user override decisions
decision audit output
```

Done when:

```txt
The system explains accept/reject without pretending to know numeric confidence.
```

### Phase 3 - Human Corrections

Tasks:

```txt
accept link
reject link
never link alias here
always link alias here
disable alias
correction priority rules
```

Done when:

```txt
Corrections survive rebuild and outrank matcher decisions.
```

### Phase 4 - Simple Mention Store

Tasks:

```txt
JSONL/chunk mention records
mentions -> generated people edges
provenance IDs
basic repair report
```

Done when:

```txt
Generated people edge can be traced to a mention and a decision.
```

### Phase 5 - Adaptive Build

Tasks:

```txt
change-size classification
SMALL_UPDATE
BATCH_UPDATE
FULL_REBUILD_LOW_PRIORITY
DISABLE_PEOPLE_REFRESH_TEMPORARILY
```

Done when:

```txt
10K changed files do not trigger a foreground freeze.
```

### Phase 6 - Renderer Integration

Tasks:

```txt
load cached graph arrays
people stale badge
snapshot swap between frames
no markdown reads
no correction reads
```

Done when:

```txt
Visual opens from cache and people refresh happens behind it.
```

### Phase 7 - Optimization Gate

Only after S1-S6 benchmarks prove a bottleneck:

```txt
binary mention columns
binary alias columns
delta compaction
advanced writer fencing
Task Scheduler prewarm
confidence model
semantic context
```

## Tests

Required tests:

- renderer does not read markdown;
- renderer does not read `.graph-meta`;
- local cache delete keeps shared identities;
- person rename preserves UUID;
- local IDs can be rebuilt;
- duplicate numeric IDs on two machines do not conflict;
- user rejection beats matcher accept;
- user accept beats ambiguous reject when scope allows it;
- short alias is rejected by decision enum;
- code/link/wiki matches are rejected;
- generated edge includes mention provenance;
- cache corrupt triggers rebuild from metadata;
- migration failure keeps previous usable state;
- large change set enters load-shedding mode;
- privacy delete removes local graph cache.

## Benchmarks

Runtime:

```txt
identityLoadMs
localIdMapMs
matcherMs
mentionsWriteMs
generatedEdgesMs
cacheOpenMs
firstVisualMs
```

Operational:

```txt
cacheDeleteRebuildMs
largeChangeClassificationMs
migrationDryRunMs
correctionApplyMs
```

Quality:

```txt
acceptedDecisions
rejectedDecisions
userOverrides
shortRejected
ambiguousRejected
topNoisyAliases
reviewSample
```

## Deferred From v10 Early Path

Postpone:

- binary alias arrays;
- binary mention arrays;
- delta compaction;
- complex CSR mutation;
- confidence floats;
- Task Scheduler;
- advanced lock leasing;
- heavy provenance optimization.

Raise priority:

- identity;
- sync safety;
- human corrections;
- migration;
- load shedding;
- cache locality;
- decision system;
- privacy boundary.

## Open Bugs To Track

```txt
V11-B001: numeric-only person IDs can conflict across devices.
V11-B002: synced local cache can mix snapshots from different machines.
V11-B003: confidence floats can create false certainty without feedback data.
V11-B004: missing human correction loop allows bad links to reappear forever.
V11-B005: missing migration registry makes schema changes unsafe.
V11-B006: no load shedding can freeze background people refresh under huge changes.
V11-B007: cache privacy boundary is unclear for sensitive people graph data.
```
