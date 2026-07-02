# Adaptive Parallel Index Compiler v15

Status values: `TODO`, `DOING`, `DONE`, `BUG`, `REGRESSION`, `BLOCKED`.

## Main Verdict

Worker pool is useful, but it is not the architecture.

It accelerates CPU-bound parsing/hash/link extraction. If the bottleneck is disk IO, resolver, array materialization, cache invalidation, or publish protocol, workers can add noise, races, memory pressure, and complexity without much speedup.

v15 defines the correct hierarchy:

```txt
1. Do not read the file.
2. If reading is required, read it once.
3. If many reads are required, batch IO.
4. If CPU is proven bottleneck, use bounded workers.
```

Core formula:

```txt
Workers are not architecture.
Workers are acceleration behind a deterministic WorkPlan.
```

## Relationship To v14

v14 answers:

```txt
which graph facts depend on these changes?
```

v15 answers:

```txt
how do we spend more machine resources on only the required file work,
without breaking determinism, memory budgets, or renderer isolation?
```

The intended flow:

```txt
v14 trust planner decides what must be read
-> v15 bounded worker pool extracts raw facts
-> deterministic compiler assigns IDs and resolves links
-> single publisher writes validated snapshot
```

## Non-Negotiable Invariants

- Renderer never starts workers.
- Renderer never parses markdown.
- Workers never write graph snapshots.
- Workers never publish cache.
- Workers never assign node IDs.
- Workers never resolve global graph links.
- Main compiler remains deterministic.
- Publisher remains single-writer.
- Worker results carry `buildId` and stale results are dropped.
- Worker pool has backpressure.
- Worker failure does not automatically kill the whole build.
- Warm trusted path uses zero workers because it reads zero markdown.

## Layer 1 - Work Planner

Workers must run behind a plan.

Input:

```txt
file manifest
trust states
parser version
resolver version
schema version
build mode
resource policy
```

Output:

```txt
WorkPlan {
  buildId
  mode
  filesToRead
  filesToReuse
  filesToVerify
  deletedFiles
  renamedFiles
  estimatedBytes
  reasonCodes
}
```

Build modes:

```txt
COLD_FULL_BUILD
WARM_TRUSTED
WARM_SUSPECT_VERIFY
SMALL_CHANGED_SET
BATCH_CHANGED_SET
REPAIR
```

Rule:

```txt
WARM_TRUSTED should schedule no worker file reads.
```

## Layer 2 - Resource Governor

Do not use CPU count alone.

Resource policy:

```txt
ResourcePolicy {
  workerCount
  maxInFlightChunks
  maxInFlightBytes
  targetChunkBytes
  maxReadConcurrency
  maxMemoryMb
  mode
}
```

Modes:

```txt
single
safe
auto
aggressive
ci
```

Initial safe policy:

```txt
workers = min(4, cores - 1)
targetChunkBytes = 1-4 MB
maxInFlightChunks = workers * 2
maxInFlightBytes = 32-64 MB
```

Adaptive policy later:

```txt
if throughput improves -> keep or increase
if disk wait high -> reduce read concurrency
if memory high -> reduce in-flight bytes
if worker overhead dominates -> reduce workers
```

## Layer 3 - Chunking By Bytes

Do not chunk only by file count.

Files vary:

- small diary notes;
- huge markdown files;
- notes with thousands of links;
- pasted/generated content.

Chunk policy:

```txt
targetChunkBytes
maxFilesPerChunk
maxSingleFileBytes
oversizedFileMode
```

Rules:

```txt
small files -> grouped by estimated bytes
large files -> own chunk
oversized files -> special path with stricter memory budget
```

## Layer 4 - Worker Task

Worker returns raw note facts only.

Worker may do:

```txt
read file if assigned
hash while reading
parse markdown
extract raw wikilinks
extract raw tags
summarize frontmatter keys
detect local parse warnings
```

Worker must not do:

```txt
nodeId assignment
global resolve
edge array building
snapshot writing
published cache mutation
global identity merge
global policy decisions
```

Worker output:

```txt
ParsedNoteRecord {
  buildId
  path
  expectedStat
  contentHash
  semanticHash
  linkScanHash
  rawLinks
  rawTags
  frontmatterSummary
  parseWarnings
}
```

## Layer 5 - Bounded Scheduler

Needed controls:

```txt
maxInFlightChunks
maxInFlightBytes
maxReadConcurrency
resultQueueLimit
AbortSignal
buildId
generation token
```

Rules:

- pause scheduling when queue is full;
- drop stale worker results;
- stop workers on abort;
- never let worker results grow unbounded in memory;
- emit worker utilization and queue metrics.

## Layer 6 - Result Collector

Collector responsibilities:

```txt
sort records deterministically
drop stale buildId
merge cached records
track failed files
track parse warnings
enforce memory budget
normalize result order
```

Collector must not publish.

## Layer 7 - Deterministic Compiler

Main thread/compiler:

