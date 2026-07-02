# Plan: Improve Browser Opening Error Handling in AuthLoginCommand

## Issue Summary
When running `opencode console login` on a headless server (e.g., Hetzner cloud VPS), the browser fails to open silently. The `open` npm package throws an error that is caught with `.catch(() => undefined)`, swallowing the error entirely. The user still sees the URL in the terminal, but no explicit message indicates the browser failed to open.

## Goal
Improve error handling so that:
1. When the browser fails to open, the user gets a clear, non-blocking warning
2. The URL and code remain visible in terminal
3. The login flow continues without interruption
4. The message is helpful for headless/server environments

## Implementation Plan

### Phase 1 — Architect
- Analyze current browser opening patterns across the codebase
- Design consistent error handling approach
- Define API/contract for `openBrowser` helper

### Phase 2 — Implementation (Backend + Frontend parallel)
- **Backend (account.ts)**: Update `openBrowser` helper to log a warning instead of silently catching
- **Frontend (CLI)**: Ensure `Prompt.log.warn` is properly displayed; possibly add a hint

### Phase 3 — QA
- Test cases: headless server, no default browser, browser permission denied
- Edge cases: non-interactive terminals, CI environments

### Phase 4 — Code Review
- Review error handling patterns
- Ensure consistency with rest of codebase
- Verify production readiness

## Files to Modify
1. `packages/opencode/src/cli/cmd/account.ts` — `openBrowser` helper, `loginEffect`
2. (If needed) `packages/opencode/src/account/account.ts` — service layer
3. (If needed) other `open` call sites in `packages/opencode/src/cli/cmd/web.ts`
