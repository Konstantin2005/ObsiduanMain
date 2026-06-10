# People Linking Data Pipeline v10

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

The previous direction was right but incomplete.

Moving people linking out of the critical render path fixes waiting. It does not automatically fix correctness, alias invalidation, false positives, graph-store consistency, or live concurrency.

```txt
Do not build a faster people-linking side effect.
Build a versioned, incremental, explainable people-linking data pipeline.
```

Core formula:

```txt
Renderer never links people.
Obsidian never waits for people linking.
People linking is versioned, explainable, incremental, reversible, and confidence-aware.
```

The standard is intentionally strict:

```txt
A fast wrong people edge is worse than a slow correct people edge.
```

Slow correct work can be cached. A noisy people graph poisons rendering, search, clusters, analytics, and user trust.

## Problem Statement

The large-vault pain is not just that people attach slowly.

The real problem is that people linking is currently treated like a graph-build helper:

```txt
scan changed notes
-> find people
-> write edges
-> swap snapshot
```

That is too naive for `30K+` notes, `4K+` people, aliases, renames, sync races, ambiguous names, and incremental updates.

The system needs an explicit engine with:

- stable person IDs;
- stable alias IDs;
- alias policies;
- mention provenance;
- confidence scores;
- invalidation reasons;
- delta/compaction strategy;
- concurrency protocol;
- reader snapshot pinning;
- quality benchmarks.

## Non-Negotiable Invariants

- Renderer never reads vault files.
- Renderer never parses markdown.
- Renderer never links people.
- Renderer receives only cached graph arrays and `RenderPlan`.
- People linking never blocks first visual.
- Cached `current` snapshot is the core guarantee.
- Prewarm is only an opportunistic freshness accelerator.
- Readers never read `staging`.
- Readers pin `snapshotBuildId` while rendering.
- Snapshot swap applies only between frames.
- Machine-generated people edges are never mixed with human markdown edges.
- Every people edge is explainable through mention provenance.
- Alias/policy changes have explicit invalidation behavior.
- Storage errors degrade to previous snapshot, not crash.

## Why Prewarm Is Not The Core Guarantee

Computer-start prewarm is useful, but cannot be the foundation.

It can be stale or wrong because:

- the machine may wake from sleep instead of booting;
- Obsidian Sync, Dropbox, iCloud, or Git may change files after prewarm;
- the user may open the vault before prewarm finishes;
- several processes may try to write cache;
- prewarm may run with an old plugin/build version;
- lock cleanup may fail after crash.

Correct model:

```txt
Core guarantee = cached current snapshot always loads fast.
Prewarmer = optional cache freshness accelerator.
```

## Target Runtime Flow

```txt
Open graph view
-> load current snapshot immediately
-> pin snapshotBuildId
-> build first RenderPlan
-> render first visual
-> run freshness check after first frame
-> start background people-link update if needed
-> validate staging snapshot
-> swap current pointer between frames
-> unpin old snapshot after readers finish
```

If rebuild fails:

```txt
keep current
record incident
mark people links failed/stale
continue rendering
```

If current is corrupt:

```txt
fallback to previous
mark previous-active
start repair in background
```

## Cache Layout v10

```txt
Calendula-20K/.graph-cache/v10/
  pointer.json
  locks/
    writer.lock
  snapshots/
    current/
    previous/
    staging-{buildId}/
  indices/
    files/
    people/
    aliases/
    mentions/
    postings/
    deltas/
  logs/
    incidents.jsonl
    prewarm.log
    quality-report.json
```

`pointer.json` is the only hot pointer:

```json
{
  "schemaVersion": "10.0",
  "currentBuildId": "build-...",
  "previousBuildId": "build-...",
  "peoplePolicyVersion": 1,
  "matcherVersion": 1,
  "freshness": {
    "graph": "fresh",
    "people": "stale-files",
    "layout": "fresh"
  }
}
```

## Snapshot Reader Safety

Contracts:

```txt
SnapshotPointer
  schemaVersion
  currentBuildId
  previousBuildId
  policyVersions
  freshness

ReaderLease
  readerId
  snapshotBuildId
  startedAt
  lastSeenAt

RenderPlan
  snapshotBuildId
  queryGeneration
  buildTimings
```

Rules:

