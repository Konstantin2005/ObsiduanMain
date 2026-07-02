# Implementation Plan: #2 - Оставить один основной код Live Graph вместо дубликатов

## Phase 1: Inventory & Analysis (Week 1)

### Task 1.1: Complete Inventory of All Live Graph Copies
- [ ] Scan all vaults for `live-graph-core.js` and related files
- [ ] Catalog each copy with: path, size, last modified, vault origin
- [ ] Identify all import paths referencing these copies
- [ ] Document any vault-specific modifications

**Deliverable**: `inventory/live-graph-copies.md`

### Task 1.2: Behavioral Comparison
- [ ] Create test harness to run identical graph operations on each copy
- [ ] Compare outputs: render plans, node positions, edge calculations
- [ ] Document differences (bug fixes, optimizations, vault-specific logic)
- [ ] Classify differences: critical / cosmetic / vault-specific

**Deliverable**: `inventory/behavioral-diff.md`

### Task 1.3: Dependency Mapping
- [ ] Map all imports/requires of live-graph modules across codebase
- [ ] Identify vault-specific config files
- [ ] Document plugin integrations per vault

**Deliverable**: `inventory/dependency-map.md`

## Phase 2: Canonical Selection & Preparation (Week 1-2)

### Task 2.1: Select Canonical Implementation
- [ ] Choose base: `Technical/Scripts/Rendering/live-graph/` (most complete)
- [ ] Merge critical fixes from other copies
- [ ] Create unified module structure (core/, governors/, workers/, rendering/, storage/)
- [ ] Add unified entry point (`index.js`) with explicit exports

**Deliverable**: `canonical/` directory structure

### Task 2.2: Configuration Abstraction
- [ ] Extract vault-specific configs to `.vault-config.json` per vault
- [ ] Create config schema with validation
- [ ] Implement config loader with merge strategy (base + vault override)

**Deliverable**: `canonical/config/`, `schemas/live-graph-config.schema.json`

### Task 2.3: Compatibility Layer
- [ ] Create shim modules for old import paths
- [ ] Ensure backward compatibility during transition
- [ ] Add deprecation warnings for old paths

**Deliverable**: `canonical/compat/`

## Phase 3: Migration & Validation (Week 2-3)

### Task 3.1: Vault-by-Vault Migration
For each vault (Algoritm, Calendula, Obs, Zetl, Angl):
- [ ] Update vault config to reference canonical
- [ ] Replace plugin entry point with canonical loader
- [ ] Run integration tests
- [ ] Verify graph rendering in Obsidian
- [ ] Document any vault-specific issues

**Deliverable**: `migration/vault-{name}-report.md`

### Task 3.2: Automated Regression Testing
- [ ] Create test suite covering: render loop, governors, workers, storage
- [ ] Run against all vaults pre- and post-migration
- [ ] Compare performance metrics (FPS, memory, frame time)
- [ ] Visual regression testing for graph layouts

**Deliverable**: `tests/regression-report.md`

### Task 3.3: Cleanup
- [ ] Remove all duplicate copies after validation
- [ ] Update `.gitignore` to prevent future duplication
- [ ] Add pre-commit hook to detect live-graph copies
- [ ] Update documentation

**Deliverable**: Cleanup commit

## Phase 4: Documentation & Handoff (Week 3)

### Task 4.1: Architecture Documentation
- [ ] Complete `architecture.md` (this file)
- [ ] Create migration guide for future vaults
- [ ] Document config schema

### Task 4.2: Developer Onboarding
- [ ] Add to developer docs: "How to add new vault using canonical live-graph"
- [ ] Create example vault config

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Vault-specific logic lost | Medium | High | Behavioral comparison (Task 1.2) before selection |
| Import path breakage | High | Medium | Compatibility layer (Task 2.3) |
| Performance regression | Low | High | Regression testing (Task 3.2) with benchmarks |
| Config conflicts | Medium | Medium | Config schema validation + merge strategy |

## Acceptance Criteria

- [ ] Single canonical live-graph implementation in `Technical/Scripts/Rendering/live-graph/`
- [ ] All 6 vaults successfully render graphs using canonical
- [ ] No performance regression (>5% frame time increase)
- [ ] All existing tests pass
- [ ] No duplicate live-graph files in repository
- [ ] Pre-commit hook prevents future duplication
- [ ] Documentation complete for adding new vaults

## Timeline

| Week | Focus | Deliverables |
|------|-------|--------------|
| 1 | Inventory, Analysis, Canonical Selection | Inventory docs, Canonical structure |
| 2 | Config Abstraction, Migration (3 vaults) | Config schema, 3 vault migrations |
| 3 | Migration (3 vaults), Testing, Cleanup | All vaults migrated, Test reports |
| 3-4 | Documentation, Handoff | Architecture docs, Migration guide |

## Resource Requirements

- **Developer A**: Lead migration, canonical development
- **Developer B**: Vault-specific testing, regression suite
- **QA**: Visual regression, performance benchmarking
- **DevOps**: Pre-commit hooks, CI integration

## Dependencies

- Issue #30 (Source-of-Truth Policy) - must complete first
- Issue #24 (Unified Graph Runtime Contract) - informs canonical API
- Issue #11 (Worker Pool) - uses canonical worker layer
- Issue #12 (Layout Cache) - uses canonical storage layer