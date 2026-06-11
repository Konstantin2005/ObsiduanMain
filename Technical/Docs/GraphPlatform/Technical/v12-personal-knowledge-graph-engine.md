# Personal Knowledge Graph Engine v12

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

v11 made the people engine survivable.

It added the missing operational foundation: identity, sync safety, human corrections, migration, privacy boundary, load shedding, and local/shared storage split.

But v11 is defensive. It protects the graph from breaking. It does not yet make the graph deeply useful at very large scale.

v12 moves from safe linking to personal knowledge understanding.

```txt
Mentions are not knowledge.
Edges are not knowledge.
Evidence over time creates knowledge.
```

Core formula:

```txt
Vault
-> Signals
-> Evidence Store
-> Decision Engine
-> Entity Graph
-> Temporal Graph
-> Importance Engine
-> Render Graph
```

## What v12 Fixes In v11

v11 answers:

```txt
How do we make people linking safe for years?
```

v12 answers:

```txt
How do we make a 10-year, 200K-note graph still explain life, work, people, and change?
```

v11 protects against:

- wrong links;
- sync conflicts;
- path renames;
- migrations;
- cache corruption;
- missing user correction loop.

v12 adds:

- evidence, not just decisions;
- temporal evolution, not just current edges;
- ranking, not equal nodes;
- relationship inference, not only note-to-person links;
- entity resolution suggestions, not only manual merges;
- analytics APIs, not only rendering;
- sensitivity levels, not only cache deletion.

## Active Scope

v12 does not replace v11. It sits on top of it.

Retained from v11:

- UUID identity;
- runtime local IDs;
- local/shared storage split;
- cache can be deleted and rebuilt;
- renderer remains isolated;
- user corrections outrank automatic rules;
- load shedding protects Obsidian;
- migrations are explicit.

Added in v12:

- Signal model;
- Evidence Store;
- decision as evidence aggregation;
- PersonRank, NoteRank, ClusterRank;
- relationship inference v0;
- temporal counters;
- entity resolution suggestions;
- Graph Intelligence API;
- explanation API;
- sensitivity model.

## Non-Negotiable Invariants

- Renderer never reads vault files.
- Renderer never computes intelligence.
- Renderer receives only cached render graph arrays.
- Human corrections remain the highest-priority override.
- Human corrections should teach future policy, not become the main quality mechanism.
- Every generated decision must reference evidence.
- Evidence is append-friendly and replayable.
- Ranking is derived, not hand-mutated.
- Relationship inference must be explainable.
- Temporal data is kept separate from first-frame rendering.
- Sensitive entities can be hidden from analytics and rendering.
- Any intelligence layer can be disabled without breaking the base graph.

## Layer 1 - Signal And Evidence Engine

v11 has:

```txt
mention -> decision
```

v12 needs:

```txt
raw signal
-> evidence
-> decision
-> edge
```

Signal types:

```txt
ALIAS_MATCH
WIKILINK
TAG_CONTEXT
DATE_CONTEXT
HEADING_CONTEXT
NEARBY_KEYWORD
CO_MENTION
RECENT_INTERACTION
MANUAL_CORRECTION
```

Evidence record:

```json
{
  "evidenceId": "uuid",
  "entityUuid": "uuid",
  "sourceUuid": "note-or-person-uuid",
  "type": "PERSON_SIGNAL",
  "signal": "ALIAS_MATCH",
  "strength": "strong",
  "reason": "exact full-name alias",
  "timeBucket": "2026-06",
  "policyVersion": 1,
  "extractorVersion": 1
}
```

Decision record:

```json
{
  "decisionId": "uuid",
  "decision": "ACCEPT",
  "target": "note-person-edge",
  "evidenceIds": ["uuid"],
  "rejectedEvidenceIds": ["uuid"],
  "policyVersion": 1
}
```

Rules:

- evidence can survive decision-policy changes;
- decisions can be recomputed from evidence;
- evidence records explain why the graph thinks something;
- raw text is not duplicated into evidence unless explicitly needed.

