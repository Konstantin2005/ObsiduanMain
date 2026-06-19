# Repository Source-of-Truth and Generated Artifacts Policy

## Source-of-Truth

The following are the canonical source-of-truth locations in this repository:

| Artifact | Source Location | Generated? | Notes |
|---|---|---|---|
| Vault markdown notes | `Calendula/`, `Calendula-People-Graph-From-Branch/Calendula/` | No | User-authored content |
| TypeScript/JS runtime code | `Technical/Scripts/**/*.js`, `Technical/Scripts/**/*.ts` | No | Core graph platform |
| PowerShell automation | `Technical/Scripts/**/*.ps1` | No | Vault, Git, Discord automation |
| Test specifications | `Technical/Tests/**/*.ps1` | No | Pester test suite |
| Documentation | `Technical/Docs/**/*.md` | No | Architecture, plans, logs |
| Graph store binaries | `Calendula-20K/.obsidian/graph-store/` | Yes | Ignored via .gitignore |
| Live-graph recovery batches | `Calendula/.obsidian/plugins/live-graph/live-graph-recovery/` | Yes | Ignored via .gitignore |
| Logs | `Technical/Scripts/Logs/`, `Scripts/Logs/` | Yes | Ignored via .gitignore |

## Generated Artifacts Policy

1. **Never commit generated artifacts** - All generated files must be in `.gitignore`
2. **Graph store** - Built by `build-calendula-graph-store.js`, stored in vault `.obsidian/graph-store/`, ignored
3. **Live-graph recovery** - Written by Ultra Graph plugin at runtime, stored in plugin directory, ignored
4. **Logs** - Written by automation scripts, stored in `Scripts/Logs/` and `Technical/Scripts/Logs/`, ignored
5. **Benchmark reports** - JSON output to stdout, not written to disk by default
6. **Temporary test vaults** - Created in system temp directory, cleaned up after tests

## Verification

Run `git status` to verify no generated artifacts are tracked:

```powershell
git status --porcelain | Where-Object { $_ -match '\.(json|bin|log)$' -and $_ -notmatch '^\?\?' }
```

Should return empty.

## Adding New Generated Paths

When adding new generated artifact paths:
1. Add the path pattern to `.gitignore`
2. Update this policy document
3. Verify with `git status` that the path shows as untracked (`??`)