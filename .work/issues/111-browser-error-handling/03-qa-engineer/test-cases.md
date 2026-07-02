# Test Cases — Browser Opening Error Handling

## TC-1: Browser opens successfully
**Given**: User has a desktop environment with a default browser
**When**: `opencode console login` is run
**Then**: Browser opens with the verification URL
**Expected**: No warning message shown. Flow continues normally.

## TC-2: No default browser (headless server)
**Given**: User is on a headless Linux server (e.g., Hetzner VPS) with no DISPLAY set
**When**: `opencode console login` is run
**Then**: `open()` call throws/returns error
**Expected**: Warning displayed: "Could not open browser automatically. If you are on a headless server, copy the URL above into a browser on another machine."
**Expected**: URL and code remain visible in terminal
**Expected**: Login flow continues (user can manually open URL)

## TC-3: Browser permission denied
**Given**: User has a browser but open() is denied (sandbox, container)
**When**: `opencode console login` is run
**Then**: `open()` call throws
**Expected**: Same warning as TC-2. Flow continues.

## TC-4: Non-interactive terminal (SSH without -X)
**Given**: User is in an SSH session without X forwarding
**When**: `opencode console login` is run
**Then**: Browser cannot open (no display)
**Expected**: Warning displayed. Flow continues.

## TC-5: `console open` command
**Given**: User runs `opencode console open`
**When**: Browser fails to open
**Expected**: Same warning behavior (openBrowser helper is shared)

## Edge Cases
- **EC-1**: CI environment (GitHub Actions, etc.) — warning is non-blocking, CI won't fail
- **EC-2**: Windows with no default browser association — `open` package handles this, but if it fails, warning shows
- **EC-3**: macOS with no default browser — same behavior
- **EC-4**: Very long error messages from `open` — not exposed to user, only our fixed message

## Verification Checklist
- [ ] Warning message is user-friendly and actionable
- [ ] Flow is NOT blocked (login continues)
- [ ] URL and code are still displayed before browser attempt
- [ ] `openBrowser` is used in `loginEffect` and `openEffect` — both covered
- [ ] No regression for successful browser opens
