# Test Cases — git-push-bulletproof

## TC01: DryRun mode (no side effects)
**Given**: repo with uncommitted changes + unpushed commits
**When**: `-DryRun` flag
**Then**: 
- No files are staged/committed
- No pushes happen
- All operations logged with [DRY-RUN] prefix
- Exit code 0

**Passed**: ✅ (Verified 2026-07-16)

## TC02: PushOnly mode (skip commit)
**Given**: repo with unpushed commits, no uncommitted changes
**When**: `-PushOnly` flag
**Then**:
- Commit step is skipped
- Sync step runs (fetch)
- Push step runs with 3-layer fallback
- At least one layer succeeds

**Passed**: ✅ Layer 2 (SSH) pushed 4 commits

## TC03: Normal mode (commit + push)
**Given**: repo with uncommitted changes + unpushed commits
**When**: no flags (default mode)
**Then**:
- Pre-flight runs (stale cleanup)
- Sync runs (fetch + pull)
- Changes are staged and committed
- Push runs with 3-layer fallback
- Exit code 0

**Status**: ⏳ Not tested (needs dirty workspace)

## TC04: Nothing to commit
**Given**: clean working tree, no unpushed commits
**When**: normal mode
**Then**:
- Pre-flight OK
- Fetch succeeds
- "Nothing to commit" logged
- "Nothing to push - 0 commits ahead" logged
- Exit code 0

**Status**: ⏳ Not tested

## TC05: Behind remote (need pull)
**Given**: local branch behind remote by N commits
**When**: any mode
**Then**:
- Stash local changes if any
- Pull --rebase attempted
- On conflict: abort rebase, try merge
- Pop stash
- Continue to commit/push

**Status**: ⏳ Not tested (needs divergence)

## TC06: All push layers fail
**Given**: no SSH key, no GCM, no gh token
**When**: PushOnly mode
**Then**:
- HTTPS fails with "terminal prompts disabled"
- SSH fails with "Repository not found" or "Permission denied"
- gh CLI fails if not authenticated
- ALL push layers FAILED error
- Exit code 1

**Status**: ⏳ Not tested (requires disabled auth)

## TC07: Stale index.lock cleanup
**Given**: stale index.lock file (>1 min old)
**When**: any mode
**Then**:
- index.lock removed during pre-flight
- Message "Removed stale index.lock" logged
- Script continues normally

**Passed**: ✅ (Lock was 3.9 min old, removed successfully)

## TC08: Concurrent run prevention (mutex)
**Given**: script already running
**When**: second instance started
**Then**:
- "Another instance is already running" error
- Exit code 1
- First instance continues unaffected

**Status**: ⏳ Not tested (manual test needed)

## TC09: Timeout handling
**Given**: git operation stuck (network issue)
**When**: operation exceeds $GIT_TIMEOUT_SEC (60s)
**Then**:
- Process killed
- "Timeout after 60s" exception thrown
- Script exits with error

**Status**: ⏳ Not tested (simulated network block)

## TC10: Verbose debug logging
**Given**: `-Verbose` flag (common parameter)
**When**: any mode
**Then**:
- DEBUG level messages shown
- All git commands logged with arguments
- Full output visible

**Status**: ✅ Works (common parameter behavior)
