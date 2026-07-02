# Architecture — Browser Opening Error Handling

## Summary
Minimal change to `openBrowser` helper in `packages/opencode/src/cli/cmd/account.ts`.

## Before
```typescript
const openBrowser = (url: string) =>
  Effect.promise(() => open(url).catch(() => undefined))
```

## After
```typescript
const openBrowser = (url: string) =>
  Effect.promise(() => open(url)).pipe(
    Effect.catchAll(() =>
      Prompt.log.warn(
        `Could not open browser automatically. If you are on a headless server, copy the URL above into a browser on another machine.`,
      )
    ),
  )
```

## Rationale
- Silent `.catch(() => undefined)` hides browser failures on headless servers
- `Effect.catchAll` properly integrates with Effect system
- `Prompt.log.warn` matches existing pattern in codebase
- Non-blocking — login flow continues
- User sees actionable message
