---
type: Documentation
title: "Graph Documentation Template"
---

# 📖 Graph Documentation Template

> Use this template to document each graph in the vault.

---

## 1. Overview

| Field | Value |
|-------|-------|
| **Graph Name** | `<!--- Graph name -->` |
| **Node Count** | `<!--- Count -->` |
| **Category** | `<!--- Zettelkasten / Analytics / Psychology / Ideas / Models / Game / Life -->` |
| **Status** | `<!--- Active / Draft / Archived -->` |

### Purpose

<!--- What problem does this graph solve? Why does it exist? -->

### Description

<!--- 2-3 paragraph description of the graph -->

---

## 2. Structure

### Node Types

| Type | Description | Count |
|------|-------------|-------|
| `<!--- type -->` | <!--- description --> | <!--- count --> |

### Link Types

| Type | Description |
|------|-------------|
| `<!--- link -->` | <!--- description --> |

### Subgraph Organization

| Subdirectory | Contents | Count |
|-------------|----------|-------|
| `<!--- dir -->` | <!--- contents --> | <!--- count --> |

---

## 3. Key Queries

<!--- Common questions this graph answers -->

- `<!--- Question 1 -->`
- `<!--- Question 2 -->`
- `<!--- Question 3 -->`

---

## 4. Extension Guide

### Adding a Node

```markdown
---
type: <NodeType>
title: "<Node Title>"
tags: [tag1, tag2]
---

# <Node Title>

## Description
<!--- description -->

## Related
- [[RelatedNode1]] — relationship description
- [[RelatedNode2]] — relationship description
```

### Adding a Link

Simply add a wikilink `[[TargetNode]]` in the note body.

### Best Practices

- Each node should have at least 2-3 outgoing links
- Use consistent node types from the schema
- Add bidirectional links where possible
- Keep descriptions concise but meaningful

---

## 5. Cross-Graph Links

| Target Graph | Link Type | Notes |
|-------------|-----------|-------|
| <!--- Graph --> | bidirectional | <!--- notes --> |

---

## 6. Examples

### Sample Traversal

```
<NodeA> → <NodeB> → <NodeC>
```

### Sample Analysis

<!--- Brief analysis example -->

---

## 7. Maintenance

- **Last validated:** `<!--- date -->`
- **Generator script:** `<!--- path -->`
- **Export formats:** GraphML / JSON / DOT / CSV