- `GraphStoreClient` loads only the build referenced by `pointer.json`.
- A render session pins one `snapshotBuildId`.
- Swaps happen only between frames.
- Old snapshots are removed only after no reader leases remain.
- If lease tracking fails, old snapshots are retained until next safe cleanup.

## Writer Concurrency Protocol

Only one writer may publish to `.graph-cache/v10`.

Writer lock fields:

```txt
ownerId
processId
buildId
pluginVersion
schemaVersion
startedAt
leaseUntil
heartbeatAt
```

Rules:

- writer uses unique `staging-{buildId}`;
- writer heartbeats lock lease;
- stale lock can be reclaimed only after timeout;
- writer validates staging before publish;
- publish is atomic pointer swap;
- reader never reads staging;
- test runner uses a separate temp cache root unless explicitly testing production cache.

## People Alias Store

Do not store aliases as one loose JSON array.

Required model:

```txt
people/
  people.ids.u32
  people.path.sid.u32
  people.status.u8
  people.version.u32

aliases/
  alias.id.u32
  alias.personId.u32
  alias.normalized.sid.u32
  alias.flags.u32
  alias.minConfidence.f32
  alias.language.u16
  alias.version.u32
```

Person statuses:

```txt
active
tombstone
merged
split
disabled
```

Alias flags:

```txt
caseSensitive
wholeWordOnly
allowInsideLinks
allowPossessive
shortAlias
ambiguous
disabled
requiresContext
commonWord
```

ID policy:

- `personId` is stable across path rename.
- `aliasId` is stable across non-semantic metadata changes.
- deleted people become tombstones, not immediate ID reuse.
- merge/split operations are explicit repair events.

## Matcher Pipeline

Fast matching is only one stage.

Pipeline:

```txt
TextNormalizer
-> SectionFilter
-> AliasMatcher
-> ContextValidator
-> AmbiguityResolver
-> ConfidenceScorer
-> MentionEmitter
```

`SectionFilter` must exclude or mark:

- YAML frontmatter;
- fenced code blocks;
- inline code;
- URLs;
- markdown links;
- existing wikilinks;
- optional headings;
- optional quotes.

`AliasMatcher` can use Aho-Corasick or equivalent single-pass matching, but match candidates are not mentions yet.

Candidate lifecycle:

```txt
candidate match
-> context filter
-> alias policy
-> ambiguity policy
-> confidence score
-> dedupe
-> mention emission
```

## Safety Policies

Default policies should prefer missing a weak automatic edge over polluting the graph.

Required policy knobs:

```txt
minAliasLength
shortAliasRequiresContext
ambiguousAliasDisabledByDefault
doNotMatchInsideCode
doNotMatchInsideLinks
doNotMatchCommonWords
maxMentionsPerNotePerPerson
maxAutoPeopleEdgesPerNote
confidenceThreshold
wholeWordByDefault
```

Examples:

- `May` should not auto-link as a person without context.
- `Вера` may be a person or a concept; it requires policy/context.
- aliases of `2-3` characters are disabled or require context by default.
- matches inside URLs/code/wikilinks are rejected unless explicitly allowed.

## Mention Store

Edges are derived from mentions. Mentions are the source of explainability.

Hot renderer does not load mentions. Debug, repair, and quality tooling do.

Mention arrays:

```txt
mentions/
  mention.noteId.u32
  mention.personId.u32
  mention.aliasId.u32
  mention.offset.u32
  mention.length.u16
  mention.confidence.f32
  mention.flags.u32
  mention.policyVersion.u32
```

Required derived indexes:

```txt
note -> mention ids
person -> mention ids
alias -> note postings
person -> alias ids
note -> matched alias ids
```

This enables:

- replacing mentions for one changed note;
- removing stale mentions for a removed alias;
- explaining a generated edge;
- targeted rescans where possible;
- safe fallback to full people-link rebuild where necessary.

## Edge Provenance

People edges must be typed and explainable.

Edge source types:

```txt
manual-wikilink
markdown-link
tag-derived
people-autolink
people-confirmed
synthetic-cluster
```

People edge fields:

```txt
sourceId
targetId
edgeType = people-autolink | people-confirmed
provenanceRangeStart
provenanceCount
confidenceAggregate
policyVersion
```

Renderer may use only compact edge arrays:

```txt
edgeSourceId
edgeTargetId
edgeFlags
edgeType
confidenceBucket
```

