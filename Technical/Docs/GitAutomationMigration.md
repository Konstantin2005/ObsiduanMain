# Git Automation Consolidation Migration Notes

## Summary
Consolidated all git automation scripts into a single canonical location: `Technical/Scripts/Git/`

## Changes Made

### Removed Duplicate Scripts
- `C:\obsidian\Main\Technical\Scripts\Git\daily-git.ps1` - simple daily commit/push
- `C:\obsidian\Main\Technical\Scripts\Git\threshold-git.ps1` - 15-second interval commit loop
- `C:\obsidian\Main\Technical\Scripts\Git\hourly-git.ps1` - hourly commit/push with rebase

### Removed Legacy Scripts (from Старое)
- `Старое\Calendula-People-Graph\daily-git.ps1`
- `Старое\Calendula-People-Graph\threshold-git.ps1`
- `Старое\Calendula-People-Graph-From-Branch\daily-git.ps1`
- `Старое\Calendula-People-Graph-From-Branch\threshold-git.ps1`
- `Старое\Calendula-People-Graph-From-Branch\Calendula-People-Graph\daily-git.ps1`
- `Старое\Calendula-People-Graph-From-Branch\Calendula-People-Graph\threshold-git.ps1`

### Removed Legacy Launchers
- `Scripts\Launchers\run-hourly.vbs`
- `Technical\Scripts\Launchers\run-hourly.vbs`

### Updated Launchers
- `Technical\Scripts\Launchers\run-hidden.vbs` - now points to `daily-push.ps1`
- `Старое\Calendula-People-Graph\run-hidden.vbs` - now points to `daily-push.ps1`
- `Старое\Calendula-People-Graph-From-Branch\run-hidden.vbs` - now points to `daily-push.ps1`
- `Старое\Calendula-People-Graph-From-Branch\Calendula-People-Graph\run-hidden.vbs` - now points to `daily-push.ps1`

### Canonical Script: `Technical\Scripts\Git\daily-push.ps1`

**Features:**
- Auto-commits every 5 seconds (when changes exist)
- Auto-pushes every 5 minutes
- Auto-detects current branch (no hardcoded `main`)
- Uses `--rebase` instead of `-X ours` for safer merges
- Comprehensive logging to `Technical\Scripts\Logs\daily-push.log`
- Dry-run mode for testing
- Configurable intervals via parameters

**Parameters:**
- `-RepoPath` - repository path (default: C:\obsidian\Main)
- `-Branch` - branch name (default: auto-detect current branch)
- `-CommitIntervalSeconds` - commit check interval (default: 5)
- `-PushIntervalMinutes` - push interval (default: 5)
- `-DryRun` - test mode without executing git commands
- `-GitPath` - git executable path (default: git)
- `-LogPath` - log file path

### Updated Tests
- Removed hourly-git tests (script removed)
- Updated legacy launcher test to verify daily-push.ps1 reference
- daily-push tests remain unchanged

## Verification
- All existing workflows continue working
- No broken script references remain
- Single canonical automation location established
- Migration notes recorded in this document

## Rollback
If issues arise, the old scripts can be restored from git history (branch `main` before this commit).