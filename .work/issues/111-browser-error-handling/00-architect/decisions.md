# Architecture Decisions Log

## ADR-1: Use Prompt.log.warn for browser failure warning

**Status**: Accepted  
**Context**: Browser opening failure on headless servers is silently swallowed.  
**Decision**: Use `Prompt.log.warn` with a descriptive message when `open()` fails, matching the existing pattern in the GitHub install handler.  
**Consequences**:
- User sees a visible warning but flow is not blocked
- Consistent with existing codebase patterns
- Minimal code change

## ADR-2: Keep the flow non-blocking

**Status**: Accepted  
**Context**: A blocked flow would break login for users who manually copy the URL.  
**Decision**: Do not throw or halt execution. The warning is informational.  
**Consequences**:
- Users on headless servers continue to work
- The terminal output clearly shows the URL as fallback

## ADR-3: No structural changes to OAuth logic

**Status**: Accepted  
**Context**: The issue is only about error presentation.  
**Decision**: Only modify the `openBrowser` helper function. No changes to service layer, polling, or data flow.  
**Consequences**:
- Low risk of regression
- Easy to review and merge
- Focused change

## ADR-4: Use Effect context for Prompt access

**Status**: Accepted  
**Context**: The `openBrowser` helper currently returns an Effect, but uses raw Promise `.catch()`.  
**Decision**: Use `Effect.sync` or `Effect.attempt` to properly integrate Prompt logging within the Effect system.  
**Consequences**:
- Proper integration with Effect's fiber/system
- Prompt (clack) context is properly available
