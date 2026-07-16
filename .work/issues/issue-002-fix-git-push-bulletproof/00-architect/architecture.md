# Architecture: Bulletproof Git Push

## System Design

```
┌─────────────────────────────────────────────────────────┐
│                 git-push-bulletproof.ps1                  │
├─────────────────────────────────────────────────────────┤
│  1. PRE-FLIGHT                                           │
│     ├── Check git installed                              │
│     ├── Kill stale git processes (>5 min)                │
│     ├── Remove stale index.lock                          │
│     ├── Clean stuck rebase/merge state                   │
│     └── Validate .git integrity                          │
├─────────────────────────────────────────────────────────┤
│  2. SYNC                                                 │
│     ├── git fetch origin (with retry)                    │
│     ├── Check ahead/behind counts                        │
│     ├── If behind → git pull --rebase (auto-merge)       │
│     └── If diverged → log warning, continue              │
├─────────────────────────────────────────────────────────┤
│  3. COMMIT (if changes)                                  │
│     ├── git add -A                                       │
│     ├── git commit -m "Auto-commit: date"                │
│     └── Handle "nothing to commit" gracefully            │
├─────────────────────────────────────────────────────────┤
│  4. PUSH (Triple-layer fallback)                         │
│     ├── LAYER 1: HTTPS + GCM + token                    │
│     │   └── Uses credential.helper=manager + plaintext   │
│     ├── LAYER 2: SSH + explicit key path                 │
│     │   └── Uses GIT_SSH_COMMAND with -i identity_file   │
│     └── LAYER 3: gh CLI env var                          │
│         └── Uses GH_TOKEN env var for auth               │
├─────────────────────────────────────────────────────────┤
│  5. VERIFICATION                                         │
│     ├── Verify push exit code                            │
│     ├── Log full details                                 │
│     └── Report status                                    │
└─────────────────────────────────────────────────────────┘
```

## Auth Layer Details

### Layer 1: HTTPS + Windows Credential Manager
- **Env**: `GIT_TERMINAL_PROMPT=0`, `GCM_INTERACTIVE=never`
- **Credential store**: Plaintext (gh token stored via `git credential-store`)
- **URL**: `https://github.com/Konstantin2005/ObsiduanMain.git`
- **Fallback condition**: Push exit code != 0

### Layer 2: SSH + Explicit Identity
- **Env**: `GIT_SSH_COMMAND=ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no`
- **URL**: `git@github.com:Konstantin2005/ObsiduanMain.git`
- **Key**: Tries common key paths (`id_ed25519`, `id_rsa`, `id_ecdsa`)
- **Fallback condition**: Push exit code != 0

### Layer 3: gh CLI Token
- **Env**: `GH_TOKEN=<token from gh auth token>`
- **Method**: Sets `GIT_ASKPASS=echo`, uses token as password
- **Fallback condition**: Push exit code != 0

## File Locations
- **Script**: `Technical/Scripts/Git/git-push-bulletproof.ps1`
- **Config**: Embedded in script (no external config needed)
- **Log**: `Technical/Scripts/Logs/git-push-bulletproof.log`
