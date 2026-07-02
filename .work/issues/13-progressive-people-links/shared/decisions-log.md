# Decisions Log: Progressive People Links

## ADR-1: Weight-based prioritization with interaction boost
Strongest connections first; relevant edges promoted on interaction.

## ADR-2: requestAnimationFrame batching
One batch per frame to avoid jank.

## ADR-3: Nodes first, edges progressive
Fast initial paint with graph structure visible.

## ADR-4: Threshold-based activation
Progressive mode only for >500 edges (configurable).

## ADR-5: Pre-emption on user interaction
Hover/click loads that node's edges immediately.