## Layer 2 - Decision Plus Evidence

v11 correctly removed fake confidence floats.

v12 keeps explicit decisions but adds evidence lists.

Example:

```json
{
  "decision": "ACCEPT",
  "evidence": [
    "exact_alias",
    "same_social_cluster",
    "recent_interaction",
    "diary_context"
  ]
}
```

Initial decision values:

```txt
ACCEPT
REJECT
DEFER
NEEDS_REVIEW
USER_ACCEPTED
USER_REJECTED
```

Initial evidence weights should be ordinal, not pseudo-scientific:

```txt
weak
medium
strong
decisive
negative
```

Numeric confidence remains deferred until there is review data and calibration.

## Layer 3 - Policy Evolution Engine

Human correction is not the primary quality system. It is a feedback source.

Flow:

```txt
human correction
-> correction store
-> policy observation
-> future decision improvement
```

Examples:

- repeated `USER_REJECTED` for an alias can mark it as ambiguous;
- repeated accepted context can create a local context rule;
- repeated merge corrections can create duplicate-detection features;
- rejected author-name matches can lower priority for book-title contexts.

Policy evolution must be conservative:

- never silently override explicit user corrections;
- never train on sensitive hidden entities unless allowed;
- produce a reviewable policy diff;
- allow rollback to previous policy.

## Layer 4 - Temporal Graph

Large personal graphs are historical.

An edge is not just present or absent.

Temporal edge fields:

```txt
createdAt
firstSeen
lastSeen
activePeriods
timeBuckets
strengthHistory
decayWeight
```

Example:

```txt
Person Alice
  2022: 5 mentions
  2023: 80 mentions
  2024: 2 mentions
```

Temporal model supports:

- new people;
- disappearing people;
- old contacts;
- revived relationships;
- project-specific periods;
- long-term trends.

Renderer receives current relevance, not the whole history.

## Layer 5 - Importance Engine

For `4K+` people, equal nodes are useless.

Ranking outputs:

```txt
PersonRank
NoteRank
ClusterRank
RelationshipRank
```

PersonRank inputs:

- frequency;
- recency;
- relationship strength;
- manual importance;
- cluster centrality;
- interaction diversity;
- temporal persistence;
- user corrections;
- sensitivity policy.

Initial output:

```json
{
  "personUuid": "uuid",
  "rankBucket": "important",
  "signals": [
    "frequent_recent_mentions",
    "multi_cluster_presence",
    "manual_star"
  ]
}
```

Use rank buckets first:

```txt
hidden
low
normal
important
core
```

Numeric rank can come later after benchmarks.

## Layer 6 - Relationship Engine

v11 focuses on:

```txt
note -> person
```

v12 adds:

```txt
person -> person
```

Relationship types:

```txt
unknown
friend
family
coworker
project
author
organization
recurring-context
```

Initial inference v0:

```txt
co-mentioned in same diary note
co-mentioned in same project note
same explicit wikilink cluster
same tags or headings
manual correction
```

Relationship record:

```json
{
  "sourcePersonUuid": "uuid",
  "targetPersonUuid": "uuid",
  "relationshipType": "unknown",
  "strengthBucket": "medium",
  "timeRange": "2026",
  "evidenceIds": ["uuid"],
  "decision": "ACCEPT"
}
```

Relationship inference must always be explainable and reversible.

## Layer 7 - Entity Intelligence

Manual merge/split is not enough for long-lived vaults.

EntityResolver should suggest, not auto-merge.

Capabilities:

```txt
duplicate detection
merge suggestions
alias discovery
unknown person detection
conflicting identity detection
```

Suggestion record:

```json
{
  "suggestionId": "uuid",
  "type": "POSSIBLE_DUPLICATE_PERSON",
  "entityUuids": ["uuid", "uuid"],
  "evidence": [
    "same alias initial",
    "same notes",
    "same project cluster",
    "nearby dates"
  ],
  "status": "pending"
}
```

Rules:

