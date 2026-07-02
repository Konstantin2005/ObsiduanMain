# Shared Architecture — Issue #111

See `00-architect/architecture.md` for full details.

## Key Components
- **LoginCommand** — CLI entry point (`packages/opencode/src/cli/cmd/account.ts`)
- **loginEffect** — core login orchestration
- **openBrowser** — wraps `open` npm package
- **Prompt** — clack-based UI system

## Contract
`openBrowser(url: string): Effect.Effect<void>` — returns Effect that opens URL in browser. On failure, logs warning and continues.