```txt
assign stable local IDs
resolve links
dedupe edges
sort edges deterministically
sort unresolved deterministically
sort warnings deterministically
build arrays
validate snapshot
hand off to publisher
```

Determinism requirements:

```txt
node order
edge order
duplicate edge dedupe order
unresolved order
basename collision order
warnings order
benchmark output order
```

## Layer 8 - Failure Strategy

Failure levels:

```txt
FILE_FAILURE
CHUNK_FAILURE
WORKER_FAILURE
POOL_FAILURE
BUILD_FAILURE
PUBLISH_FAILURE
```

Policies:

```txt
file failure -> keep old record or mark failed
chunk failure -> retry/split
worker failure -> replace worker
pool failure -> single-thread remaining work
publish failure -> keep previous snapshot
```

Do not full-fallback on one bad file.

Full single-thread fallback is reserved for:

```txt
worker infrastructure failure
serialization contract failure
repeated chunk failure after split
```

## Layer 9 - Cancellation And Stale Results

Every task carries:

```txt
buildId
generation
chunkId
```

Abort behavior:

```txt
AbortController triggered
-> stop scheduling
-> terminate idle workers
-> reject in-flight stale results
-> do not publish staging
```

New build starts:

```txt
generation increments
old results discarded
```

## Layer 10 - Benchmark Reporter

Benchmark schema:

```json
{
  "buildMode": "COLD_FULL_BUILD",
  "workersRequested": 8,
  "workersUsed": 4,
  "chunkPolicy": {
    "targetChunkBytes": 4194304,
    "maxInFlightChunks": 8,
    "maxInFlightBytes": 33554432
  },
  "io": {
    "filesRead": 33903,
    "bytesRead": 123456789,
    "maxConcurrentReads": 6
  },
  "workers": {
    "chunksScheduled": 80,
    "chunksCompleted": 80,
    "chunksRetried": 0,
    "workerRestarts": 0,
    "staleResultsDropped": 0
  },
  "determinism": {
    "singleSnapshotHash": "...",
    "parallelSnapshotHash": "...",
    "equal": true
  },
  "timingsMs": {
    "planner": 40,
    "workerReadHashParse": 900,
    "collect": 30,
    "resolve": 180,
    "arrayBuild": 120,
    "write": 90,
    "total": 1360
  }
}
```

## First Slice

`V15-S1 Bounded Worker Pool With Deterministic Compiler`

Tasks:

```txt
1. Add timing breakdown before worker work.
2. Define WorkPlan contract.
3. Add --workers, --chunk-size, --max-in-flight.
4. Implement graph-build-file-worker.js for read/hash/parse/rawLinks only.
5. Implement worker pool with buildId and AbortSignal.
6. Main thread assigns IDs and resolves links.
7. Add deterministic sort of records/warnings/edges.
8. Add parallel-vs-single snapshot hash comparison.
9. Add retry/split chunk on worker failure.
10. Add benchmark worker utilization and IO counters.
```

Done:

```txt
workers=1 equals old path
workers=4/8 produce byte-stable graph output
worker crash does not kill build
renderer untouched
no writes happen in workers
benchmark proves where speedup came from
```

## Tests

Required tests:

```txt
workers=1 equals single-thread
workers=4 equals single-thread
workers=8 equals single-thread
worker crash retries chunk
chunk with bad file isolates bad file
abort cancels build
stale worker result discarded
maxInFlightBytes respected
no worker writes snapshot
no renderer starts workers
edge order deterministic
warning order deterministic
benchmark schema stable
```

## Extension Points For Future Agents

```txt
ExtensionPoint: WorkPlanner
- can integrate v14 trust-aware planner

ExtensionPoint: WorkerTask
- can add people mention extraction later

ExtensionPoint: ResourcePolicy
- can become adaptive based on benchmark history

ExtensionPoint: ResultCollector
- can support streaming records to disk

ExtensionPoint: Compiler
- can move resolver to worker later only if deterministic

ExtensionPoint: SnapshotPublisher
- can add current/previous/staging protocol

ExtensionPoint: BenchmarkReporter
- can compare runs over time
```

## What To Defer

Defer initially:

- workers `8` as default;
- aggressive mode as default;
- worker-side stat;
- worker-side global node type policy;
- resolver in worker;
- snapshot writes from worker;
- fallback whole build to single-thread on any worker error;
- chunking by file count only.

Raise priority:

- WorkPlan;
- AbortSignal;
- backpressure;
- targetChunkBytes;
- result queue limits;
- stale result dropping;
- failure levels;
- determinism hash.

## Open Bugs To Track

```txt
V15-B001: worker pool can hide disk IO bottlenecks instead of fixing them.
V15-B002: worker-side stat duplicates planner IO.
V15-B003: file-count chunking can create load imbalance on large markdown files.
V15-B004: missing backpressure can inflate RAM on 100K files.
V15-B005: missing cancellation can publish stale results.
V15-B006: one worker failure should not force full single-thread rebuild.
V15-B007: parallel edge/warning order can become nondeterministic.
V15-B008: workers in warm trusted mode indicate planner failure.
```
