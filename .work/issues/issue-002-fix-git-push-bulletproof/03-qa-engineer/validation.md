# Validation Rules — git-push-bulletproof

## Input Validation

### Parameter: -PushOnly
- Type: [switch]
- Validation: None needed (boolean)
- Default: $false

### Parameter: -DryRun
- Type: [switch]
- Validation: None needed (boolean)
- Default: $false

## Runtime Validation

### Pre-flight
| Check | Rule | Action |
|-------|------|--------|
| Git installed | `git --version` succeeds | Exit if fails |
| Git directory | `git rev-parse --git-dir` succeeds | Exit if fails |
| Stale git processes | Age > 5 min from PID start | Kill process |
| index.lock | Age > 1 min from creation | Remove file |
| Rebase artifacts | .git/rebase-merge/apply age > 5 min | Remove recursively |

### Sync
| Check | Rule | Action |
|-------|------|--------|
| Remote URL | Must be HTTPS or SSH format | Warn if unexpected |
| Fetch | Exit code 0 from `git fetch` | Retry with alternative protocol |
| Behind count | If > 0, pull required | Stash → pull --rebase → fallback to merge → pop stash |

### Commit
| Check | Rule | Action |
|-------|------|--------|
| Has changes | `git status --porcelain` non-empty | Skip commit if empty |
| Stage | `git add -A` exit code 0 | Error if fails |
| Commit | `git commit -m msg` exit code 0 | Retry if "nothing to commit" |

### Push
| Check | Rule | Action |
|-------|------|--------|
| Ahead count | Must be > 0 to push | Skip if 0 |
| Ahead max | Max $MAX_AHEAD_PUSH (500) | Error if exceeded |
| Layer 1 (HTTPS) | Exit code 0 | Fall through to Layer 2 |
| Layer 2 (SSH) | Exit code 0 | Fall through to Layer 3 |
| Layer 3 (gh CLI) | Exit code 0 | Error if all layers fail |

## Output Validation

### Return Codes
| Code | Meaning |
|------|---------|
| 0 | All operations completed successfully |
| 1 | Error (pre-flight, sync, commit, or push failed) |

### Log Format
- Timestamp: `[yyyy-MM-dd HH:mm:ss]`
- Level: `[LEVEL]` (STEP, INFO, OK, WARN, ERROR, DEBUG)
- Message: Free-form text

### Log Levels
| Level | When |
|-------|------|
| STEP | Major pipeline step boundary |
| INFO | Normal informational message |
| OK | Successful operation |
| WARN | Non-fatal failure (layer fallback) |
| ERROR | Fatal failure (script may exit) |
| DEBUG | Only shown with -Verbose flag |
