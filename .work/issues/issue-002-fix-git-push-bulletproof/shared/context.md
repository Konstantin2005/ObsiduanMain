# Context

**Issue**: Git push system keeps falling - need bulletproof solution
**Status**: BACKEND_IMPLEMENTATION
**Created**: 2026-07-16

## Problem
Current git-worker.ps1 and core.ps1 have multiple failure points:
1. SSH-only push fails from Task Scheduler (no SSH agent)
2. Stale index.lock blocks all operations
3. gh push command doesn't exist in modern gh CLI
4. No fetch/pull before push → rejection
5. No self-healing before operations

## Solution
Replace with git-push-bulletproof.ps1:
- Self-healing pre-flight checks
- 3-layer auth: HTTPS → SSH → gh token
- fetch + pull --rebase before push
- Comprehensive logging
- Idempotent, non-interactive
