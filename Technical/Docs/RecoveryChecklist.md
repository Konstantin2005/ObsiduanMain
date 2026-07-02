# Recovery Checklist

> Based on issue #91 and the encoding disaster of 2026-06-24.

## Encoding Corruption Recovery

### Symptoms
- `?` characters in file content (Windows-1251 → broken UTF-8)
- `?` in filenames
- Broken tags (`tags: [???, ????]`)
- Git shows massive binary diff

### Recovery Steps

| Step | Action | Command |
|------|--------|---------|
| 1 | Find the killer commit | `git log --oneline --name-only` |
| 2 | Find last healthy commit | Check files before corruption |
| 3 | Create recovery branch | `git checkout -b recovery-YYYY-MM-DD` |
| 4 | Restore from healthy commit | `git checkout <healthy-commit> -- <dir>` |
| 5 | Remove corrupted files | `git rm <corrupted-files>` |
| 6 | Clean encoding damage | Remove `?` blocks from files |
| 7 | Fix tags | Rebuild frontmatter |
| 8 | Commit | `git commit -m "recovery: ..."` |
| 9 | Force-push (last resort) | `git push --force origin recovery-YYYY-MM-DD` |
| 10 | Merge to main | `git checkout main; git merge recovery-...` |

### Prevention
- ✅ Pre-commit hook blocks `?` patterns in `.md` files
- ✅ All files validated as UTF-8
- ✅ No `text.encode("windows-1251", errors="replace")` in scripts

---

## File Corruption Recovery

### Symptoms
- Broken frontmatter
- Missing `---` delimiters
- Empty files
- Garbled YAML

### Recovery Steps

| Step | Action |
|------|--------|
| 1 | Check file count baseline | `Get-ChildItem -Recurse *.md | Measure-Object` |
| 2 | Find files with broken frontmatter | Search for missing `---` |
| 3 | Restore from snapshot | `vault/snapshot.ps1` archive |
| 4 | Restore from git | `git checkout <commit> -- <file>` |
| 5 | Validate all tags | Check `tags:` field |
| 6 | Validate all links | Check `[[...]]` patterns |

---

## Git Repository Recovery

### Symptoms
- Corrupted index
- Loose objects errors
- Push rejected

### Recovery Steps

| Step | Action | Command |
|------|--------|---------|
| 1 | Verify objects | `git fsck` |
| 2 | Clean reflog | `git reflog expire --expire=now --all` |
| 3 | GC aggressively | `git gc --aggressive --prune=now` |
| 4 | Repair if needed | `git repair` (git-extras) |
| 5 | Fresh clone (nuclear) | `git clone <url> --mirror` |

---

## Task Scheduler Recovery

### After System Crash

| Step | Action |
|------|--------|
| 1 | Check all tasks status | `schtasks /query /v` |
| 2 | Verify script paths | Check `Technical/` prefix |
| 3 | Restart stuck tasks | `schtasks /end /tn <task>` |
| 4 | Clear stale lock files | Remove `*.lock` from `Technical/Scripts/Logs/` |
| 5 | Re-enable disabled tasks | `schtasks /change /tn <task> /enable` |
| 6 | Verify execution | Run each task manually |

### Known-Fixed Paths
| Task | Correct Path |
|------|-------------|
| HourlyGit | `Technical\Scripts\Launchers\run-hourly.vbs` |
| HourlyGitObsidian | `Technical\Scripts\Launchers\run-hourly.vbs` |
| Kanban - File Watcher | `Technical\Scripts\Launchers\run-watcher.vbs` |
| Kanban - Move Today Tasks | `Technical\Scripts\Vault\Move-TodayTasks.ps1` |
| ThresholdGitObsidian | `Technical\Scripts\Launchers\run-hidden.vbs` |

---

## Backup Strategy

| Layer | What | Frequency | Retention |
|-------|------|-----------|-----------|
| Git | All tracked files | Per commit | Full history |
| Snapshot | `vault/` directory | 6h | 7 days |
| GitHub | Remote copy | Per push | Full history |
| Local clone | Full repo | N/A | N/A |

### Restore Priority
1. **Git checkout** — fastest for known-good state
2. **Snapshot restore** — if git history is damaged
3. **Fresh clone** — last resort for full repo recovery