- resolver suggests, user confirms;
- suggestions can be hidden or dismissed;
- dismissed suggestions become negative evidence;
- confirmed merges update identity mappings through v11 migration rules.

## Layer 8 - Aging And Forgetting

Do not delete old knowledge by default.

Use decay to produce a current relevance graph.

```txt
fresh edge:
  currentWeight = high

5 years inactive:
  currentWeight = low

historical query:
  full historical weight is still available
```

Decay inputs:

- last seen;
- frequency drop;
- relationship type;
- manual importance;
- sensitivity;
- project status.

Renderer default:

```txt
show current relevance graph
```

Analytics can request:

```txt
historical graph
```

## Layer 9 - Graph Intelligence API

The graph should serve more than rendering.

Initial API:

```txt
findRelatedPeople(entityUuid, options)
getTimeline(entityUuid, range)
explainConnection(sourceUuid, targetUuid)
suggestMerge(entityUuid)
findEmergingClusters(range)
findDisappearingPeople(range)
findMostSeenPeople(range)
findProjectPeople(projectUuid)
```

API rules:

- no direct markdown reads;
- uses cached evidence/entity/temporal stores;
- respects sensitivity policy;
- returns explanation IDs where possible;
- degrades gracefully if intelligence stores are stale.

## Layer 10 - Security And Sensitivity

Privacy in v11 is not enough for people intelligence.

Sensitivity levels:

```txt
public
private
hidden
excluded-from-analytics
```

Rules:

- hidden people do not appear in render graph;
- excluded-from-analytics people are not used in ranking or cluster discovery;
- private people can render locally but never leave local cache;
- shared metadata must not expose hidden analytics by accident;
- delete commands must distinguish local cache and shared corrections/identities.

## First Slice

`V12-S1 Intelligent People Graph Core`

Tasks:

```txt
1. Keep v11 Entity UUID system.
2. Add Signal model.
3. Add Evidence Store.
4. Make decisions aggregate evidence.
5. Extract mentions into evidence-backed decisions.
6. Add PersonRank buckets.
7. Add relationship inference v0 from co-mentions.
8. Add temporal counters by month/year.
9. Produce cached render graph with rank and current relevance.
10. Add Explain API for note-person and person-person edges.
```

Done:

```txt
The system does not only know:
  "name was found"

It knows:
  why it was found,
  why it was accepted or rejected,
  how important it is,
  when it mattered,
  who it connects to,
  and how that changed over time.
```

## Implementation Progress

### V12-S1A - Evidence Contract Foundation

Status: `DONE`

Completed:

```txt
Signal enum
EvidenceRecord/v12.0 contract
EvidenceDecision/v12.0 contract
EvidenceMention/v12.0 contract
EvidenceGeneratedEdge/v12.0 contract
decision aggregation from evidence
human rejection override
negative section evidence rejection
generated edge blocked for rejected decisions
raw text stripped from evidence metadata
synthetic evidence benchmark
```

Measured:

```txt
50K evidence records: 41.687ms
50K decisions: 42.107ms
mentions/edges batch: 12.493ms
total synthetic benchmark: 96.287ms
accepted decisions: 45,000
rejected decisions: 5,000
generated edges: 15,000
```

Verified:

```txt
Pester: 43 passed, 0 failed
Calendula-20K fixture: 33,903 nodes, 35,956 edges, 0 unresolved
```

Remaining in `V12-S1`:

```txt
Entity UUID system integration
Signal extraction from real note text
Evidence Store persistence
Temporal counters
PersonRank buckets
Relationship inference v0
Explain API
Renderer cached rank hints
```

## Implementation Phases

### Phase 0 - Evidence Contract

Tasks:

```txt
Signal enum
Evidence record
Decision record references evidenceIds
evidence replay contract
```

Done when:

```txt
Changing decision policy does not require rereading every markdown file if evidence is still valid.
```

### Phase 1 - Evidence-Backed Mentions

Tasks:

