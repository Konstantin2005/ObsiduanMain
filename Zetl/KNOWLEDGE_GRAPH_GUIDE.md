# Knowledge Graph Architecture - Daily Usage Guide

## Overview

This is a scalable knowledge graph system designed for Obsidian, optimized for 1000+ notes. It uses a minimal set of note types with flexible relationships.

## Core Note Types

### Topic (Domain)
**Purpose**: High-level categories for organizing knowledge
**File Location**: `Knowledge/Topics/`
**YAML Properties**:
- `type: topic`
- `priority: [high/medium/low]`
- `status: [active/archived]`
- `created: [date]`
- `last_reviewed: [date]`
- `review_frequency: [daily/weekly/monthly/quarterly]`

**When to Use**:
- When you need a high-level category for organizing related concepts
- When you want to group related ideas together
- When you need a reference point for related knowledge

**When NOT to Use**:
- When you need to store specific ideas or theories
- When you want to store personal principles or beliefs

**Example**: `AI_Overview_v1.md`

### Concept (Idea)
**Purpose**: Specific ideas, theories, or insights
**File Location**: `Knowledge/Concepts/`
**YAML Properties**:
- `type: concept`
- `topic: [related topic]`
- `source: [where learned]`
- `confidence: [high/medium/low]`
- `status: [active/archived]`
- `created: [date]`
- `last_reviewed: [date]`
- `review_frequency: [daily/weekly/monthly/quarterly]`
- `tags: [tag1, tag2, tag3]`
- `references: [url1, url2]`

**When to Use**:
- When you learn or discover a new idea or concept
- When you want to document a theory or insight
- When you need to store specific knowledge

**When NOT to Use**:
- When you need to store high-level categories
- When you want to store personal principles or beliefs

**Example**: `ML_NeuralNetworks_v1.md`

### Value (Belief)
**Purpose**: Principles or beliefs that guide decisions
**File Location**: `Knowledge/Values/`
**YAML Properties**:
- `type: value`
- `category: [life/personal/career/creative/social]`
- `priority: [high/medium/low]`
- `status: [active/archived]`
- `created: [date]`
- `last_reviewed: [date]`
- `review_frequency: [daily/weekly/monthly/quarterly]`
- `conflict_with: [value1, value2]`
- `supports: [value3, value4]`

**When to Use**:
- When you establish a personal or professional principle
- When you want to document what matters most to you
- When you need to guide decision-making

**When NOT to Use**:
- When you need to store specific ideas or theories
- When you want to organize knowledge into categories

**Example**: `Career_LearningContinuity.md`

### Project (Initiative)
**Purpose**: Active projects or initiatives that implement concepts
**File Location**: `Knowledge/Projects/`
**YAML Properties**:
- `type: project`
- `project: [project name]`
- `status: [active/archived/completed]`
- `created: [date]`
- `last_reviewed: [date]`
- `review_frequency: [daily/weekly/monthly/quarterly]`
- `tags: [tag1, tag2, tag3]`

**When to Use**:
- When you start an initiative to implement a concept
- When you want to track progress on a specific goal
- When you need to organize related tasks and resources

**When NOT to Use**:
- When you need to store specific ideas or theories
- When you want to store high-level categories

**Example**: `Project_MLResearch.md`

### MOC (Map of Content)
**Purpose**: Comprehensive overview of a Topic
**File Location**: `Knowledge/MOCs/`
**YAML Properties**:
- `type: moc`
- `topic: [related topic]`
- `status: [active/archived]`
- `created: [date]`
- `last_reviewed: [date]`
- `review_frequency: [monthly/quarterly]`

**When to Use**:
- When you need a comprehensive overview of a topic
- When you want to organize related concepts, values, and projects
- When you need a reference point for a specific domain

**When NOT to Use**:
- When you need to store specific ideas or theories
- When you want to track progress on a specific goal

**Example**: `AI_MOC.md`

## Naming Convention

**Format**: `[Type]_[Descriptor]_[Version?]`

**Examples**:
- `Topic`: `AI_Overview_v1`, `Productivity_Tips`
- `Concept`: `ML_NeuralNetworks_v2`, `Productivity_Pomodoro`
- `Value`: `Life_WorkLifeBalance`, `Career_LearningContinuity`
- `Project`: `Project_MLResearch`, `Project_ProductivityTools`
- `MOC`: `AI_MOC`, `Productivity_MOC`

## Linking Rules

