# Implementation — Agent OS Monorepo

## Создано

| Path | Description |
|------|-------------|
| agent-os/ | Monorepo root |
| agent-os/core/ | Execution engine (from agent-core) |
| agent-os/orchestration/ | Reference framework (from ai-dev-orchestration-system) |
| agent-os/telemetry/ | Error logging (from agent-core/src/telemetry) |
| agent-os/task-queue/ | Error→task→execution (from agent-core/src/task-queue) |
| agent-os/bridge/ | Integration layer |
| agent-os/bridge/src/lifecycle.js | Lifecycle orchestrator |
| agent-os/bridge/src/agent-mapper.js | Agent mapping |
| agent-os/bridge/src/pipeline-mapper.js | Pipeline mapping |
| agent-os/bridge/src/template-adapter.js | Template mapping |
| agent-os/bridge/src/index.js | Bridge exports |
| agent-os/config/.opencodeignore | OpenCode exclusion rules |
| agent-os/config/opencode.jsonc | OpenCode config |
| agent-os/config/.gitignore | gitignore |
| agent-os/package.json | npm package |
| agent-os/README.md | Repo docs |
| agent-os/docs/lifecycle.md | Lifecycle docs |
