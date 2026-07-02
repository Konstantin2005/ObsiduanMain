# Shared Architecture — Issue #115

## Цель
Превратить `agent-core/` в standalone GitHub репозиторий с CI/CD.

## Компоненты
- **GitHub repo** — `agent-core` (отдельный репозиторий)
- **CI/CD** — GitHub Actions (test + lint)
- **npm package** — публикация через npm/gpr
- **Docs** — README, CONTRIBUTING, примеры
- **Issues-driven development** — AGENTS.md workflow в самом agent-core

## Pipeline
```
Git init → GitHub repo → CI setup → npm init → Docs → QA → Review → Publish
```
