# Architectural Decisions: Progressive People Links

## ADR-1: Weight-based edge prioritization with interaction boost
**Status**: Accepted
**Context**: Not all edges are equally important; users care most about strong connections.
**Decision**: Sort edges by weight (co-occurrence frequency) first; boost edges related to visible/interacted nodes.
**Consequence**: Most meaningful connections appear first; relevant edges promoted when user interacts.

## ADR-2: requestAnimationFrame batching (1 batch per frame)
**Status**: Accepted
**Context**: Adding too many edges in one frame causes jank.
**Decision**: Load one batch (configurable size, default 100) per requestAnimationFrame callback.
**Consequence**: Smooth progressive loading; total load time increases but no frame drops.

## ADR-3: Render nodes immediately, add edges progressively
**Status**: Accepted
**Context**: Nodes are cheap to render (position + label); edges are expensive (lines, arrows, labels).
**Decision**: All nodes render immediately. Edges load in batches.
**Consequence**: Fast initial paint; users see graph structure instantly and connections fill in.

## ADR-4: Threshold-based progressive mode (not always-on)
**Status**: Accepted
**Context**: For small graphs, progressive loading adds unnecessary complexity.
**Decision**: Progressive mode activates only when total edges exceed 500 (configurable threshold).
**Consequence**: Simple paths for small graphs; progressive only when beneficial.

## ADR-5: Pre-emption of batches on user interaction
**Status**: Accepted
**Context**: When user hovers a node, they want to see its connections immediately.
**Decision**: User interaction pauses current batch sequence and immediately loads all edges for the interacted node.
**Consequence**: Instant feedback on interaction; slight delay in overall loading progression.
