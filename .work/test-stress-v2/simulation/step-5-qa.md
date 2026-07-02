# Step 5: QA — Chaos Testing

## Тесты
- 22 test cases (CRDT, permissions, sync, edge)
- 10 edge cases documented
- 5 chaos scenarios executed

## Chaos Results
| Scenario | Result | Weakness Found |
|---|---|---|
| CS-01: 3 users, 1 block, delay | ✅ | None |
| CS-02: Offline flood + partial sync | ⚠️ BROKEN | Retry backoff 30s |
| CS-03: Stale client attack | ✅ | No stale detection |
| CS-04: Tenant isolation breach | ✅ | 403 correct |
| CS-05: Race condition (3 moves) | ✅ | Fractional index works |

## QA Verdict
System stability: **8/10**
- CRDT invariants hold under adversarial conditions
- Retry backoff is UX concern
- System properly broken in CS-02

## Результат
QA завершён. Найденные проблемы переданы Reviewer.
