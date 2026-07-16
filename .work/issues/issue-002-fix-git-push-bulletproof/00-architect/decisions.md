# Architectural Decisions

## AD-1: Self-contained script (no external module dependency)
**Status**: Accepted
**Reasoning**: The current `core.ps1` module has bugs (e.g., `gh push` doesn't exist). A self-contained script eliminates dependency issues and ensures predictable behavior.
**Alternatives**: Fixing `core.ps1` (fragile, cascading changes)

## AD-2: HTTPS as primary push method
**Status**: Accepted
**Reasoning**: SSH agent is not available in Task Scheduler (non-interactive). HTTPS + credential store works without interactive login. Token stored in `credential-store` is always available.
**Alternatives**: SSH as primary (fails from Task Scheduler)

## AD-3: Pre-flight self-healing before every operation
**Status**: Accepted
**Reasoning**: Common issues (stale lock, rebase state) accumulate over time. Cleaning them before each run ensures the script never fails on a recoverable condition.
**Alternatives**: Fail-fast (frequent crashes, user frustration)

## AD-4: fetch + pull --rebase before push
**Status**: Accepted
**Reasoning**: Remote can diverge from local if multiple processes push. Sync before push prevents rejection. `--rebase` keeps history linear.
**Alternatives**: Force push (data loss risk), skip sync (rejection)

## AD-5: Triple-layer push with exponential backoff
**Status**: Accepted
**Reasoning**: Each layer has different auth mechanisms. If one fails, the next may succeed. Retry with backoff avoids hammering the server.
**Alternatives**: Single method (single point of failure)

## AD-6: No GPG signing
**Status**: Accepted
**Reasoning**: `--no-gpg-sign` prevents failures on systems without GPG configured. Auto-commits don't need cryptographic verification.
**Alternatives**: GPG sign (harder to set up, fails without GPG key)
