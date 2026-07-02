# Resilient Graph Platform Bug Registry

Use this template:

```md
## BUG-ID
- Area:
- Severity: P0/P1/P2/P3
- Status: TODO/DOING/FIXED/REGRESSION
- Reproduction:
- Expected:
- Actual:
- Suspected cause:
- Files:
- Test coverage:
- Recovery behavior:
```

## BUG-A002
- Area: Safe Native Graph
- Severity: P1
- Status: FIXED
- Reproduction: Obsidian restart rewrote safe graph physics to heavy values while keeping `tag:#graph/backbone`.
- Expected: `repelStrength <= 1.5`, `linkDistance <= 30`.
- Actual: observed `repelStrength=10`, `linkDistance=250`.
- Suspected cause: native graph persisted runtime settings after startup before guard re-applied full policy.
- Files: `Calendula-20K/.obsidian/graph.json`, `Calendula-20K/.obsidian/plugins/calendula-graph-guard/main.js`.
- Test coverage: extend safe startup tests to validate physics and guard drift repair.
- Recovery behavior: offline switcher reapplies `fast-backbone`; guard quarantine also repairs drift and logs incident.

## BUG-I001
- Area: Ultra Graph startup pipeline
- Severity: P1
- Status: FIXED
- Reproduction: Applying `Set-Calendula20KGraphProfile.ps1 -Profile fast-backbone` rewrote `community-plugins.json` with only `calendula-graph-guard`.
- Expected: safe startup keeps both guard and `calendula-ultra-graph` enabled.
- Actual: Ultra Graph could be disabled by the offline safety switcher.
- Suspected cause: hardcoded single-plugin JSON writer in the profile switcher.
- Files: `Technical/Scripts/Obsidian/Set-Calendula20KGraphProfile.ps1`, `Calendula-20K/.obsidian/community-plugins.json`.
- Test coverage: Pester temp-vault profile switcher test now verifies both community plugins.
- Recovery behavior: profile switcher writes both plugins through the shared UTF-8 JSON writer.

## BUG-K001
- Area: Ultra Graph degraded modes
- Severity: P2
- Status: FIXED
- Reproduction: First Ultra Graph frame was classified as `interactive` without user input in deterministic tests.
- Expected: first render starts in `steady` mode unless input has happened.
- Actual: `lastInteractionAt = 0` made early runtime frames look like input-burst frames.
- Suspected cause: startup timestamp used as a real interaction timestamp.
- Files: `Calendula-20K/.obsidian/plugins/calendula-ultra-graph/main.js`.
- Test coverage: Ultra Graph lifecycle test verifies first-frame steady health and emergency degradation at low FPS.
- Recovery behavior: initialize `lastInteractionAt` to negative infinity.
