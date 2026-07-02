# Architecture: Agent Core Standalone (#115)

## Решение
Выделить `agent-core/` в отдельный репозиторий на GitHub.

## Структура репозитория
```
agent-core/
├── .github/
│   └── workflows/
│       ├── test.yml       — test on push/PR
│       └── publish.yml    — npm publish on tag
├── src/
│   ├── core/              — orchestrator, pipeline, agent base
│   ├── agents/            — 5 agents
│   ├── templates/         — template engine
│   ├── shared/            — memory, context
│   └── logs/              — logger
├── templates/             — 8 markdown files
├── config/                — pipeline config
├── tests/                 — test suite
├── package.json
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## CI Pipeline
```
push/PR → npm ci → npm test → npm run lint → ✅
tag v* → npm test → npm publish → ✅
```

## Интеграция с multi-agent workflow
- AGENTS.md внутри agent-core
- .work/issues/ для issue-driven разработки
- Шаблоны для быстрого старта новых issues
