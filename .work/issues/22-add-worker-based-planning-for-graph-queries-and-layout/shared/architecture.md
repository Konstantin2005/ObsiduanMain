# Shared Architecture: DEV: Add worker-based planning for graph queries and layout

## System Context
Query planning and layout work should not compete with UI responsiveness at large scale.

## Key Components
1. Worker Pool — manages worker lifecycle
2. Planner Worker — executes graph query planning
3. Layout Worker — computes graph layout
4. Result Merger — combines worker results deterministically
5. Cancellation Token — ensures safe cancellation

## Data Flow
UI Request → Worker Pool → Planning Worker / Layout Worker → Result Merger → Main Thread → Render

## Constraints
- Workers must not block the main thread
- Worker results must be deterministic
- Cancellation must be safe (no resource leaks)
