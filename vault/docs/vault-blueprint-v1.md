# Vault Blueprint v1.0 — Obsidian + AI Agents

**Goal:** One person maintains this vault for 5+ years with multiple AI agents.
**Philosophy:** Markdown files, git branches, and built-in tools. No daemons, no Kubernetes, no Prometheus.

---

## Branch Structure

```
main         # reviewed, stable notes
develop      # daily work, auto-saved
feature/*    # focused work on a topic
ai/*         # AI agent work
```

Example:
```
ai/gpt5/research-rag
ai/claude/rewrite-blueprint
ai/gemini/book-summary
feature/obsidian-templater-setup
```

## AI Merge Policy

| From | To | Who |
|------|----|-----|
| ai/* | develop | Human reviews then merges |
| feature/* | develop | Human merges |
| develop | main | Human merges (when stable) |

AI never writes to `develop` or `main`.

## Automation

### Auto-commit (every 60 min, only when meaningful)

```bash
0 * * * * cd /repo && BRANCH=$(git rev-parse --abbrev-ref HEAD) && case $BRANCH in feature/*|ai/*|develop) CHANGED=$(git diff --cached --numstat | wc -l) && FILES=$(git diff --cached --name-only | wc -l) && if [ "$FILES" -ge 3 ] || [ "$CHANGED" -ge 30 ]; then git add -A && git commit -m "chore(vault): auto-save $(date)" && git push; fi ;; esac
```

Threshold: >= 3 files changed OR >= 30 lines changed.

### Snapshot (every 6 hours, tags only)

```bash
0 */6 * * * cd /repo && git tag snapshot-$(date +%Y-%m-%d-%H%M) && git push --tags
```

Format: `snapshot-2026-06-24-1800` (no snapshot branches, only tags).

### Weekly GC

```bash
0 3 * * 0 cd /repo && git gc --aggressive
```

---

## Vault Directory Layout

```
vault/
├── inbox/          # quick capture, fleeting notes
├── note/           # permanent notes, zettelkasten
├── project/        # per-project folders
├── research/       # research notes, sources
├── ai/
│   ├── gpt5/       # GPT-5 generated notes
│   ├── claude/     # Claude generated notes
│   ├── gemini/     # Gemini generated notes
│   └── archive/    # stale AI notes
├── adr/            # Architecture Decision Records
├── template/       # Obsidian templates
├── log/            # daily logs, work log
│   └── activity.md
└── meta/           # vault config, indexes, MOCs
    └── index.md
```

### Directory Purpose

| Directory | Purpose | Git Branch |
|-----------|---------|-----------|
| `inbox/` | Fleeting notes, capture | develop |
| `note/` | Permanent notes | develop |
| `project/` | Active projects | feature/* |
| `research/` | Research and sources | feature/* or ai/* |
| `ai/<agent>/` | AI-generated content | ai/<agent>/<topic> |
| `adr/` | Architecture decisions | develop |
| `template/` | Obsidian templates | develop |
| `log/` | Daily activity log | develop |
| `meta/` | Indexes, MOCs, config | develop |

---

## Activity Log

Simple file: `vault/log/activity.md`

Updated manually or by AI during session.

```markdown
# Activity Log

## 2026-06-24

- [gpt5] Research RAG patterns → ai/gpt5/research-rag/
- [human] Clean inbox → processed 12 notes
- [claude] Rewrite blueprint → ai/claude/rewrite-blueprint/

## 2026-06-23

- [gemini] Book summary → ai/gemini/book-summary/
- [human] Weekly review → moved projects
```

Not automated. Not a git journal. Just a log.

---

## Snapshot Naming

```
snapshot-2026-06-24-1800
snapshot-2026-06-25-0000
snapshot-2026-06-25-0600
```

Tags only, no branches. Retention: 90 days.

---

## Git Hooks

### pre-commit (warn only)

```bash
#!/bin/bash
MSG=$(git log -1 --format="%s" 2>/dev/null || echo "")
REGEX='^(feat|fix|refactor|perf|test|docs|ci|build|chore|revert)(\(.+\))?:\s.+'
if ! echo "$MSG" | grep -qE "$REGEX" && [ -n "$MSG" ]; then
  echo "[vault] Tip: use Conventional Commits (type(scope): desc)"
fi
exit 0
```

### pre-push (warn only)

```bash
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
  echo "[vault] Pushing to main. Consider merging via PR."
fi
exit 0
```

---

## Quick Start

```bash
# New feature
git checkout -b feature/obsidian-templater develop
# work...
git add -A && git commit -m "feat(templates): add daily note template"
git push

# AI task
git checkout -b ai/gpt5/research-rag develop
# AI works...
# auto-commit saves progress every 60 min

# Human review
git checkout develop
git merge ai/gpt5/research-rag
git push

# Release to main
git checkout main
git merge develop
git push
```

---

## What We Removed

Prometheus, OpenTelemetry, Loki, Tempo, Pyroscope, systemd, health endpoints, metrics server, Service Tiering, SLO, Error Budgets, SEV-0/1/2, GitOps, ArgoCD, Canary, Blue-Green, CD Pipeline, Database Evolution, API Compatibility, Production Readiness Review, DAAF Python daemons, release/hotfix/support/legacy branches, snapshot branches.

**Reduction:** ~95% of original blueprint removed.
