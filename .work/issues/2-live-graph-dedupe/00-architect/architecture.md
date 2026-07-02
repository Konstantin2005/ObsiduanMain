# Architecture - Issue #2: Live Graph Canonical Code

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CANONICAL LIVE GRAPH                         │
│                  Technical/Scripts/Rendering/                   │
│                         live-graph/                             │
├─────────────────────────────────────────────────────────────────┤
│  core/                     │  governors/         │  workers/    │
│  ├─ live-graph-core.js     │  ├─ graph-governors │  ├─ worker-  │
│  ├─ graph-scheduler.js     │  ├─ throughput-gov  │  │  layer.js  │
│  └─ builtin-graph.js       │  └─ evidence-engine │  └─ query-   │
│                            │                     │     engine.js│
├─────────────────────────────────────────────────────────────────┤
│  rendering/                │  storage/           │  index.js    │
│  ├─ multiscale.js          │  ├─ shard-store.js  │  (barrel)    │
│  └─ canvas-renderer.js     │  ├─ manifest.js         │              │
└─────────────────────────────────────────────────────────────────┘
```

## Module Responsibilities

### Core Layer (`core/`)
| Module | Responsibility | Exports |
|--------|---------------|---------|
| `live-graph-core.js` | Main entry point, orchestrates render loop, manages lifecycle | `LiveGraphCore`, `createLiveGraph()` |
| `graph-scheduler.js` | Frame scheduling, priority lanes, capacity leases | `GraphScheduler`, `FrameBudget` |
| `builtin-graph.js` | Built-in graph types (people, concepts, tasks) | `BuiltinGraphRegistry`, `GraphType` |

### Governors Layer (`governors/`)
| Module | Responsibility | Exports |
|--------|---------------|---------|
| `graph-governors.js` | Base governor classes, degradation policies | `Governor`, `DegradationPolicy` |
| `graph-throughput-governor.js` | CPU/throughput load control | `ThroughputGovernor` |
| `graph-evidence-engine.js` | Evidence-based rendering decisions | `EvidenceEngine` |

### Workers Layer (`workers/`)
| Module | Responsibility | Exports |
|--------|---------------|---------|
| `graph-worker-layer.js` | Worker pool management, task distribution | `WorkerLayer`, `TaskQueue` |
| `graph-query-engine.js` | Query parsing, planning, execution | `QueryEngine`, `QueryPlan` |

### Rendering Layer (`rendering/`)
| Module | Responsibility | Exports |
|--------|---------------|---------|
| `graph-multiscale.js` | Multi-scale rendering, LOD management | `MultiScaleRenderer` |
| `graph-canvas-renderer.js` | Canvas/WebGL rendering primitives | `CanvasRenderer` |

### Storage Layer (`storage/`)
| Module | Responsibility | Exports |
|--------|---------------|---------|
| `shard-store.js` | Sharded graph storage, compaction | `ShardStore` |
| `manifest.js` | Manifest recovery, integrity checks | `ManifestManager` |

## API Contract

### Public Interface (`index.js`)
```javascript
// Main entry point
export {
  // Core
  LiveGraphCore,
  createLiveGraph,
  GraphScheduler,
  FrameBudget,
  
  // Graph Types
  BuiltinGraphRegistry,
  GraphType,
  
  // Governors
  Governor,
  ThroughputGovernor,
  EvidenceEngine,
  DegradationPolicy,
  
  // Workers
  WorkerLayer,
  TaskQueue,
  QueryEngine,
  QueryPlan,
  
  // Rendering
  MultiScaleRenderer,
  CanvasRenderer,
  
  // Storage
  ShardStore,
  ManifestManager,
  
  // Types
  GraphNode,
  GraphEdge,
  RenderPlan,
  Viewport,
} from './core/index.js';
```

## Data Flow

```
User Interaction → LiveGraphCore → GraphScheduler → FrameBudget
                                                      ↓
                    ┌─────────────────────────────────┼─────────────┐
                    ▼                                 ▼             ▼
              WorkerLayer                      Governors        Rendering
              ├─ QueryEngine                  ├─ Throughput    ├─ MultiScale
              └─ TaskQueue                    └─ Evidence      └─ Canvas
                    │                                 │             │
                    └─────────────────────────────────┼─────────────┘
                                                      ▼
                                              Storage Layer
                                              ├─ ShardStore
                                              └─ Manifest
```

## Configuration

### Runtime Config (`live-graph.config.json`)
```json
{
  "scheduler": {
    "targetFPS": 60,
    "frameBudgetMs": 16.67,
    "priorityLanes": ["critical", "high", "normal", "low"]
  },
  "governors": {
    "throughput": {
      "maxNodesPerFrame": 5000,
      "maxEdgesPerFrame": 10000,
      "degradationThreshold": 0.8
    },
    "evidence": {
      "minConfidence": 0.7,
      "maxHypotheses": 100
    }
  },
  "workers": {
    "poolSize": "auto",
    "maxConcurrentTasks": 8,
    "taskTimeoutMs": 5000
  },
  "rendering": {
    "useWebGL": true,
    "fallbackToCanvas": true,
    "maxRenderNodes": 50000
  },
  "storage": {
    "shardSize": 10000,
    "compactionIntervalMs": 300000,
    "manifestBackupCount": 3
  }
}
```

## Vault Integration Points

Each vault (Algoritm, Calendula, Obs, Zetl, Angl, Technical) imports via:
```javascript
// Vault-specific config override
import { createLiveGraph } from 'Technical/Scripts/Rendering/live-graph';

const graph = createLiveGraph({
  vaultName: 'Algoritm',
  config: require('./vault-config.json'),
  plugins: [/* vault-specific plugins */]
});
```

## Migration Strategy

### Before (Duplicated)
```
Algoritm/.obsidian/plugins/live-graph/live-graph-core.js
Calendula/.obsidian/plugins/live-graph/live-graph-core.js
Obs/.obsidian/plugins/live-graph/live-graph-core.js
Zetl/.obsidian/plugins/live-graph/live-graph-core.js
Angl/.obsidian/plugins/live-graph/live-graph-core.js
Technical/Scripts/Rendering/live-graph/live-graph-core.js  ← CANONICAL
```

### After (Unified)
```
Technical/Scripts/Rendering/live-graph/          ← SINGLE SOURCE
├── core/
├── governors/
├── workers/
├── rendering/
├── storage/
├── index.js
└── live-graph.config.json

Each vault:
.vault-config.json  →  references canonical + vault overrides
```

## Cross-References
- **Issue #11** (Worker Pool): Uses `graph-worker-layer.js` from canonical
- **Issue #12** (Layout Cache): Uses `storage/shard-store.js` from canonical
- **Issue #35** (Multi-vault Sync): Canonical enables unified graph index
- **Issue #8** (Discord Sync): Notifications via canonical governors