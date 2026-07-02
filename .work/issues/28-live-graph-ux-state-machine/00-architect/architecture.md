# Architecture: Live Graph UX State Machine

## Module Structure
```
src/
  ux/
    states/
      definitions.ts   — State enum and metadata
      transitions.ts   — Valid transition map
      guards.ts        — Transition precondition checks
    machine/
      engine.ts        — FSM engine
      event-queue.ts   — Event ordering and dispatch
      hooks.ts         — Entry/exit hook manager
    ui/
      panel.ts         — Main panel component
      controls.ts      — Action button/control component
      indicators.ts    — Progress/status indicators
    mapping/
      state-ui.ts      — State → UI layout mapping
      actions.ts       — State-aware action availability
```

## API Design
```typescript
type GraphState = 'IDLE' | 'LOADING' | 'RUNNING' | 'PAUSED' | 'ERROR' | 'RECOVERING' | 'PREVIEW';

interface StateMachineConfig {
  initialState: GraphState;
  states: Record<GraphState, StateDefinition>;
  transitions: Transition[];
}

interface Transition {
  from: GraphState;
  to: GraphState;
  event: string;
  guard?: () => boolean | Promise<boolean>;
}

interface StateEvent {
  type: string;
  payload?: any;
  source: 'user' | 'system';
  timestamp: number;
}
```
