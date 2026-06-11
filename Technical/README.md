# Technical Workspace

This folder groups project technical assets that are not primary vault content.

## Contents

- `Docs` - project plans, architecture notes, execution logs, and bug registries.
- `Scripts` - automation, Obsidian tooling, launchers, graph runtime scripts, and logs.
- `Scripts/Rendering` - graph rendering engine, RenderPlan, scheduler, renderer gate, and live-graph source bundle.
- `Tests` - Pester test suite for scripts and graph runtime contracts.
- `vault` - technical/test Obsidian vault content.

## Path Policy

- New technical code should live under `Technical/Scripts`.
- New render-facing JavaScript should live under `Technical/Scripts/Rendering`.
- New tests should live under `Technical/Tests`.
- New graph platform docs should live under `Technical/Docs/GraphPlatform`.
- Runtime vaults used for testing should live under `Technical/vault`.

The root `Scripts` folder may remain temporarily if a running background process is holding an old log file open.
