# Engineering Blueprint 2026 — Simplified

**Version:** 3.0.0 (Simplified)

---

## Branch Structure

```
main         # stable, reviewed content
develop      # daily work, auto-commits
feature/*    # focused work
ai/*         # AI agent branches
snapshot/*   # auto-created every 6 hours (tags only)
```

## Rules

- `main`: no direct push, PR only, signed commits
- `develop`: PR merge from feature/* and ai/*
- `feature/*`, `ai/*`: free push, auto-clean after 14 days
- `snapshot/*`: tags only, auto-prune after 90 days

## Automation (cron)

```bash
# Auto-save every 15 min on feature/*, ai/*, develop
*/15 * * * * cd /repo && BRANCH=$(git rev-parse --abbrev-ref HEAD) && case $BRANCH in feature/*|ai/*|develop) git add -A && git diff --cached --quiet || git commit -m "chore(vault): auto-save $(date)" && git push ;; esac

# Snapshot every 6 hours
0 */6 * * * cd /repo && git tag snapshot/$(date +%Y-%m-%d-%H%M) && git push --tags

# Weekly GC
0 3 * * 0 cd /repo && git gc --aggressive
```

## Git Hooks

- `pre-commit`: validate Conventional Commits
- `pre-push`: block pushes to main

## Commit Format

```
type(scope): description

feat:     new feature
fix:      bug fix
refactor: code restructuring
docs:     documentation
chore:    maintenance
```

## Quick Reference

```bash
git checkout -b feature/123-add-auth develop
git commit -m "feat(auth): add SSO login"
git checkout -b ai/gpt5/refactor-cache develop
git commit -m "chore(ai): auto-save checkpoint"
```

## ADR Log

| # | Decision | Status |
|---|----------|--------|
| 001 | Monorepo | Accepted |
| 002 | Trunk-Based Development | Accepted |
