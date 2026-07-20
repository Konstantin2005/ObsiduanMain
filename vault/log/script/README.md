# Script Log System

Every script execution is logged here for audit trail.

## Log Files

| File | Purpose |
|------|---------|
| `activity.md` | Master activity log (human readable) |
| `script/<name>.log` | Per-script execution history |
| `script/README.md` | This file |

## Log Format

```
[2026-06-24 16:00] script.ps1 | branch: feature/x | exit: 0 | duration: 12s | output: OK
```

## Usage

Run scripts via `run.ps1` wrapper to auto-log:

```powershell
.\vault\run.ps1 .\Technical\Scripts\Git\daily-push.ps1
```

Or add logging manually to any script.
