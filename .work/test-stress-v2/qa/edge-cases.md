# Edge Cases (10)

| # | Edge Case | Ожидаемое поведение |
|---|---|---|
| EC-01 | Empty workspace (0 blocks) | Render empty state + "Add block" CTA |
| EC-02 | Block with whitespace-only content | Treat as empty, trim on save |
| EC-03 | Fractional index precision overflow | Trigger rebalancing (O(n)) |
| EC-04 | HLC counter overflow | Reset counter, clock sync |
| EC-05 | User disconnects during event push | Retry with backoff, dedup |
| EC-06 | Two users with same display name | Different UUIDs, no conflict |
| EC-07 | Delete already deleted block | Idempotent (tombstone exists) |
| EC-08 | Move block to its current position | No-op, no event generated |
| EC-09 | Create workspace with empty name | 400 validation error |
| EC-10 | Add existing user to workspace | 409 conflict |
