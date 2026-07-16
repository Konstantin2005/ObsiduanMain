# Failure Scenarios — git-push-bulletproof

## FS01: Git not installed
**Trigger**: `git` command not found in PATH
**Detection**: Test-GitInstalled checks Get-Command
**Recovery**: Script exits with error before any operation

## FS02: Not a git repository
**Trigger**: Running script outside .git directory
**Detection**: Test-GitDir checks `git rev-parse --git-dir`
**Recovery**: Script exits with error

## FS03: HTTPS push fails (no GCM)
**Trigger**: GIT_TERMINAL_PROMPT=0, no credential helper configured
**Layer**: Push Layer 1
**Recovery**: Logs warning, falls through to Layer 2 (SSH)

## FS04: SSH push fails (no key / agent)
**Trigger**: No SSH key found, or key has passphrase, or key not authorized
**Layer**: Push Layer 2
**Recovery**: Logs warning, falls through to Layer 3 (gh CLI)

## FS05: gh CLI not authenticated
**Trigger**: `gh auth token` returns empty
**Layer**: Push Layer 3
**Recovery**: Logs "gh CLI not authenticated", returns false

## FS06: ALL push layers fail
**Trigger**: HTTPS fails + SSH fails + gh CLI fails
**Recovery**: Script exits with code 1, logs actionable diagnostics:
- "Check: github auth status, SSH keys, gh CLI auth"
- "Run: gh auth status"
- "Run: ssh -T git@github.com"

## FS07: Fetch fails (network)
**Trigger**: No network, DNS failure, GitHub down
**Recovery**: Retries SSH fetch, falls back to HTTPS fetch, if both fail → exit code 1

## FS08: Rebase fails with conflicts
**Trigger**: `git pull --rebase` produces conflicts
**Recovery**: `git rebase --abort`, falls back to `git pull` (merge)
**If merge also fails**: Script exits with error, conflict markers remain in working tree

## FS09: Stale git process blocks operations
**Trigger**: Git process running >5 minutes
**Recovery**: Process killed by Repair-StaleProcesses; index.lock cleaned by Repair-StaleLock

## FS10: Commit fails (pre-commit hook or disk full)
**Trigger**: Git commit fails for any reason
**Recovery**: Error logged, script exits with code 1

## FS11: PowerShell version < 3.0
**Trigger**: Script uses [CmdletBinding()] which requires PS 3.0+
**Recovery**: None — will fail on PS 2.0. Acceptable for modern Windows systems.

## FS12: Path too long (MAX_PATH)
**Trigger**: Temp file paths exceed 260 chars
**Recovery**: `[System.IO.Path]::GetTempPath()` + short filenames should stay under limit
**Risk**: Low for typical Windows systems
