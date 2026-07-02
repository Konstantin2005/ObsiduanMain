# Decisions Log

## ADR-1: Explicit FSM over ad-hoc state tracking
- **Decision:** Formal finite state machine
- **Rationale:** Eliminates illegal states; testable
- **Date:** 2026-06-27

## ADR-2: Event queue with total ordering
- **Decision:** Centralized ordered event queue
- **Rationale:** Prevents race conditions
- **Date:** 2026-06-27

## ADR-3: Guards as async predicates
- **Decision:** Guards can be async
- **Rationale:** Some transitions depend on system state
- **Date:** 2026-06-27

## ADR-4: Visual state indicator in header
- **Decision:** Show current state as badge
- **Rationale:** User knows what's happening
- **Date:** 2026-06-27
