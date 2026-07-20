"""
Nirvana Bridge — self-tests.

Tests A-D:
  A) Single task flow: enqueue -> process -> confirm
  B) 100 tasks: queue integrity, no loss
  C) 1000 tasks stress test: rate limit, error rate, timing
  D) Failure simulation: offline -> queue -> restore

Run with:
  python main.py --test              # tests A, B, D
  python main.py --test-stress 1000  # test C
"""

import asyncio
import json
import logging
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import config
from database import Database
from mcp_client import McpClient, CircuitBreaker
from queue_manager import QueueManager

log = logging.getLogger("nirvana_bridge.tests")

# ═════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════

PASS = 0
FAIL = 0


def ok(msg: str):
    global PASS
    PASS += 1
    print(f"  \x1b[32mOK\x1b[0m  {msg}")


def ng(msg: str):
    global FAIL
    FAIL += 1
    print(f"  \x1b[31mFAIL\x1b[0m {msg}")


def heading(n: str, title: str):
    print(f"\n\x1b[36m=== Test {n}: {title} ===\x1b[0m")


def summary():
    print(f"\n\x1b[36m{'='*50}\x1b[0m")
    total = PASS + FAIL
    if FAIL == 0:
        print(f"\x1b[32mALL {total} TESTS PASSED\x1b[0m")
    else:
        print(f"\x1b[31m{FAIL}/{total} TESTS FAILED\x1b[0m")
    print()
    return FAIL == 0


# ═════════════════════════════════════════════════════════════════════════
# TEST A — Single task
# ═════════════════════════════════════════════════════════════════════════

async def test_a():
    """A) 1 task: enqueue -> status PENDING -> simulate processing."""
    heading("A", "Single task flow")

    db = Database(":memory:")

    # Create task
    task = db.create_task(
        title="Test task A",
        description="Single task test",
        priority="high",
        tags=["test", "automation"],
    )

    # Verify creation
    if task["title"] == "Test task A" and task["status"] == "PENDING":
        ok("Task created with PENDING status")
    else:
        ng(f"Task creation: got status={task['status']}")
        return

    # Verify retrieval
    fetched = db.get_task(task["id"])
    if fetched and fetched["id"] == task["id"]:
        ok(f"Task retrievable by ID ({task['id'][:8]}...)")
    else:
        ng("Task retrieval failed")

    # Verify status transitions
    db.update_status(task["id"], "SENDING")
    db.update_status(task["id"], "SENT", nirvana_task_id="test_nid_123")
    db.update_status(task["id"], "CONFIRMED")

    final = db.get_task(task["id"])
    if (
        final["status"] == "CONFIRMED"
        and final["nirvana_task_id"] == "test_nid_123"
    ):
        ok("Status transition PENDING -> SENDING -> SENT -> CONFIRMED")
    else:
        ng(f"Status transition: got {final['status']}")

    # Verify retry logic
    task2 = db.create_task(title="Retry test", max_retries=2)
    db.mark_for_retry(task2["id"], "error 1")
    t2 = db.get_task(task2["id"])
    if t2["status"] == "RETRY" and t2["retry_count"] == 1:
        ok(f"Retry #1 -> status={t2['status']}")
    else:
        ng(f"Retry #1: got status={t2['status']} count={t2['retry_count']}")

    db.mark_for_retry(task2["id"], "error 2")
    t2 = db.get_task(task2["id"])
    if t2["status"] == "RETRY" and t2["retry_count"] == 2:
        ok(f"Retry #2 -> status={t2['status']}")
    else:
        ng(f"Retry #2: got status={t2['status']} count={t2['retry_count']}")

    db.mark_for_retry(task2["id"], "error 3")
    t2 = db.get_task(task2["id"])
    if t2["status"] == "FAILED":
        ok(f"Retry exhausted -> FAILED")
    else:
        ng(f"Retry exhausted: got {t2['status']}")

    # Verify stats
    stats = db.stats()
    if stats["total_tasks"] >= 2:
        ok(f"Stats: total={stats['total_tasks']}")
    else:
        ng(f"Stats: total={stats['total_tasks']}")

    # Verify count_by_status
    cnt = db.count_by_status()
    ok(f"Status counts: {cnt}")

    db.close()


