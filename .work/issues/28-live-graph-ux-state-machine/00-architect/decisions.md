# Key Decisions: Live Graph UX State Machine

## ADR-1: Explicit FSM over ad-hoc state tracking
- **Decision:** Use formal finite state machine with defined transitions
- **Rationale:** Eliminates illegal states; makes state space testable and verifiable
- **Trade-off:** More upfront definition work; harder to add quick states

## ADR-2: Event queue with total ordering
- **Decision:** All events go through a centralized queue with ordering
- **Rationale:** Prevents race conditions between user and system events
- **Trade-off:** Single queue can become bottleneck under high event rate

## ADR-3: Guards as async predicates
- **Decision:** Transition guards can be async (Promise-based)
- **Rationale:** Some transitions depend on system state (e.g., can't transition to RUNNING if backend is down)
- **Trade-off:** Async guards make state machine harder to reason about

## ADR-4: Visual state indicator in header
- **Decision:** Always show current state as badge/indicator in panel header
- **Rationale:** User knows exactly what's happening; builds trust in the system
- **Trade-off:** Takes UI space; could be distracting during rapid transitions
