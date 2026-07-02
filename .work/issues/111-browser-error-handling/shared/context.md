# Shared Context — Issue #111

**Issue**: fix: improve browser opening error handling in AuthLoginCommand  
**Status**: ✅ DONE

## Summary
- Changed `openBrowser` helper in `packages/opencode/src/cli/cmd/account.ts:10`
- Before: `open(url).catch(() => undefined)` — silently swallowed errors
- After: `Effect.promise(() => open(url)).pipe(Effect.catchAll(() => Prompt.log.warn(...)))` — shows warning

## Pipeline Result
| Role | Status |
|------|--------|
| 🧭 Architect | ✅ Done |
| ⚙️ Backend | ✅ Done |
| 🎨 Frontend | ✅ Done |
| 🧪 QA | ✅ Done |
| 🔍 Reviewer | ✅ Done |

## Diff
```diff
- const openBrowser = (url: string) => Effect.promise(() => open(url).catch(() => undefined))
+ const openBrowser = (url: string) =>
+   Effect.promise(() => open(url)).pipe(
+     Effect.catchAll(() =>
+       Prompt.log.warn(
+         `Could not open browser automatically. If you are on a headless server, copy the URL above into a browser on another machine.`,
+       )
+     ),
+   )
```
