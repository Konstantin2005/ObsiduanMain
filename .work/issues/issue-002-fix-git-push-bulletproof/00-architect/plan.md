# Plan: Bulletproof Git Push System

## Problem
The existing git push system (`git-worker.ps1`, `auto-commit.ps1`) routinely fails because:
1. SSH agent is not running from Task Scheduler (non-interactive) → SSH push fails
2. `index.lock` stale files block git operations
3. No `fetch`/`pull` before `push` → remote divergence causes rejection
4. `gh push` command doesn't exist (bug in core.ps1)
5. No credential validation before operations
6. No self-healing before each operation

## Solution
Create a new `git-push-bulletproof.ps1` with:
1. **Pre-flight self-healing**: Fix locks, rebase, stale processes before any operation
2. **3-layer auth push**: HTTPS+token → SSH → gh CLI (each independent)
3. **Auto fetch+rebase**: Always sync before push
4. **Comprehensive error handling**: Every failure caught, logged, and recovered
5. **Idempotent**: Safe to run any number of times
6. **Non-interactive**: All operations work without user input

## Files to Create/Modify
1. **NEW**: `Technical/Scripts/Git/git-push-bulletproof.ps1` — Main script
2. **NEW**: `Technical/Scripts/system/core-v3.ps1` — Updated shared module
3. **MODIFY**: `vault/git-worker.ps1` — Delegate to new system
