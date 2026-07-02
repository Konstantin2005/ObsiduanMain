# Backend: Bridge Layer API

## Agent Mapper
```
getAgentRef(name) → { ref, description, referencePath } | null
listAgents() → string[]
```

## Pipeline Mapper
```
getPipelineRef(stageName) → { ref, order, parallel } | null
getPipelineOrder() → [{ name, ref, order, parallel }]
```

## Template Adapter
```
getTemplateRef(templateName) → { ref, description } | null
listTemplates() → string[]
```
