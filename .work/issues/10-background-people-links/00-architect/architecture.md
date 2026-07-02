# Architecture: Background People Links

## System Overview
```
[Vault Load] → [Foreground: Graph Store] ←→ [PeopleLinkCache]
                      ↓                            ↑
              [Background Worker] ──────────────────┘
                      ↓
            [PeopleLinkGenerator]
                      ↓
            [PeopleLinkGraph] (result)
```

## Components

### 1. PeopleLinkGenerator
- Scans notes for people mentions (via `@mention` or `[[person]]` patterns)
- Resolves aliases using `PeopleRegistry`
- Computes co-occurrence metrics between people
- Produces `PeopleLinkGraph` with weighted edges

### 2. PeopleLinkCache
- Key: `people-links:{manifestHash}:{configVersion}`
- Value: serialized `PeopleLinkGraph`
- Storage: IndexedDB / local file cache
- Invalidation: on note changes that affect people links

### 3. BackgroundWorker
- Runs `PeopleLinkGenerator` off the main thread
- Accepts `LinkGenerationTask` from queue
- Posts results back to main thread
- Handles cancellation (if newer task supersedes)

### 4. LinkGenerationTask
```typescript
interface LinkGenerationTask {
  taskId: string;
  vaultId: string;
  manifestHash: string;
  configVersion: number;
  changedNotes?: string[];  // incremental update if available
  priority: 'foreground' | 'background';
  timestamp: number;
}
```

## Data Flow
1. Vault loads → foreground requests people links from cache
2. Cache miss → foreground returns empty graph immediately + enqueues generation task
3. BackgroundWorker picks up task, runs PeopleLinkGenerator
4. Generator reads all notes, extracts mentions, computes co-occurrence
5. Result is cached → foreground notified → UI updates with links
6. On note edit → cache invalidated → re-generation scheduled (debounced 2s)

## PeopleLinkGraph Structure
```typescript
interface PeopleLinkGraph {
  version: number;
  generatedAt: number;
  manifestHash: string;
  nodes: Map<string, PersonNode>;
  edges: PeopleEdge[];
}

interface PeopleEdge {
  sourceId: string;
  targetId: string;
  weight: number;      // co-occurrence frequency
  contexts: string[];  // note IDs where co-occurrence found
}
```