```txt
alias match emits signal
section filter emits negative evidence
decision aggregates evidence
mention keeps decisionId
generated edge keeps decisionId
```

Done when:

```txt
Every generated note-person edge has an explanation chain.
```

### Phase 2 - Temporal Counters

Tasks:

```txt
time bucket extraction
person mention counts by month/year
relationship counts by month/year
lastSeen and firstSeen
```

Done when:

```txt
The system can answer who appeared often in a given year without scanning markdown.
```

### Phase 3 - Rank Buckets

Tasks:

```txt
PersonRank buckets
NoteRank buckets
manual importance override
recency/frequency ranking
renderer rank hint
```

Done when:

```txt
Core people and incidental mentions no longer render as equally important.
```

### Phase 4 - Relationship Inference v0

Tasks:

```txt
co-mention evidence
person-person edge generation
relationship strength buckets
relationship explanation
```

Done when:

```txt
Selecting a person can show a useful ego graph with explained connections.
```

### Phase 5 - Entity Resolution Suggestions

Tasks:

```txt
duplicate candidate generation
alias discovery
unknown person candidates
dismiss/accept suggestion
suggestion evidence
```

Done when:

```txt
The system suggests possible duplicate people but never auto-merges without approval.
```

### Phase 6 - Intelligence API

Tasks:

```txt
findRelatedPeople
getTimeline
explainConnection
suggestMerge
findEmergingClusters
findDisappearingPeople
```

Done when:

```txt
Graph data can power analysis features without touching renderer internals.
```

### Phase 7 - Sensitivity Controls

Tasks:

```txt
entity sensitivity levels
analytics exclusion
render exclusion
private local-only records
privacy test suite
```

Done when:

```txt
Sensitive people can be excluded from visualization and intelligence without corrupting the graph.
```

## What To Lower From v11

Lower early priority:

- complex migration modes;
- many correction types;
- perfect privacy UI;
- physical JSONL vs binary debate;
- advanced writer fencing;
- Task Scheduler prewarm.

Raise priority:

- Evidence Store;
- Temporal Graph;
- Ranking;
- Relationship inference;
- Entity resolution;
- Graph Intelligence API;
- sensitivity levels.

## Tests

Required tests:

- decisions reference evidence IDs;
- rejected code/link/wiki matches produce negative evidence;
- evidence replay can recompute decisions;
- user correction creates decisive evidence;
- person rank changes with recency/frequency;
- old inactive relationships decay in current relevance;
- historical query still sees old evidence;
- co-mentions create explainable relationship edge;
- dismissed duplicate suggestion does not reappear immediately;
- hidden person does not appear in render graph;
- analytics-excluded person does not affect ranking;
- explain API returns evidence chain;
- intelligence API does not read markdown;
- renderer does not compute intelligence.

## Benchmarks

Runtime:

```txt
signalExtractionMs
evidenceWriteMs
decisionAggregationMs
temporalCounterMs
rankBuildMs
relationshipInferenceMs
intelligenceApiP95Ms
renderGraphBuildMs
```

Scale:

```txt
notes: 30K, 100K, 200K
people: 4K, 10K
mentions: 500K, 2M
relationships: 100K, 1M
```

Quality:

```txt
acceptedEvidenceCount
rejectedEvidenceCount
relationshipExplainabilityRate
duplicateSuggestionAcceptanceRate
topRankedPeopleReviewSample
falseRelationshipReviewSample
temporalTrendReviewSample
```

## Open Bugs To Track

```txt
V12-B001: human corrections can become manual busywork instead of policy feedback.
V12-B002: decision enums without evidence cannot explain different contexts.
V12-B003: current-only edges cannot represent relationships changing over years.
V12-B004: equal ranking makes core people and incidental mentions visually identical.
V12-B005: manual-only merge does not scale to many aliases and duplicate identities.
V12-B006: no decay model makes old stale relationships pollute current graph.
V12-B007: renderer-only graph misses analytics value from the knowledge engine.
V12-B008: local-only privacy without sensitivity levels is too coarse for people data.
```
