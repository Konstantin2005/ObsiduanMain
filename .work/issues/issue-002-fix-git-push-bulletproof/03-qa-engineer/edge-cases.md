# Edge Cases — git-push-bulletproof

## EC01: Branch name with spaces
If branch name contains spaces, Invoke-Git must properly quote it for cmd.exe /c.
**Current behavior**: Arguments are quoted if they match `\s` regex.
**Risk**: Medium — branches with spaces are rare but would break quoting.
**Mitigation**: Test with "feature/my feature" branch.

## EC02: Large number of commits ahead (>500)
Script checks `$MAX_AHEAD_PUSH` (500) and refuses to push.
**Edge**: What if ahead exactly 500? Condition is `-gt` (greater than), so 500 is allowed.
**Risk**: Very large push could timeout.

## EC03: HTTPS credential store race condition
Push-Https stores gh token in credential store, then immediately pushes.
**Edge**: If credential store update takes >500ms (Start-Sleep), push might not use the new token.
**Risk**: Low — Start-Sleep 500ms should be enough.

## EC04: SSH key with passphrase
Script finds id_ed25519 and uses it with -o BatchMode=yes.
**Edge**: If key has a passphrase, SSH will fail because `BatchMode=yes` prevents prompting.
**Risk**: Low — SSH keys for automation should not have passphrases. If they do, use ssh-agent.

## EC05: Network partition during fetch
Fetch sets TimeoutSec=120. If network is slow, partial data might be received.
**Edge**: Process.Kill() on timeout might leave .git in inconsistent state.
**Mitigation**: Pre-flight's Repair-StaleLock cleans index.lock on next run.

## EC06: Rebase conflict during pull
Invoke-Sync tries `git pull --rebase`. If conflicts:
1. `git rebase --abort` 
2. Falls back to `git pull` (merge)
**Edge**: If merge also conflicts, the conflict markers remain in working tree.
**Mitigation**: None — manual intervention needed. Script logs the error clearly.

## EC07: Uncommitted changes during pull
Script stashes before pull, pops after.
**Edge**: If stash pop fails (conflict with pulled changes), stash is left behind.
**Risk**: Medium — user might lose stashed changes if not checked.
**Mitigation**: Script logs all stash operations.

## EC08: Git hooks interfering
Script disables hooks by setting core.hooksPath to a temp directory.
**Edge**: If git version doesn't support core.hooksPath (pre-2.9), this is silently ignored.
**Mitigation**: Error suppressed with 2>$null.

## EC09: Running outside a git repo
Test-GitDir catches this early with `git rev-parse --git-dir`.
**Behavior**: "Not a git repository" error, exit code 1.

## EC10: Mutex on non-Windows
Script assumes Windows (uses "Global\" prefix for mutex).
**Edge**: On Linux/macOS, New-Object System.Threading.Mutex still works but without "Global\" prefix.
**Risk**: Low — this script is Windows-specific (Task Scheduler use case).

## EC11: Temp files not cleaned up
Invoke-Git creates temp files for output redirection. If script crashes before cleanup, files remain in %TEMP%.
**Mitigation**: Random unique filenames, cleanup on success. Stale temp files are harmless.

## EC12: Empty commit message
Invoke-Commit auto-generates message if none provided: "Auto-commit $date [$stats]"
**Edge**: If stats show 0 files/0 lines (empty commit), git might refuse.
**Risk**: Low — Test-HasChanges checks for changes before committing.