### Mandatory Links (for new notes):
1. **Concept**: Must link to 1-3 related Concepts and 1 Topic
2. **Topic**: Must link to 2-3 related Concepts
3. **Value**: Must link to 1-2 related Values
4. **Project**: Must link to 1-2 related Concepts and 1 Value
5. **MOC**: Must link to 1-3 related Concepts, 1-2 Values, 1-2 Projects, and 1 Topic

### Linking Strategy:
- **Backward**: Link new knowledge to existing related notes
- **Forward**: Link existing notes to new knowledge when relevant
- **Cross-type**: Link Concepts to Values, Topics to Concepts, Projects to Concepts and Values

## Folder Structure

```
Knowledge/
├── Topics/          # Topic notes
│   ├── AI_Overview_v1.md
│   └── Productivity_Tips.md
├── Concepts/        # Concept notes
│   ├── ML_NeuralNetworks_v1.md
│   └── Productivity_Pomodoro.md
├── Values/          # Value notes
│   ├── Career_LearningContinuity.md
│   └── Life_WorkLifeBalance.md
├── Projects/        # Project notes
│   ├── Project_MLResearch.md
│   └── Project_ProductivityTools.md
├── MOCs/            # Maps of Content
│   ├── AI_MOC.md
│   └── Productivity_MOC.md
└── Archive/         # Archived notes
```

## Tag System

**Tag Format**: `#type/purpose`

**Examples**:
- `#topic/ai` - Topic tags
- `#concept/ml` - Concept tags
- `#value/learning` - Value tags
- `#project/mlresearch` - Project tags
- `#status/active` - Status tags
- `#priority/high` - Priority tags

## Quality Rules

### New Note Requirements:
1. **Concept**: Must have 1-3 Concept links and 1 Topic link
2. **Topic**: Must have 2-3 Concept links
3. **Value**: Must have 1-2 Value links
4. **Project**: Must have 1-2 Concept links and 1 Value link
5. **MOC**: Must have 1-3 Concept links, 1-2 Value links, 1-2 Project links, and 1 Topic link
6. **All types**: Must have at least one tag

### Link Distribution Guidelines:
- **Most notes**: 2-3 links (70% of notes)
- **Moderate notes**: 4-5 links (25% of notes)
- **High-density notes**: 6+ links (5% of notes)
- **No notes**: 0 links (avoid isolated nodes)

### Link Quality Guidelines:
- **Backward linking**: Link new knowledge to existing related notes
- **Forward linking**: Link existing notes to new knowledge when relevant
- **Cross-type linking**: Link Concepts to Values, Topics to Concepts, Projects to Concepts and Values

### Monthly Graph Review:
1. **Week 1**: Find notes with <2 links, connect them
2. **Week 2**: Review MOCs, add missing links
3. **Week 3**: Check for value conflicts, resolve if needed
4. **Week 4**: Clean up orphaned notes, archive outdated content

## Daily Usage Rules

### Rule 1: Start with Topics
- When you have new knowledge, first determine which Topic it belongs to
- Create a Topic note if it doesn't exist
- Link your new knowledge to the appropriate Topic

### Rule 2: Connect Concepts
- Every Concept must link to its parent Topic
- Every Concept must link to 1-3 related Concepts
- Use backlinks to find related concepts

### Rule 3: Define Values
- Every Concept should have related Values
- Values should link to related Concepts
- Check for value conflicts and resolve them

### Rule 4: Track Projects
- Every Concept can have related Projects
- Projects should link to related Concepts and Values
- Use the Progress section to track implementation status

### Rule 5: Create MOCs
- Every Topic should have a corresponding MOC
- MOCs should link to all related Concepts, Values, and Projects
- Use MOCs for high-level overviews

### Rule 6: Review Regularly
- Review notes based on their review_frequency
- Check for broken links and fix them
- Update outdated information

## Getting Started

1. Create your first Topic: `Knowledge/Topics/YourTopic_v1.md`
2. Add related Concepts: `Knowledge/Concepts/YourConcept_v1.md`
3. Define your Values: `Knowledge/Values/YourValue.md`
4. Create a Project: `Knowledge/Projects/YourProject.md`
5. Create a MOC for your Topic: `Knowledge/MOCs/YourTopic_MOC.md`
6. Link everything together!

## Search and Navigation

- Use Obsidian's graph view to visualize connections
- Use Dataview queries to filter by type, tags, or properties
- Use backlinks to find related notes
- Use the MOCs for high-level overviews
- Use the Project progress sections to track implementation status
