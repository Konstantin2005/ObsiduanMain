$plans = @{
  1 = @"
## Problem
The "Life" plugin needs a clearer, more stable user experience so the main flow is predictable and easier to use.

## Recommended Approach
Improve the plugin in small, testable steps so we preserve behavior while tightening UI, controls, and state handling.

## Implementation Plan
1. Audit the current UI, state flow, and failure modes.
2. Split visible controls and feedback into clearer states.
3. Harden lifecycle handling for start, stop, recovery, and reload.
4. Add smoke checks or manual verification notes.

## Acceptance Criteria
- [ ] The main plugin flow is clearer and more stable.
- [ ] Start/stop/recovery states are unambiguous.
- [ ] No regression in existing behavior.
- [ ] Verification is recorded.

## Verification
- Verify in app and capture before/after behavior notes.
"@
  2 = @"
## Problem
The repository contains duplicate Live Graph code paths, which increases maintenance cost and makes fixes inconsistent.

## Recommended Approach
Converge on one canonical implementation and remove the duplicates only after the active path is proven stable.

## Implementation Plan
1. Inventory duplicate files and references.
2. Identify the canonical source of truth.
3. Remove or redirect redundant code paths.
4. Run targeted tests and manual checks for broken imports.

## Acceptance Criteria
- [ ] Only one primary Live Graph implementation remains.
- [ ] No dead references to removed duplicates remain.
- [ ] Tests or smoke checks pass.
- [ ] Rollback path is clear.

## Verification
- Confirm the plugin loads and core graph behavior still works.
"@
  3 = @"
## Problem
Generated files and repo bloat make the repository harder to navigate, slower to review, and more expensive to maintain.

## Recommended Approach
Separate generated artifacts from source code and keep only what is needed for build, docs, or runtime.

## Implementation Plan
1. Identify generated or redundant files safe to remove.
2. Define retention rules for source vs generated artifacts.
3. Remove the unnecessary files in a controlled way.
4. Verify the repo still builds and essential docs remain intact.

## Acceptance Criteria
- [ ] Repo size is reduced meaningfully.
- [ ] Generated artifacts are removed or isolated.
- [ ] No source files are accidentally deleted.
- [ ] Build and tests still work.

## Verification
- Confirm the repository tree is cleaner and expected files remain available.
"@
  4 = @"
## Problem
Performance settings and benchmark definitions can drift apart, which makes results hard to trust and compare.

## Recommended Approach
Treat benchmark settings as part of the contract and keep them synchronized with runtime assumptions.

## Implementation Plan
1. Review current performance settings and benchmark sources.
2. Align names, thresholds, and defaults.
3. Remove conflicting or stale configuration.
4. Validate benchmark output still matches expected baselines.

## Acceptance Criteria
- [ ] Performance settings and benchmark definitions are consistent.
- [ ] No stale config causes misleading results.
- [ ] Benchmark reports remain reproducible.
- [ ] Verification is recorded.

## Verification
- Run the relevant benchmark or config check and compare outputs.
"@
  5 = @"
## Problem
The "Life" panel needs direct stop/recover controls so users can interrupt and safely restore the workflow.

## Recommended Approach
Keep the controls minimal and explicit, with predictable state transitions and clear recovery behavior.

## Implementation Plan
1. Define the control states and transitions.
2. Wire the stop and restore actions into the panel.
3. Add feedback for active, stopped, and recovering states.
4. Validate that restart/recovery returns to a safe state.

## Acceptance Criteria
- [ ] Stop control is available and works.
- [ ] Restore control returns the plugin to a safe state.
- [ ] State transitions are visible to the user.
- [ ] No regressions in the normal flow.

## Verification
- Test the controls manually in the app.
"@
  6 = @"
## Problem
Users need visibility into cycle progress and remaining links so they can understand whether the process is healthy or stalled.

## Recommended Approach
Expose lightweight progress feedback that reflects real runtime state without adding noise.

## Implementation Plan
1. Identify available progress and remaining-link signals.
2. Add a clear progress indicator to the UI.
3. Ensure it updates consistently during the cycle.
4. Validate against normal and partial-failure scenarios.

## Acceptance Criteria
- [ ] Progress is visible during the cycle.
- [ ] Remaining links are displayed clearly.
- [ ] UI stays readable under normal load.
- [ ] Verification notes are captured.

## Verification
- Observe progress changes during a real run.
"@
  7 = @"
## Problem
The current log/preview/recovery flow is too coarse, which makes it harder to inspect actions and recover safely.

## Recommended Approach
Make the panel more operational: log what happened, preview what will happen, and allow safe restoration.

## Implementation Plan
1. Audit the existing log and preview behavior.
2. Define the recovery model and its states.
3. Add a clearer journal/preview UI.
4. Validate safe restore paths and error handling.

## Acceptance Criteria
- [ ] User actions are logged in a readable form.
- [ ] Preview is available before risky actions.
- [ ] Recovery is safe and repeatable.
- [ ] No data-loss regressions are introduced.

## Verification
- Manually test preview, log inspection, and recovery.
"@
  8 = @"
## Problem
Discord synchronization needs an explicit implementation plan so the integration is reliable and maintainable.

## Recommended Approach
Design the sync as an integration boundary with clear triggers, retries, and failure visibility.

## Implementation Plan
1. Define sync direction, trigger points, and payload shape.
2. Implement the Discord integration path.
3. Add error handling and retry behavior.
4. Verify the sync with a safe test account or environment.

## Acceptance Criteria
- [ ] Sync behavior is clearly defined.
- [ ] Errors are surfaced instead of failing silently.
- [ ] Retries or fallback behavior are documented.
- [ ] Verification succeeds in a test scenario.

## Verification
- Exercise the integration in a controlled test run.
"@
  9 = @"
## Problem
Graph updates currently require too much work, which makes incremental changes expensive and slow.

## Recommended Approach
Move toward an incremental update path that reuses existing state where possible and only recomputes what changed.

## Implementation Plan
1. Identify the current rebuild bottlenecks.
2. Define the incremental update boundaries.
3. Implement partial recomputation or reuse logic.
4. Benchmark against the full rebuild path.

## Acceptance Criteria
- [ ] Updates no longer require full rebuilds for small changes.
- [ ] Correctness is preserved for incremental paths.
- [ ] Performance improves measurably.
- [ ] Benchmarks capture the delta.

## Verification
- Compare full rebuild vs incremental update timing.
"@
  10 = @"
## Problem
People graph connections should be prepared in the background so user-facing flows do not wait on expensive derivation.

## Recommended Approach
Treat connection generation as a cacheable background job with deterministic outputs.

## Implementation Plan
1. Define which connections can be precomputed.
2. Move connection generation into a background step.
3. Persist results in cache with invalidation rules.
4. Validate freshness and correctness after source changes.

## Acceptance Criteria
- [ ] Connections are generated outside the critical path.
- [ ] Cache invalidation is explicit.
- [ ] Results remain correct after updates.
- [ ] Background generation is observable.

## Verification
- Run a background generation cycle and inspect the cached output.
"@
  11 = @"
## Problem
Query planning, layout, and edge computation are too heavy for the main thread at scale.

## Recommended Approach
Move the expensive planning work into a worker pool and keep the main thread focused on orchestration and rendering.

## Implementation Plan
1. Identify the computation that can be moved to workers.
2. Define worker input/output contracts.
3. Add worker execution and result merging.
4. Validate cancellation, determinism, and fallback behavior.

## Acceptance Criteria
- [ ] Heavy planning work runs in workers.
- [ ] Main thread blocking is reduced.
- [ ] Cancellation and stale-result handling are safe.
- [ ] Performance gains are measurable.

## Verification
- Benchmark the main-thread path vs worker path.
"@
  12 = @"
## Problem
The graph layout should be cacheable so repeated renders do not recompute the same arrangement for large graphs.

## Recommended Approach
Introduce a layout cache with explicit invalidation rules tied to graph changes.

## Implementation Plan
1. Define stable layout cache keys.
2. Persist or reuse layout data between runs.
3. Invalidate the cache when graph inputs change.
4. Measure render improvements on large graphs.

## Acceptance Criteria
- [ ] Layout is reused when inputs are unchanged.
- [ ] Cache invalidation is correct.
- [ ] Large graph render time improves.
- [ ] Rollback remains possible.

## Verification
- Compare cached and uncached layout timings.
"@
  13 = @"
## Problem
Dense people graphs need gradual edge loading so the interface does not collapse under full data volume.

## Recommended Approach
Load and reveal connections progressively based on view state and importance.

## Implementation Plan
1. Define edge priority and visibility rules.
2. Implement staged edge loading.
3. Tie loading to zoom, focus, or viewport constraints.
4. Validate that partial loading preserves usability.

## Acceptance Criteria
- [ ] Edges load progressively instead of all at once.
- [ ] The graph remains usable at scale.
- [ ] Important connections remain visible first.
- [ ] Performance improves under dense datasets.

## Verification
- Test dense graph rendering with staged loading.
"@
  14 = @"
## Problem
We need evidence before switching to WebGL or OffscreenCanvas, because the wrong rendering backend can add complexity without improving real performance.

## Recommended Approach
Use benchmarks to decide whether a backend switch is justified.

## Implementation Plan
1. Define benchmark scenarios and thresholds.
2. Measure current canvas performance.
3. Prototype WebGL/OffscreenCanvas only if the benchmark supports it.
4. Record the decision and fallback strategy.

## Acceptance Criteria
- [ ] A benchmark-backed decision exists.
- [ ] The chosen backend is justified by measurements.
- [ ] Fallback strategy is documented.
- [ ] No speculative migration is merged blindly.

## Verification
- Review benchmark outputs and compare render paths.
"@
  15 = @"
## Problem
CPU and throughput pressure need explicit control so the runtime can degrade gracefully instead of becoming unstable.

## Recommended Approach
Add a runtime governor that reacts to load signals and adjusts work accordingly.

## Implementation Plan
1. Define pressure signals and budget rules.
2. Implement load-aware scheduling or throttling.
3. Expose telemetry for active mode and limits.
4. Validate behavior under benchmark pressure.

## Acceptance Criteria
- [ ] CPU and throughput pressure are controlled explicitly.
- [ ] Degraded modes are predictable.
- [ ] Telemetry shows when limits activate.
- [ ] Benchmarks validate the policy.

## Verification
- Run the benchmark suite under high load.
"@
  16 = @"
## Problem
Shard storage needs compaction and manifest recovery so stale artifacts do not accumulate and corruption can be repaired safely.

## Recommended Approach
Make storage maintenance explicit and recoverable, with clear diagnostics for any repair path.

## Implementation Plan
1. Define compaction criteria and safe cleanup rules.
2. Implement manifest recovery/rebuild logic.
3. Add diagnostics for corrupted or missing state.
4. Validate on large-scale fixtures.

## Acceptance Criteria
- [ ] Stale shard data is compacted safely.
- [ ] Manifest recovery works after drift or corruption.
- [ ] Diagnostics explain repairs.
- [ ] Tests cover normal and recovery paths.

## Verification
- Run compaction and recovery checks on representative data.
"@
  17 = @"
## Problem
The render loop still scans the full vault, which makes Live Graph performance scale poorly.

## Recommended Approach
Move vault traversal out of the frame loop and consume prepared graph data during render.

## Implementation Plan
1. Locate all full-vault reads in the render path.
2. Extract traversal into a precompute or async path.
3. Update rendering to use prepared snapshots.
4. Add performance checks for large vaults.

## Acceptance Criteria
- [ ] Full vault traversal is removed from the hot render path.
- [ ] Frame time becomes stable at scale.
- [ ] Functional behavior stays correct.
- [ ] Performance evidence is recorded.

## Verification
- Run a large-vault render smoke test and compare timings.
"@
  18 = @"
## Problem
Pan, zoom, and selection interactions can lag under load, which makes the graph feel unstable at scale.

## Recommended Approach
Treat interaction handling as performance-critical and optimize the event path before polishing visuals.

## Implementation Plan
1. Profile interaction hotspots.
2. Reduce redundant work during pan/zoom/selection.
3. Batch or defer expensive recomputation.
4. Measure interaction latency before and after.

## Acceptance Criteria
- [ ] Pan/zoom/selection stay responsive under load.
- [ ] Interaction latency is reduced measurably.
- [ ] No regressions in selection correctness.
- [ ] Results are documented.

## Verification
- Measure interaction performance on a large graph.
"@
  19 = @"
## Problem
Git automation is still split between the repository root and Technical, which increases confusion and maintenance cost.

## Recommended Approach
Consolidate automation into one canonical location and remove duplicated entry points only after the new path is safe.

## Implementation Plan
1. Inventory all remaining automation scripts and callers.
2. Decide the canonical home under Technical.
3. Move or wrap the remaining scripts.
4. Verify all references still work.

## Acceptance Criteria
- [ ] Only one canonical automation location remains.
- [ ] Existing workflows keep working.
- [ ] No broken script references remain.
- [ ] Migration notes are recorded.

## Verification
- Run the affected automation flows end to end.
"@
  20 = @"
## Problem
The runtime needs an explicit governor for CPU and throughput so load spikes do not overwhelm the user experience.

## Recommended Approach
Implement a controlled runtime policy that balances capacity, responsiveness, and graceful degradation.

## Implementation Plan
1. Define pressure signals and target budgets.
2. Add the control logic into the runtime.
3. Expose mode changes through logs or telemetry.
4. Validate the policy under benchmark conditions.

## Acceptance Criteria
- [ ] The runtime reacts to load with explicit policy.
- [ ] Degradation is visible and controlled.
- [ ] Performance benchmarks are meaningful.
- [ ] Rollback/fallback remains possible.

## Verification
- Run the relevant benchmark or smoke scenario.
"@
  21 = @"
## Problem
Shard storage must support compaction and manifest repair so the repository does not accumulate stale generated data.

## Recommended Approach
Apply a storage maintenance flow that is safe, observable, and easy to validate.

## Implementation Plan
1. Define compaction rules and recovery triggers.
2. Implement the maintenance logic.
3. Add diagnostics for cleanup and repair.
4. Validate on large-scale data.

## Acceptance Criteria
- [ ] Storage cleanup is safe and repeatable.
- [ ] Manifest recovery restores a usable state.
- [ ] Diagnostics explain the action taken.
- [ ] Tests cover the recovery path.

## Verification
- Verify compaction and recovery on representative fixtures.
"@
  22 = @"
## Problem
Query planning and layout work should not compete with UI responsiveness at large scale.

## Recommended Approach
Move expensive graph planning into workers and keep the main thread focused on orchestration and drawing.

## Implementation Plan
1. Define worker contracts for planning and layout.
2. Implement worker execution and result merging.
3. Add stale-result and cancellation safety.
4. Benchmark the worker path against the current baseline.

## Acceptance Criteria
- [ ] Heavy planning no longer blocks the main thread.
- [ ] Worker results are deterministic.
- [ ] Cancellation is safe.
- [ ] Performance benefits are measurable.

## Verification
- Compare UI responsiveness before and after worker offload.
"@
  23 = @"
## Problem
Live Graph currently traverses the full vault inside the render cycle, which creates avoidable performance pressure.

## Recommended Approach
Separate graph data preparation from rendering so frame work only consumes already-prepared inputs.

## Implementation Plan
1. Find the vault traversal currently happening in-frame.
2. Move it to a precompute or async preparation step.
3. Update the renderer to read from the prepared snapshot.
4. Add timing checks to confirm the hot path is lighter.

## Acceptance Criteria
- [ ] Full vault traversal is removed from render hot path.
- [ ] Frame timing improves or stabilizes.
- [ ] Output remains correct.
- [ ] Verification evidence is recorded.

## Verification
- Run a large-vault smoke test and inspect timings.
"@
}

foreach ($n in 1..23) {
  $path = Join-Path $PSScriptRoot "issue_$n.txt"
  Set-Content -LiteralPath $path -Value $plans[$n] -Encoding utf8
  gh issue edit $n -R Konstantin2005/ObsiduanMain --body-file $path | Out-Host
  Remove-Item -LiteralPath $path -Force
}
