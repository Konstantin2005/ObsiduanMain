# Conflict Logic (CRDT)

## LWW-Register (Content)
```
Rule: last-write-wins per character position
HLC determines "last"
Characters may interleave:
  User A: "Hello" at HLC=50
  User B: "World" at HLC=51
  Result: "Hello" + "World" or "World" + "Hello" (depends on char positions)
```

## OR-Set (Block Membership)
```
Add: block added to set
Remove: block tomstoned
Merge: union of two sets (both adds win over removes)
Если User A добавил блок, User B удалил:
  - A: add(block) at HLC=50
  - B: remove(block) at HLC=51
  - После merge: block exists? → depends on causality
  - Если concurrent → block exists (add wins per CRDT spec)
```

## Position Conflict
```
Two users insert at same fractional index:
  User A: insert at "abc"
  User B: insert at "abc"
  CRDT: both blocks exist
  Order: deterministic by userId (UUID comparison)
```

## Delete-Update Conflict
```
User A deletes block, User B updates:
  - delete wins (tombstone)
  - update ignored
  - User B gets 404 on next sync
```
