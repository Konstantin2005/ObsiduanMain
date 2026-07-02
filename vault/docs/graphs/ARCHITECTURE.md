---
type: Architecture
title: "Unified Graph Platform Architecture"
created: 2026-06-25
---

# 🏗️ Unified Graph Platform Architecture

> Architectural design for the complete knowledge graph system.
> Scope: All 20+ graphs, shared infrastructure, cross-graph integration.

---

## 1. System Overview

### Vision

A unified platform where all knowledge graphs coexist, share infrastructure,
and interconnect through standardized interfaces — enabling cross-graph
navigation, analysis, and evolution at scale.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GRAPH PLATFORM LAYERS                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    PRESENTATION LAYER                      │  │
│  │  Obsidian Vault  │  Graph View  │  Exports (GraphML/...) │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              ↕                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   GRAPH ENGINE LAYER                       │  │
│  │  generate.py  │  validate.py  │  graph_links.py           │  │
│  │  export.py    │  organize.py  │  graph_common.py          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              ↕                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    DATA LAYER                              │  │
│  │  Individual Graphs  │  Cross-Graph Index  │  Registry     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Architecture

### 2.1 Data Layer

**Components:**
- **Individual Graphs**: Self-contained Obsidian note collections under `Zetl/<GraphName>/`
- **Cross-Graph Index**: `Zetl/GraphLinks/GraphLinks.md` — master registry of all inter-graph connections
- **Graph Registry**: `Zetl/lib/graph_common.py` — Python dict defining all graphs, their paths, types, and link schemas
- **Export Store**: `Zetl/export/<GraphName>/` — generated GraphML, JSON, DOT, CSV files

**Source of Truth:**
- Primary: Individual `.md` files in each graph directory
- Secondary: Registry configuration in `graph_common.py`
- Generated: Export files (reproducible from source)

### 2.2 Graph Engine Layer

**Components:**

| Module | Purpose |
|--------|---------|
| `graph_common.py` | Shared library — types, registry, stats, utilities |
| `generate.py` (per graph) | Node/link generation with standardized CLI |
| `validate_graph.py` | Integrity checks, orphan/broken-link detection |
| `graph_links.py` | Cross-graph link creation and maintenance |
| `export_graph.py` | Multi-format export (GraphML, JSON, DOT, CSV) |
| `organize.py` | Content distribution across graph structure |

**Key Design Decisions:**
- CLI interface: `--output <dir> --format <md|json|graphml>`
- Config-driven: YAML/JSON graph definitions in registry
- Cross-platform: Pure Python, no OS-specific dependencies

### 2.3 Presentation Layer

**Components:**
- **Obsidian Vault**: Primary interface for human interaction
- **Local Graph View**: Obsidian native graph visualization
- **Exported Formats**: External tools (Gephi, D3.js, GraphViz)

---

## 3. Graph Classification

### Tier 1: Core Graphs (>500 nodes)
| Graph | Nodes | Role |
|-------|-------|------|
| KnowledgeGraphs | 5193 | Zettelkasten foundation |
| DecisionMakingGraph | 1993 | Decision analysis |
| KnowledgeGalaxy | 1827 | Knowledge synthesis |
| Knowledge | 1205 | Knowledge base |
| DecisionMaze | 949 | Decision alternatives |
| QuestionFractal | 647 | Question decomposition |

### Tier 2: Domain Graphs (100-500 nodes)
| Graph | Nodes | Role |
|-------|-------|------|
| PersonalityGraph | 310 | Self-modeling |
| BiasGraph | 267 | Cognitive bias mapping |
| IdeaEcosystem | 260 | Idea evolution |
| ConflictGraph | 260 | Value conflicts |
| ShadowValueSystem | 257 | Shadow work |
| IntellectualNetwork | 172 | Thinker/idea network |
| CausalLoop | 158 | Causal reasoning |
| WorldModelGraph | 136 | World models |

### Tier 3: Small Graphs (<100 nodes)
| Graph | Nodes | Target Super-Graph |
|-------|-------|-------------------|
| GameSystem | 80 | GameSystem |
| Emotions | 40 | PsychologyGraph |
| Traits | 30 | PsychologyGraph |
| Fears | 30 | PsychologyGraph |
| Skills | 41 | LifeSystem |
| Habits | 25 | LifeSystem |
| Goals | 22 | LifeSystem |
| Desires | 22 | PsychologyGraph |
| Values | 22 | LifeSystem |

---

## 4. Cross-Graph Integration

### Link Types Between Graphs

| Type | Description | Example |
|------|-------------|---------|
| **Semantic** | Conceptually related nodes | Question → Bias |
| **Causal** | Cause-effect relationships | Decision → Outcome |
| **Hierarchical** | Parent-child structures | Graph → Subgraph |
| **Evolutionary** | Temporal/transformative | Idea → Mutation |
| **Reflective** | Mirror/shadow relationships | Value → Shadow |

