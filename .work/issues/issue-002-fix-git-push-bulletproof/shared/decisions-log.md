# Decisions Log — Issue #002 Fix Git Push

## Decision 1: Self-healing architecture vs simple push-retry
- **Choice**: Self-healing with pre-flight checks (stale locks, processes, rebase)
- **Rationale**: The original problem was a stale index.lock (8195 min old) + SSH agent not running in Task Scheduler. Simple retry wouldn't fix root cause.
- **Alternatives considered**: (a) Just fix the SSH agent, (b) Use only `gh` CLI, (c) Simple retry loop

## Decision 2: 3-layer push fallback vs single method
- **Choice**: HTTPS → SSH → gh CLI token (tried sequentially)
- **Rationale**: Different environments have different auth available. Non-interactive (Task Scheduler) needs SSH with explicit key or token.
- **Alternatives**: (a) Only SSH (fails without agent), (b) Only HTTPS (fails without GCM)

## Decision 3: cmd.exe /c with temp files for git execution
- **Choice**: Redirect stdout/stderr to temp files, execute via cmd.exe /c, read results
- **Rationale**: PowerShell Process async event handlers have scoping issues with -Action blocks; synchronous ReadToEnd() can deadlock on large output.
- **Alternatives**: (a) Start-Job/Receive-Job (slow), (b) Runspace pool (complex), (c) & git native call (no timeout control)

## Decision 4: Pure ASCII file content
- **Choice**: Removed ALL Unicode characters from the .ps1 file (em-dashes, smart quotes)
- **Rationale**: Get-Content defaults to ANSI on PS 5.1 (Windows-1251 on Russian systems), which corrupts UTF-8 characters. ASCII-only avoids encoding issues entirely.
- **Alternatives**: (a) Always use -Encoding UTF8, (b) Save without BOM, (c) Use [File]::ReadAllText

## Decision 5: Use explicit SSH key path instead of ssh-agent
- **Choice**: Set GIT_SSH_COMMAND with -i path/to/key
- **Rationale**: Task Scheduler non-interactive sessions don't have ssh-agent running. Direct key path works without agent.
- **Alternatives**: (a) Start ssh-agent in script, (b) Use pageant (Windows), (c) Use .ssh/config

## Decision 6: Remote URL correction
- **Choice**: Updated $REMOTE_SSH/$REMOTE_HTTPS to Konstantin2005/ObsiduanMain
- **Rationale**: Original URL pointed to kiselyovds/Calendula which doesn't exist on GitHub
- **Alternatives**: (a) Auto-detect correct remote via API, (b) Use git remote get-url, (c) Prompt user

## Decision 7: Mutex for parallel run prevention
- **Choice**: System.Threading.Mutex with "Global\ObsidianGitPushBulletproof" name
- **Rationale**: Task Scheduler could trigger multiple overlapping runs. Mutex prevents concurrent pushes.
- **Alternatives**: (a) Lock file in .git/, (b) PowerShell module mutex, (c) Named pipe
