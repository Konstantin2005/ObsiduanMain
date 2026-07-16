# Architecture — Bulletproof Git Push

## Overview
Self-healing git push script for Obsidian vault automation.
Designed for Task Scheduler non-interactive execution.

## Pipeline
```
                    ┌──────────────────┐
                    │  START           │
                    │  Mutex Acquire   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  PRE-FLIGHT      │
                    │  ├─ Check Git    │
                    │  ├─ Kill stale   │
                    │  ├─ Clean lock   │
                    │  └─ Clean rebase │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  SYNC            │
                    │  ├─ Set SSH URL  │
                    │  ├─ git fetch    │
                    │  ├─ Check behind │
                    │  └─ Pull (if >0) │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  COMMIT          │
                    │  ├─ Stage all    │
                    │  └─ Commit auto  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  PUSH (3 layers)  │
                    │  ├─ Layer 1: HTTPS│
                    │  ├─ Layer 2: SSH │
                    │  └─ Layer 3: gh  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  DONE / FAIL     │
                    │  Mutex Release   │
                    └──────────────────┘
```

## Key Components

### Invoke-Git
- **Method**: cmd.exe /c with stdout/stderr redirection to temp files
- **Env**: GIT_TERMINAL_PROMPT=0, GCM_INTERACTIVE=never
- **Timeout**: Configurable per call (default 60s, fetch 120s)
- **Retry**: 1 attempt (with lock conflict auto-retry)

### Push Layers
| Layer | Protocol | Auth Method | Expected in Non-Interactive |
|-------|----------|-------------|---------------------------|
| 1 | HTTPS | Credential Manager | Fails (no GCM) |
| 2 | SSH | Explicit key (-i) | Works (no agent needed) |
| 3 | HTTPS | gh CLI token | Works (if auth'd) |

### Self-Healing
| Issue | Detection | Recovery |
|-------|-----------|----------|
| Stale index.lock | >1 min old | Delete |
| Stale git process | >5 min running | Kill |
| Stuck rebase | dir >5 min old | Delete recursively |
| Lock conflict | "index.lock" in output | Retry after 2s |
| Rebase conflict | "conflict" in output | Abort + fallback to merge |
| SSH fetch fail | non-zero exit | Retry with HTTPS |
| HTTPS push fail | non-zero exit | Try SSH |
| SSH push fail | non-zero exit | Try gh CLI |

## Configuration
- `$REMOTE_HTTPS/SSH`: GitHub repo URLs (auto-detected from git config recommended)
- `$STALE_PROCESS_MINUTES`: 5 min
- `$MAX_AHEAD_PUSH`: 500 commits
- `$GIT_TIMEOUT_SEC`: 60s (fetch 120s)
- `$MUTEX_NAME`: Global\ObsidianGitPushBulletproof
- Log dir: `../logs/` relative to script

## Logs
- `logs/backend.log` — all script operations
- Format: `[timestamp] [LEVEL] message`
- Levels: STEP, INFO, OK, WARN, ERROR, DEBUG
- DEBUG level only with -Verbose

## Test Coverage
### Verified
- ✅ DryRun mode (TC01)
- ✅ PushOnly mode (TC02) — SSH Layer succeeded
- ✅ Stale lock cleanup (TC07)
- ✅ All parser/encoding fixes

### Not Tested
- ⏳ Normal mode with dirty workspace (TC03)
- ⏳ Nothing to commit (TC04)
- ⏳ Pull behind remote (TC05)
- ⏳ All layers fail (TC06)
- ⏳ Mutex concurrent (TC08)
- ⏳ Timeout handling (TC09)
