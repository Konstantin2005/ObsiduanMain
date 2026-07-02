# Architecture: Agent Core Templates (#114)

## Decision
Создать `agent-core/` как отдельный JS репозиторий с собственной Template системой.

## Components

### Template Engine (src/templates/)
```
engine.js      — рендеринг: [var], {% if %}, {% each as %}
loader.js      — загрузка .md из templates/
registry.js    — Facade: engine + loader
index.js       — публичное API
```

### Agents (src/agents/)
```
architect.js   → plan.md, architecture.md, decisions.md
backend.js     → backend-api.md
frontend.js    → frontend-ui.md
qa.js          → qa-tests.md
reviewer.js    → review.md
```

### Pipeline Integration
```
Pipeline.init() → TemplateRegistry.init() → loadAll()
  ↓
#runStage() → new Agent() → agent.setTemplateRegistry(registry)
  ↓
agent.execute(context) → this.renderTemplate(name, vars)
```

## Data Flow
```
TemplateRegistry.render(name, vars)
  → TemplateLoader.load(name)        // .md → string
  → TemplateEngine.render(string, vars)  // [var] → substitutions
  → return rendered string
  → fs.writeFile to workspace
```
