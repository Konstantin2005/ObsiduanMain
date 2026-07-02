# Implementation — Error Telemetry

## Created Files

### agent-core/src/telemetry/
| File | Purpose |
|------|---------|
| error-collector.js | Buffer queue, flush, capture |
| transport.js | GitTransport — writes JSONL, git commit + push |
| fallback-storage.js | Local fallback if git fails |
| error-logger.js | Facade: singleton, wrap(), handler() |
| hooks.js | Agent/pipeline/template telemetry hooks |
| index.js | Public API |

### error-telemetry/
| File | Purpose |
|------|---------|
| README.md | Repo docs |
| .gitignore | Exclude logs |
| logs/ | JSONL output directory |
