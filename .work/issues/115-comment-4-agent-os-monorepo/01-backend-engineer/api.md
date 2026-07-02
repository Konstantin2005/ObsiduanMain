# Bridge API — Lifecycle

## Lifecycle
```
new Lifecycle({ core, telemetry, taskQueue, onError })

lifecycle.handleError(error, source, severity)  → async
lifecycle.processNextTask()                     → Task | null
lifecycle.run(error, source, severity)          → Task | null
```

## Mappers (agent, pipeline, template)
```
getAgentRef(name)      → { ref, description } | null
listAgents()           → string[]
getPipelineRef(name)   → { ref, order, parallel } | null
getPipelineOrder()     → [{ name, ref, order, parallel }]
getTemplateRef(name)   → { ref, description } | null
listTemplates()        → string[]
```
