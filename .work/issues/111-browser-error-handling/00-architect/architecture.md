# Architecture: Browser Opening Error Handling

## System Context
The auth login flow uses the OAuth 2.0 Device Authorization Grant (RFC 8628).
The CLI is the user-facing component; it runs on user machines and potentially on headless servers.

## Current Architecture

```
LoginCommand (CLI)
  └─ loginEffect(url)
       ├─ Prompt.intro("Log in")
       ├─ service.login(url)  → device code from server
       ├─ Print URL + code to terminal
       ├─ openBrowser(url)    → silent .catch(() => undefined)
       ├─ Spinner + poll for auth
       └─ Handle result
```

## Problem
`openBrowser` currently swallows all errors:
```typescript
const openBrowser = (url: string) =>
  Effect.promise(() => open(url).catch(() => undefined))
```

On headless servers, the `open` package throws because:
- No display server (Linux without X/Wayland)
- No default browser configured
- Sandbox restrictions in containers
- SSH sessions without X forwarding

## Proposed Architecture

### Enhanced `openBrowser` with user-friendly warning
```typescript
const openBrowser = (url: string) =>
  Effect.promise(() =>
    open(url).catch((error) => {
      Prompt.log.warn(
        `Could not open browser automatically. If you are on a headless server, copy the URL above into a browser on another machine.`
      )
    })
  )
```

### Consistency with existing patterns
The GitHub install handler already uses `Prompt.log.warn(...)`:
```typescript
if (error) {
  prompts.log.warn(`Could not open browser. Please visit: ${url}`)
}
```

We will follow the same pattern but use the Effect-wrapped Prompt API.

## Data Flow (unchanged)
No changes to the data flow or OAuth logic. Only the error presentation layer is affected.

## Key Design Decisions
1. Non-blocking warning — the flow continues regardless
2. Clear actionable message — user knows what to do
3. Consistent with existing GitHub install pattern
4. Minimal change — only the `openBrowser` helper
