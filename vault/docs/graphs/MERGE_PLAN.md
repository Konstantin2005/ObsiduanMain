---
type: Plan
title: "Small Graph Merge Plan"
created: 2026-06-25
---

# 📦 Small Graph Merge Plan

> Merging 12 small graphs (<100 nodes each) into 3 thematic super-graphs.
> Total: 364 nodes → organized into GameSystem, LifeSystem, PsychologyGraph.

---

## 1. Rationale

### Problems with Current State

- **Scattered**: 12 tiny graphs pollute the top-level namespace
- **Isolated**: No cross-links between related small graphs
- **No shared infrastructure**: Each lacks generate.py, validation, exports
- **Hard to navigate**: Too many separate MOCs for small collections

### Benefits of Merging

- **Coherence**: Related content lives together
- **Shared tooling**: One generate.py per super-graph
- **Cross-linking**: Internal links within super-graph are automatic
- **Simplified navigation**: One MOC instead of 4-5
- **Better discovery**: Related concepts are physically adjacent

---

## 2. Super-Graph Definitions

### 2.1 GameSystem (164 nodes)

**Target path:** `Zetl/GameSystem/`

**Source graphs and node counts:**

| Source | Nodes | Target Subdirectory |
|--------|-------|-------------------|
| Zetl/SmallGraphs2/Quests/ | 55 | GameSystem/Quests/ |
| Zetl/SmallGraphs2/Bosses/ | 21 | GameSystem/Bosses/ |
| Zetl/SmallGraphs2/Obstacles/ | 31 | GameSystem/Obstacles/ |
| Zetl/SmallGraphs2/Rewards/ | 17 | GameSystem/Rewards/ |
| Zetl/SmallGraphs2/Skills/ (part) | 20 | GameSystem/Skills/ |
| Zetl/Quests/ | 20 | GameSystem/Quests/ |

**Node Types:** Quest, Boss, Obstacle, Reward, Skill, Level, Achievement, Challenge

**Link Types:** requires, unlocks, defeats, blocks, rewards, develops, overcomes

**MOC:** `MOC - GameSystem.md` — table of all quests, bosses, rewards progression

```
GameSystem/
├── Quests/          # All quests (merged from SmallGraphs2 + Quests)
├── Bosses/          # All bosses
├── Obstacles/       # All obstacles
├── Rewards/         # All rewards
├── Skills/          # Skills relevant to game system
├── MOC - GameSystem.md
├── Navigation.md
└── generate.py
```

### 2.2 LifeSystem (88 nodes)

**Target path:** `Zetl/LifeSystem/`

**Source graphs and node counts:**

| Source | Nodes | Target Subdirectory |
|--------|-------|-------------------|
| Zetl/SmallGraphs2/Concepts/ (life) | 10 | LifeSystem/Concepts/ |
| Zetl/PersonalityGraph/Habits/ | 25 | LifeSystem/Habits/ |
| Zetl/PersonalityGraph/Goals/ | 22 | LifeSystem/Goals/ |
| Zetl/PersonalityGraph/Values/ (life) | 15 | LifeSystem/Values/ |
| Zetl/SmallGraphs1/Values/ (life) | 16 | LifeSystem/Values/ |

**Node Types:** Skill, Habit, Goal, Value, Milestone, Routine

**Link Types:** develops, requires, measures, tracks, enables, supports

**MOC:** `MOC - LifeSystem.md` — personal growth tracking

```
LifeSystem/
├── Habits/          # Habits (from PersonalityGraph)
├── Goals/           # Goals (from PersonalityGraph)
├── Skills/          # Life skills
├── Values/          # Life values (merged from multiple sources)
├── Milestones/      # Life milestones
├── MOC - LifeSystem.md
├── Navigation.md
└── generate.py
```

### 2.3 PsychologyGraph (152 nodes)

**Target path:** `Zetl/PsychologyGraph/`

**Source graphs and node counts:**

| Source | Nodes | Target Subdirectory |
|--------|-------|-------------------|
| Zetl/PersonalityGraph/Emotions/ | 40 | PsychologyGraph/Emotions/ |
| Zetl/PersonalityGraph/Traits/ | 30 | PsychologyGraph/Traits/ |
| Zetl/PersonalityGraph/Fears/ | 30 | PsychologyGraph/Fears/ |
| Zetl/PersonalityGraph/Desires/ | 22 | PsychologyGraph/Desires/ |
| Zetl/PersonalityGraph/Values/ (psych) | 30 | PsychologyGraph/Values/ |

**Node Types:** Emotion, Trait, Fear, Desire, Value, Archetype, Pattern, Mechanism

