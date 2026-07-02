# Plan: System Stabilization

## Goals
- Zero feedback loops
- No memory growth
- No re-index storms
- Predictable execution

## Phase 1 — Architect
- [x] Full system audit
- [x] 10 detected bugs with root causes
- [x] SAFE MODE architecture

## Phase 2 — Backend (fixes)
- [x] Control Plane separation
- [x] Stateless router
- [x] Minimal state manager (batched writes, 30s flush)
- [x] Non-triggering logging (append-only, no orchestration)

## Phase 3 — Frontend
- [x] SAFE MODE diagram
- [x] 10 hard constraints

## Phase 4 — QA
- [x] Loop prevention verification

## Phase 5 — Review
- [x] Final stable system rules
