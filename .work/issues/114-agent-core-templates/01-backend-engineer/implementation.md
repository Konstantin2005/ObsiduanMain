# Implementation — Agent Core Templates (#114)

## Created Files

### src/templates/
| File | Lines | Description |
|------|-------|-------------|
| engine.js | ~70 | TemplateEngine class with regex-based rendering |
| loader.js | ~50 | TemplateLoader with caching + error handling |
| registry.js | ~35 | TemplateRegistry Facade |
| index.js | ~15 | Public API exports |

### templates/
| File | Origin | Status |
|------|--------|--------|
| plan.md | New | ✅ |
| architecture.md | Ported from Main | ✅ Enhanced |
| decisions.md | New | ✅ |
| context.md | Ported from Main | ✅ Enhanced |
| backend-api.md | Ported (was backend-engineer.md) | ✅ Enhanced |
| frontend-ui.md | Ported (was frontend-engineer.md) | ✅ Enhanced |
| qa-tests.md | Ported (was qa-engineer.md) | ✅ Enhanced |
| review.md | Ported (was code-reviewer.md) | ✅ Enhanced |

### src/agents/ (refactored)
| File | Before | After |
|------|--------|-------|
| architect.js | Hardcoded strings | renderTemplate('plan', vars) |
| backend.js | Hardcoded strings | renderTemplate('backend-api', vars) |
| frontend.js | Hardcoded strings | renderTemplate('frontend-ui', vars) |
| qa.js | Hardcoded strings | renderTemplate('qa-tests', vars) |
| reviewer.js | Hardcoded strings | renderTemplate('review', vars) |

### src/core/ (modified)
- **agent.js** — added setTemplateRegistry() + renderTemplate()
- **pipeline.js** — init() calls TemplateRegistry, inject into agents