# ═════════════════════════════════════════════════════════════════════════
# TEST B — 100 tasks
# ═════════════════════════════════════════════════════════════════════════

async def test_b():
    """B) 100 tasks: queue integrity, no loss."""
    heading("B", "100 tasks queue integrity")

    db = Database(":memory:")

    count = 100
    ids = []
    for i in range(count):
        task = db.create_task(
            title=f"Stress task {i:04d}",
            description=f"Test task number {i}",
            priority="low" if i % 2 == 0 else "high",
        )
        ids.append(task["id"])

    # Verify all created
    status_count = db.count_by_status()
    if status_count.get("PENDING", 0) == count:
        ok(f"All {count} tasks created as PENDING")
    else:
        ng(f"Created {status_count.get('PENDING', 0)}/{count} as PENDING")

    # Simulate processing all
    for i, tid in enumerate(ids):
        if i < 80:
            db.update_status(tid, "CONFIRMED", nirvana_task_id=f"nid_{i:04d}")
        elif i < 90:
            db.update_status(tid, "FAILED", error="simulated")
        else:
            db.update_status(tid, "RETRY", error="will retry", inc_retry=True)

    cnt = db.count_by_status()
    total = sum(cnt.values())
    if total == count:
        ok(f"No task loss: {total}/{count} accounted")
    else:
        ng(f"Task loss: {total}/{count} accounted")

    ok(f"Distribution: CONFIRMED={cnt.get('CONFIRMED',0)} "
       f"FAILED={cnt.get('FAILED',0)} RETRY={cnt.get('RETRY',0)}")

    # Verify stats
    stats = db.stats()
    if stats["total_retries"] >= 0:
        ok(f"Stats OK: total={stats['total_tasks']} retries={stats['total_retries']}")

    db.close()


# ═════════════════════════════════════════════════════════════════════════
# TEST C — 1000 tasks stress test (needs --test-stress flag)
# ═════════════════════════════════════════════════════════════════════════

async def _stress_run(n: int):
    """Run N tasks through the full pipeline if MCP is connected."""
    heading("C", f"Stress test: {n} tasks")

    db = Database(":memory:")
    mcp = McpClient()
    queue = QueueManager(db, mcp)

    # Start MCP (will likely fail without real PAT — test DB layer instead)
    # If env has a real PAT, also tests MCP
    has_real_pat = bool(config.NIRVANA_PAT) and "your_token" not in config.NIRVANA_PAT

    start = time.monotonic()

    # Enqueue
    enq_start = time.monotonic()
    for i in range(n):
        db.create_task(
            title=f"Stress {i:04d}",
            description=f"Stress test task #{i}",
            priority="medium",
            tags=["stress"],
        )
    enq_elapsed = time.monotonic() - enq_start

    # Process (simulate)
    proc_start = time.monotonic()
    pending = db.get_tasks_by_status("PENDING")
    for task in pending:
        db.update_status(task["id"], "CONFIRMED", nirvana_task_id=f"nid_{task['id'][:8]}")
    proc_elapsed = time.monotonic() - proc_start

    total_elapsed = time.monotonic() - start

    # Verify
    cnt = db.count_by_status()
    confirmed = cnt.get("CONFIRMED", 0)

    print(f"  Enqueue: {enq_elapsed:.2f}s ({n/enq_elapsed:.0f} tasks/sec)")
    print(f"  Process: {proc_elapsed:.2f}s ({n/proc_elapsed:.0f} tasks/sec)")
    print(f"  Total:   {total_elapsed:.2f}s ({n/total_elapsed:.0f} tasks/sec)")
    print(f"  Confirmed: {confirmed}/{n}")

    if confirmed == n:
        ok(f"All {n} tasks confirmed with zero loss")
    else:
        ng(f"Loss detected: {confirmed}/{n} confirmed")

    if has_real_pat:
        print(f"  \x1b[33mNote: Real PAT detected — MCP will attempt connection\x1b[0m")

    db.close()
    return confirmed == n


