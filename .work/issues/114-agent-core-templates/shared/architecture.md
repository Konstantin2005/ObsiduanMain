# Shared Architecture — Issue #114

## Система
`agent-core/` — JS репозиторий с custom Agent Core и Template Engine.

## Компоненты
- **src/templates/engine.js** — TemplateEngine (variables, conditionals, loops)
- **src/templates/loader.js** — TemplateLoader (загрузка .md)
- **src/templates/registry.js** — TemplateRegistry (engine + loader)
- **templates/** — 8 шаблонов (plan, architecture, decisions, context, backend-api, frontend-ui, qa-tests, review)
- **src/agents/*** — 5 агентов, используют TemplateRegistry вместо хардкода

## Связь с Main
- `Main/Issues.md` — документация всех завершённых Issues (#108, #111, #112, #114)
- `Main/.work/templates/` — оригинальные 7 шаблонов (портированы и расширены в agent-core)

## Data Flow
```
Orchestrator → Pipeline → Agent (inject TemplateRegistry)
                              ↓
                         renderTemplate(name, vars)
                              ↓
                         TemplateRegistry.render()
                              ↓
                         TemplateLoader.load() + TemplateEngine.render()
                              ↓
                         write .md to workspace role folder
```
