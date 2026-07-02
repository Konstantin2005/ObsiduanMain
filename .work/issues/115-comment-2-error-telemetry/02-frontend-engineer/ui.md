# Error Telemetry — Repo Structure

```
Main/
├── agent-core/
│   └── src/
│       └── telemetry/          ← NEW: error logging system
│           ├── error-logger.js     — facade, singleton
│           ├── error-collector.js  — buffer queue
│           ├── transport.js        — git writer
│           ├── fallback-storage.js — local fallback
│           ├── hooks.js           — agent/pipeline/template wrappers
│           └── index.js           — exports
│
├── error-telemetry/             ← NEW: external git repo
│   ├── README.md
│   ├── .gitignore
│   └── logs/
│       └── YYYY-MM-DD/
│           ├── agent-errors.jsonl
│           ├── pipeline-failures.jsonl
│           └── system-warnings.jsonl
│
└── .work/issues/115-comment-2-error-telemetry/
```