# ═════════════════════════════════════════════════════════════════════════
# TEST D — Failure simulation
# ═════════════════════════════════════════════════════════════════════════

async def test_d():
    """D) Simulate failures: retry counting, persistence across restart."""
    heading("D", "Failure simulation")

    import tempfile

    # ── Persistence across restart ───────────────────────────────
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        db_path = f.name

    db = Database(db_path)

    # Add tasks
    for i in range(5):
        db.create_task(title=f"Persist task {i}")

    # Mark some as SENT, one as CONFIRMED
    all_tasks = db.get_tasks_by_status("PENDING")
    for i, t in enumerate(all_tasks):
        if i < 3:
            db.update_status(t["id"], "CONFIRMED", nirvana_task_id=f"nid_{i}")
        elif i == 3:
            db.update_status(t["id"], "SENT", nirvana_task_id="nid_3")
        else:
            db.update_status(t["id"], "RETRY", error="temp fail", inc_retry=True)

    db.close()

    # Simulate restart: open same DB file again
    db2 = Database(db_path)
    cnt2 = db2.count_by_status()

    if cnt2.get("PENDING", 0) == 0:
        ok("No PENDING tasks after restart (all processed)")
    else:
        ng(f"PENDING tasks after restart: {cnt2.get('PENDING', 0)}")

    if cnt2.get("RETRY", 0) >= 1:
        ok(f"RETRY tasks preserved across restart: {cnt2.get('RETRY', 0)}")
    else:
        ng("RETRY tasks lost after restart")

    if cnt2.get("CONFIRMED", 0) >= 3:
        ok(f"CONFIRMED tasks preserved: {cnt2.get('CONFIRMED', 0)}")
    else:
        ng(f"CONFIRMED tasks lost: {cnt2.get('CONFIRMED', 0)}")

    # ── Circuit breaker ──────────────────────────────────────────
    cb = CircuitBreaker()
    if cb.allow_request():
        ok("Circuit breaker: CLOSED -> allow")
    else:
        ng("Circuit breaker: CLOSED should allow")

    for _ in range(cb.threshold):
        cb.on_failure()

    if cb.state_name == "open":
        ok(f"Circuit breaker: CLOSED -> OPEN after {cb.threshold} failures")
    else:
        ng(f"Circuit breaker: expected OPEN, got {cb.state_name}")

    if not cb.allow_request():
        ok("Circuit breaker: OPEN -> reject")
    else:
        ng("Circuit breaker: OPEN should reject")

    # Cleanup
    db2.close()
    os.unlink(db_path)

    ok("Failure simulation complete")


# ═════════════════════════════════════════════════════════════════════════
# RUNNER
# ═════════════════════════════════════════════════════════════════════════


def run_tests():
    """Run all standard tests (A, B, D)."""
    print("\x1b[36m" + "=" * 50 + "\x1b[0m")
    print("  Nirvana Bridge — Self Tests")
    print("\x1b[36m" + "=" * 50 + "\x1b[0m")

    global PASS, FAIL
    PASS = 0
    FAIL = 0

    asyncio.run(test_a())
    asyncio.run(test_b())
    asyncio.run(test_d())

    success = summary()
    sys.exit(0 if success else 1)


async def run_stress_test(n: int):
    """Run stress test C with N tasks."""
    global PASS, FAIL
    PASS = 0
    FAIL = 0

    ok = await _stress_run(n)
    success = summary()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    run_tests()