Debug tooling can load provenance lazily.

## Incremental Invalidation Graph

Every rebuild has a reason.

Invalidation reasons:

```txt
NOTE_CHANGED
NOTE_DELETED
PERSON_RENAMED
PERSON_DELETED
PERSON_MERGED
PERSON_SPLIT
ALIAS_ADDED
ALIAS_REMOVED
ALIAS_POLICY_CHANGED
MATCHER_VERSION_CHANGED
NORMALIZER_VERSION_CHANGED
STORAGE_SCHEMA_CHANGED
```

Decision table:

| Change | Minimal action | Fallback |
| --- | --- | --- |
| note changed | rescan note, replace note mentions and generated people edges | queue full people rebuild if parsing fails |
| note deleted | remove note mentions and generated people edges | tombstone note in delta |
| person path changed | update person metadata only | rebuild person postings if ID missing |
| alias added | targeted sweep if postings exist, otherwise alias sweep | full people-link rebuild |
| alias removed | remove mentions by aliasId | full people-link rebuild if provenance missing |
| alias policy changed | rescan affected aliases | full people-link rebuild |
| matcher changed | policy-version rebuild | full people-link rebuild |
| normalizer changed | full people-link rebuild | keep previous active until ready |

## Fingerprint Strategy

Use layered fingerprints.

```txt
quick stat hash:
  path + size + mtime

content hash:
  only when stat changed or uncertain

semantic hash:
  normalized markdown excluding volatile metadata

people-scan hash:
  text after excluding code, links, URLs, and ignored sections
```

People scan should run only when `people-scan hash` changes or when alias/policy invalidation requires it.

## Delta And Compaction

CSR is excellent for rendering reads. It is not ideal for frequent tiny writes.

Use:

```txt
base compacted snapshot
+ delta updates
+ periodic compaction
```

Initial practical policy:

```txt
small update:
  replace affected note mention group
  replace affected generated people edge group
  append delta

medium update:
  rebuild people edge group
  keep base graph arrays

large update or policy version change:
  staging full people-link rebuild
```

Compaction runs in background and publishes a new compacted snapshot only after validation.

## Freshness Model

Freshness must be per subsystem.

States:

```txt
fresh
stale-files
stale-aliases
stale-policy
stale-layout
building
failed
partial
previous-active
```

Example:

```txt
graph visual: fresh
people links: stale-aliases
layout: fresh
```

UI should expose this without blocking rendering.

## Benchmarks

Runtime metrics:

```txt
filesScanned
filesParsed
peopleCount
aliasCount
candidateMatches
mentionsEmitted
edgesCreated
edgesRejected
csrWriteMs
deltaWriteMs
manifestMs
totalBuildMs
memoryPeakMb
snapshotSizeMb
```

Quality metrics:

```txt
matchesFound
matchesRejected
ambiguousMatches
shortAliasMatches
confidenceDistribution
topNoisyAliases
edgesPerNoteP95
peoplePerNoteP95
falsePositiveReviewSample
```

Benchmark suites:

```txt
bench:v10-snapshot-open
bench:v10-warm-nochange
bench:v10-one-note-changed
bench:v10-hundred-notes-changed
bench:v10-alias-added
bench:v10-alias-removed
bench:v10-policy-change
bench:v10-4k-people-quality
bench:v10-snapshot-swap
```

## Test Requirements

Every phase needs contract, test, benchmark, fallback, and error handling.

Required cases:

- renderer does not read markdown;
- renderer does not link people;
- reader pins `snapshotBuildId`;
- reader never reads staging;
- writer lock prevents two cache writers;
- stale writer lock can be recovered;
- corrupt current falls back to previous;
- short aliases are disabled or context-required;
- ambiguous aliases do not auto-link by default;
- code blocks, inline code, URLs, markdown links, and wikilinks are excluded;
- one changed note replaces only that note's mentions;
- alias removal removes stale mentions by `aliasId`;
- person rename preserves stable `personId`;
- deleted person creates tombstone;
- provenance explains every generated people edge;
- quality report flags noisy aliases;
- policy version change forces correct invalidation.

## Implementation Order

### Phase 0 - Snapshot Reader Safety

Tasks:

```txt
current/previous/staging pointer
reader snapshot pinning
atomic pointer swap only between frames
RenderPlan carries snapshotBuildId
previous fallback on current corruption
writer lock lease contract
```

