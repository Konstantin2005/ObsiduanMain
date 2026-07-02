# Decisions Log: Unified Graph Runtime Contract

## Decision 1: Interface-First Contract Definition
- **Date:** 2026-06-27
- **Decision:** Define contracts as formal interfaces (TypeScript/Go interfaces) before implementation
- **Rationale:** Interface-first ensures all subsystems agree on shapes before coding
- **Alternatives Considered:**
  - Document-first (spec in markdown) — can drift from code

## Decision 2: Data Flow Map as Living Document
- **Date:** 2026-06-27
- **Decision:** Data flow map is maintained as both a diagram and a code-validated document (tests enforce flow correctness)
- **Rationale:** Prevents divergence between documentation and implementation
- **Alternatives Considered:**
  - Static diagram only — inevitably becomes outdated

## Decision 3: Validation Suite Runs in CI
- **Date:** 2026-06-27
- **Decision:** Contract compliance is enforced via automated tests in CI pipeline
- **Rationale:** Catches contract violations before deployment
- **Alternatives Considered:**
  - Manual review — error-prone and slow
