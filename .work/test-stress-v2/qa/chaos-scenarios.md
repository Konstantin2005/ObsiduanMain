# Chaos Scenarios (5)

## CS-01: "3 Users, 1 Block, Network Delay"
**Setup:** 3 users, 1 block, 500ms artificial network delay
**Action:** All 3 users type simultaneously in same block
**Expected:** LWW merge, characters interleave correctly
**Result:** ✅ Characters merged per HLC order, no data loss
**Weakness found:** None (CRDT guarantee holds)

## CS-02: "Offline Flood + Partial Sync" ⚠️ SYSTEM BROKEN
**Setup:** User goes offline, makes 50 changes
**Action:** Network restores, sync starts, drops at 30/50
**Expected:** Retry, no duplicate events, partial state
**Result:** ⚠️ Retry succeeded but UX delay 30s (max backoff)
**Weakness found:** Retry backoff too aggressive for UX

## CS-03: "Stale Client Attack"
**Setup:** Client with HLC = 0 (old/stale)
**Action:** Sends event with HLC = 0 to server at HLC = 100
**Expected:** Server assigns new HLC, event applied
**Result:** ✅ Event applied with HLC = 101
**Weakness found:** No stale client detection

## CS-04: "Tenant Isolation Breach Attempt"
**Setup:** User A in Tenant 1
**Action:** Manually modifies API call to target Tenant 2 workspace
**Expected:** 403 Forbidden
**Result:** ✅ 403, event logged in security log
**Weakness found:** None for mock (API-level check works)

## CS-05: "Race Condition: 3 Blocks, 3 Users, Simultaneous Move"
**Setup:** 3 users, 3 blocks, 1 target position
**Action:** All 3 users move their block to same position X simultaneously
**Expected:** All blocks at different fractional indices
**Result:** ✅ Fractional index prevented collision, all blocks visible
**Weakness found:** None (CRDT + fractional index correct)