### Cross-Graph Navigation Flow

```
QuestionFractal → PersonalityGraph → BiasGraph → DecisionMakingGraph
      ↓                  ↓               ↓               ↓
  "What biases    "Traits that      "How biases     "Decisions to
   affect my       shape my          distort my       correct for
   decisions?"     biases"           thinking"        biases"
```

---

## 5. Standardized Interfaces

### 5.1 Common CLI for generate.py

```bash
python generate.py --output <dir> --format <md|json|graphml>
```

All graph generators must support:
- `--output DIR` — output directory
- `--format FMT` — output format (default: md)
- `--config FILE` — YAML/JSON config
- `--validate` — run validation after generation
- `--seed N` — random seed for reproducibility

### 5.2 Graph Registry Schema

```python
{
    "GraphName": {
        "path": "Zetl/GraphName",
        "subdirs": ["Subdir1", "Subdir2"],
        "node_types": ["Type1", "Type2"],
        "link_types": ["link1", "link2"],
    }
}
```

### 5.3 Validation Schema

All graphs must pass:
1. No orphan nodes (0 outgoing links)
2. No broken internal links
3. No duplicate node IDs
4. Valid frontmatter (type, title required)
5. Bidirectional link consistency
6. Size limits respected (<1000 nodes or sharded)

---

## 6. Export Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│ MD Files │───▶│ Parser   │───▶│ Export   │
│ (Source) │    │ (Python) │    │ (Target) │
└──────────┘    └──────────┘    └──────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
              ┌──────────┐     ┌──────────┐     ┌──────────┐
              │ GraphML  │     │  JSON    │     │   DOT    │
              │ (Gephi)  │     │  (D3.js) │     │(GraphViz)│
              └──────────┘     └──────────┘     └──────────┘
```

---

## 7. Migration Plan

### Phase 1: Foundation (Current)
- ✅ Graph registry defined
- ✅ Shared library created (`graph_common.py`)
- ✅ Validation system designed (`validate_graph.py`)
- ✅ Cross-graph link system designed (`graph_links.py`)
- ✅ Export system designed (`export_graph.py`)

### Phase 2: Standardization (Next)
- [ ] Convert all `.ps1` generators to `.py` with common CLI
- [ ] Run validation on all graphs and fix issues
- [ ] Create cross-graph link files for all pairs
- [ ] Export all graphs to all formats
- [ ] Generate documentation for all Tier 1-2 graphs

### Phase 3: Integration (Future)
- [ ] CI/CD pipeline for automated validation
- [ ] Auto-fix common validation issues
- [ ] Live graph view with cross-graph rendering
- [ ] Performance optimization for 50K+ nodes
- [ ] Incremental graph updates

---

## 8. File Structure

```
Zetl/
├── lib/
│   ├── graph_common.py          # Shared library
│   └── graph_links.py           # Cross-graph link system
├── validation/
│   └── validate_graph.py        # Validation & integrity
├── export/
│   ├── export_graph.py          # Multi-format export
│   └── EXPORT_INDEX.md          # Export registry
├── GraphLinks/
│   ├── GraphLinks.md            # Master link index
│   └── <GraphA>_to_<GraphB>.md  # Per-pair link docs
├── <Graph1>/                    # Individual graphs
├── <Graph2>/
└── ...

docs/
└── graphs/
    ├── ARCHITECTURE.md          # This document
    ├── TEMPLATE.md              # Documentation template
    ├── MERGE_PLAN.md            # Small graph merge plan
    ├── QuestionFractal.md       # Per-graph docs
    ├── PersonalityGraph.md
    └── ...
```

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Broken links during migration | Medium | Validate before/after each move |
| Duplicate content across graphs | Low | Hash-based dedup in validation |
| Performance at scale | High | Shard graphs >1000 nodes |
| Cross-graph link rot | Medium | Automated link checking in CI |
| Generator output mismatch | Low | Standardized CLI + config |

---

## 10. ADR (Architecture Decision Records)

### ADR-001: Python over PowerShell
**Status:** Accepted
**Context:** Need cross-platform graph generation
**Decision:** Standardize on Python 3 for all generators
**Consequences:** All `.ps1` files will be migrated to `.py`

### ADR-002: Registry over Convention
**Status:** Accepted
**Context:** Need reliable enumeration of all graphs
**Decision:** Central registry dict in `graph_common.py` instead of filesystem scanning
**Consequences:** Adding a new graph requires registry update

### ADR-003: Source of Truth = Markdown Files
**Status:** Accepted
**Context:** Need primary data format that works with Obsidian
**Decision:** `.md` files are the single source of truth; all exports are generated
**Consequences:** Export files are reproducible, never hand-edited
