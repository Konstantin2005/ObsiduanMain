# Test Cases (22)

## Core CRUD
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-01 | Create workspace | 201 |
| TC-02 | Create text block | 200, block in workspace |
| TC-03 | Update block content | 200, version incremented |
| TC-04 | Delete block | 200, block tomstoned |
| TC-05 | Move block position | 200, fractional index updated |

## CRDT Conflicts
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-06 | 3 users insert at same position | All 3 blocks exist |
| TC-07 | 2 users edit same block concurrently | LWW merge, no data loss |
| TC-08 | Delete while editing | Delete wins |
| TC-09 | Move to occupied position | Fractional index inserts between |
| TC-10 | Duplicate event replay | Idempotent, ignored |
| TC-11 | Out-of-order event arrival | CRDT merge correct |

## Multi-tenant & Permissions
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-12 | Add user as editor | 200, can edit |
| TC-13 | Add user as viewer | 200, read-only |
| TC-14 | Viewer tries to edit | 403 |
| TC-15 | Tenant A accesses Tenant B | 403 |
| TC-16 | Viewer escalates to owner | 403, logged |
| TC-17 | Owner removes user | 200, user removed |

## Sync
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-18 | Pull sync since HLC | Events since HLC |
| TC-19 | Push 100 events batch | All applied |
| TC-20 | Partial sync (network loss) | Retry, no duplicate |
| TC-21 | Stale client sends old event | Applied with new HLC |
| TC-22 | Offline → 50 edits → sync | All merged correctly |