**Link Types:** expresses, suppresses, triggers, conflicts_with, reinforces, compensates

**MOC:** `MOC - PsychologyGraph.md` — comprehensive psychology reference

```
PsychologyGraph/
├── Emotions/        # Emotions (from PersonalityGraph)
├── Traits/          # Personality traits
├── Fears/           # Fears and anxieties
├── Desires/         # Desires and motivations
├── Values/          # Personal values
├── Archetypes/      # Psychological archetypes
├── MOC - PsychologyGraph.md
├── Navigation.md
└── generate.py
```

---

## 3. Migration Procedure

### Phase 1: Create Structure

```bash
# Create super-graph directories
mkdir -p Zetl/GameSystem/{Quests,Bosses,Obstacles,Rewards,Skills}
mkdir -p Zetl/LifeSystem/{Habits,Goals,Skills,Values,Milestones}
mkdir -p Zetl/PsychologyGraph/{Emotions,Traits,Fears,Desires,Values,Archetypes}
```

### Phase 2: Copy Notes

```bash
# GameSystem
cp Zetl/SmallGraphs2/Quests/*.md Zetl/GameSystem/Quests/
cp Zetl/SmallGraphs2/Bosses/*.md Zetl/GameSystem/Bosses/
cp Zetl/SmallGraphs2/Obstacles/*.md Zetl/GameSystem/Obstacles/
cp Zetl/SmallGraphs2/Rewards/*.md Zetl/GameSystem/Rewards/
cp Zetl/Quests/*.md Zetl/GameSystem/Quests/

# LifeSystem
cp Zetl/PersonalityGraph/Habits/*.md Zetl/LifeSystem/Habits/
cp Zetl/PersonalityGraph/Goals/*.md Zetl/LifeSystem/Goals/

# PsychologyGraph
cp Zetl/PersonalityGraph/Emotions/*.md Zetl/PsychologyGraph/Emotions/
cp Zetl/PersonalityGraph/Traits/*.md Zetl/PsychologyGraph/Traits/
cp Zetl/PersonalityGraph/Fears/*.md Zetl/PsychologyGraph/Fears/
cp Zetl/PersonalityGraph/Desires/*.md Zetl/PsychologyGraph/Desires/
```

### Phase 3: Update Frontmatter

Each copied note needs updated frontmatter:
- `graph:` field updated to new super-graph name
- Internal links updated if paths changed

### Phase 4: Create Super-Graph Infrastructure

```python
# generate.py for each super-graph with:
# - Standard CLI interface
# - Config-driven definitions
# - Validation step

# MOC - <SuperGraph>.md
# Navigation.md
# Cross-graph links to related graphs
```

### Phase 5: Update Registry

Add to `graph_common.py`:
```python
"GameSystem": {
    "path": ZETL / "GameSystem",
    "subdirs": ["Quests", "Bosses", "Obstacles", "Rewards", "Skills"],
    "node_types": ["Quest", "Boss", "Obstacle", "Reward", "Skill"],
    "link_types": ["requires", "unlocks", "defeats", "blocks", "rewards"],
},
```

### Phase 6: Update Indexes

- Update `MOC - All Graphs.md` — replace small entries with super-graphs
- Update `MOC - Zetl.md` — add super-graph links
- Add cross-graph links between super-graphs

---

## 4. Cross-Super-Graph Links

| Source | Target | Connection |
|--------|--------|------------|
| GameSystem/Quests | PsychologyGraph/Traits | "Quest requires specific traits" |
| LifeSystem/Goals | PsychologyGraph/Fears | "Fear blocks goal pursuit" |
| PsychologyGraph/Values | LifeSystem/Values | "Personal values guide goals" |
| GameSystem/Rewards | LifeSystem/Goals | "Rewards align with goals" |

---

## 5. Timeline

| Step | Effort | Dependencies |
|------|--------|-------------|
| Create directories | 30 min | None |
| Copy notes | 1 hour | Directories created |
| Update frontmatter | 2 hours | Notes copied |
| Create generate.py | 3 hours | Registry updated |
| Create MOCs | 1 hour | Directory structure ready |
| Update indexes | 1 hour | MOCs created |
| Validate | 30 min | All changes applied |
| **Total** | **~9 hours** | — |

---

## 6. Rollback Plan

If merge causes issues:
1. Each super-graph is a copy, not a move — originals remain
2. Revert registry changes in git
3. Re-run old generate.py scripts
4. Restore `MOC - All Graphs.md` from git

> [!warning] Data Safety
> The merge uses COPY, not MOVE. Original small graph directories remain intact until fully verified.