Done when:

```txt
First visual opens from current cache.
Renderer can survive corrupt current.
Concurrent writer cannot publish partial staging.
```

### Phase 1 - People Alias Index MVP

Tasks:

```txt
stable personId
stable aliasId
normalized aliases
alias flags
person tombstone status
short/ambiguous aliases disabled by default
```

Done when:

```txt
People rename does not change personId.
Alias policy is explicit.
Dangerous aliases are not matched automatically.
```

### Phase 2 - Single-Pass Matcher MVP

Tasks:

```txt
TextNormalizer
SectionFilter
single-pass alias matcher
whole-word matching
candidate rejection reasons
mention output
```

Done when:

```txt
One note can be scanned without full vault rebuild.
Rejected matches are counted and explainable.
```

### Phase 3 - Mention Store

Tasks:

```txt
store mentions
derive people edges from mentions
edge provenance
dedupe by note/person/alias
lazy debug provenance load
```

Done when:

```txt
Every generated people edge can be traced to mentions.
Edges are not emitted directly from raw matcher candidates.
```

### Phase 4 - Incremental Notes

Tasks:

```txt
file manifest
layered fingerprints
changed note scan
replace note mentions atomically
replace generated note people edges
fallback to previous on failure
```

Done when:

```txt
Changing one diary note does not trigger full people-link rebuild.
Old mentions for that note are removed safely.
```

### Phase 5 - Alias Invalidation

Tasks:

```txt
alias postings
alias added/removed policies
person renamed handling
policy version invalidation
targeted rescan when possible
full rebuild when required
```

Done when:

```txt
Alias changes do not leave stale edges.
The engine records why targeted or full rebuild was chosen.
```

### Phase 6 - Delta And Compaction

Tasks:

```txt
delta update log
read view = base + deltas
compaction threshold policy
background compaction
validation before publish
```

Done when:

```txt
Small updates avoid rewriting full CSR.
Compacted snapshot remains renderer-friendly.
```

### Phase 7 - Background Prewarm

Tasks:

```txt
plugin-side background prewarm
low-priority chunks
lock lease
incident logs
optional Windows Task Scheduler installer later
```

Done when:

```txt
Prewarm improves freshness but is not required for fast open.
Task Scheduler is optional, not core.
```

### Phase 8 - Renderer Integration

Tasks:

```txt
load cached snapshot immediately
people edge budget
person selection ego graph
stale people badge
snapshot swap between frames
```

Done when:

```txt
Visual never waits for people linking.
Fresh people links can appear after background swap without blocking input.
```

## First Slice

`V10-S1: Safe People Mentions MVP`

Tasks:

```txt
1. Define stable personId and aliasId.
2. Build PeopleAliasIndex with normalized aliases.
3. Reject or disable short ambiguous aliases by default.
4. Scan one changed note with single-pass matcher.
5. Exclude code blocks, URLs, markdown links, and wikilinks.
6. Emit mentions, not edges directly.
7. Derive note -> person edges from mentions.
8. Store mention provenance.
9. Replace mentions for changed note atomically.
10. Benchmark scan time, rejection counts, and noisy aliases.
```

Done:

```txt
People linking no longer sits in render path.
One note can be rescanned without full vault rebuild.
False positives are controlled by policy.
Edges are explainable.
Renderer still only sees cached graph.
```

## Deferred Until After S1

Lower priority:

- Windows Task Scheduler installer;
- WebGL discussion;
- fancy LOD policy;
- full 50K visual hierarchy;
- aggressive CSR write optimization before delta policy exists.

Higher priority:

- alias ambiguity;
- mention provenance;
- stable person IDs;
- snapshot reader pinning;
- writer lock lease;
- quality metrics;
- invalidation rules.

## Open Bugs To Track

```txt
V10-B001: false positives from short aliases can poison graph.
V10-B002: alias removal can leave stale generated people edges without provenance.
V10-B003: person rename can break layout/history if personId is path-derived.
V10-B004: concurrent cache writers can publish partial or stale snapshots.
V10-B005: current snapshot corruption can block first visual without previous fallback.
V10-B006: full CSR rewrite can make small updates too expensive.
V10-B007: quality benchmarks can pass runtime while producing bad links.
```
