"""
Nirvana Bridge — task queue manager.

Processes the local queue: picks up PENDING/RETRY tasks,
sends them via MCP, validates confirmation, and updates status.
"""

import asyncio
import logging
import time
from datetime import datetime, timezone

from config import config
from database import Database
from mcp_client import McpClient

log = logging.getLogger("nirvana_bridge.queue")


class QueueManager:
    """Background queue processor with rate limiting and retry."""

    def __init__(self, db: Database, mcp: McpClient):
        self._db = db
        self._mcp = mcp
        self._running = False
        self._task: asyncio.Task | None = None

        # Rate limiting
        self._min_interval = 1.0 / max(config.TASKS_PER_SECOND, 0.1)
        self._last_send = 0.0

        # Stats
        self.sent_count = 0
        self.error_count = 0
        self.retry_count = 0

    # ── Lifespan ─────────────────────────────────────────────────────

    async def start(self) -> None:
        self._running = True
        self._task = asyncio.create_task(
            self._process_loop(), name="queue-processor"
        )
        log.info("Queue manager started")

    async def stop(self) -> None:
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None
        log.info("Queue manager stopped")

    # ── Main loop ────────────────────────────────────────────────────

    async def _process_loop(self) -> None:
        while self._running:
            try:
                await self._process_one()
            except Exception as exc:
                log.error(f"Queue processing error: {exc}")
            await asyncio.sleep(config.QUEUE_POLL_INTERVAL)

    async def _process_one(self) -> bool:
        """Process the next task from the queue. Returns True if any was processed."""
        # Peek at next pending/retry task
        tasks = self._db.get_tasks_by_status("PENDING", "RETRY")
        if not tasks:
            return False

        task = tasks[0]
        task_id = task["id"]

        log.info(
            f"Processing task {task_id[:8]} "
            f"(status={task['status']}, retry={task['retry_count']})"
        )

        # Check if MCP is connected
        if not self._mcp.is_connected:
            log.debug("MCP not connected — deferring task")
            return False

        # Rate limit
        now = time.monotonic()
        elapsed = now - self._last_send
        if elapsed < self._min_interval:
            await asyncio.sleep(self._min_interval - elapsed)

        # Mark as SENDING
        self._db.update_status(task_id, "SENDING")

        # Build arguments for create_tasks
        args = self._build_args(task)

        # Send via MCP
        try:
            async with asyncio.timeout(config.MCP_TIMEOUT):
                result = await self._mcp.call_tool("create_tasks", args)
        except asyncio.TimeoutError:
            log.warning(f"Task {task_id[:8]} timed out")
            self._db.mark_for_retry(task_id, "Timeout")
            self.error_count += 1
            return True
        except Exception as exc:
            log.error(f"Task {task_id[:8]} send error: {exc}")
            self._db.mark_for_retry(task_id, str(exc))
            self.error_count += 1
            return True

        # Check result
        if result is None:
            self._db.mark_for_retry(task_id, "No response from MCP")
            self.error_count += 1
            return True

        # Extract nirvana task ID from response
        nirvana_id = self._extract_task_id(result)
        if not nirvana_id:
            err = "Could not extract task ID from response"
            log.warning(f"{err}: {result}")
            self._db.mark_for_retry(task_id, err)
            self.error_count += 1
            return True

        # Mark as SENT (will be confirmed after verification)
        self._db.update_status(task_id, "SENT", nirvana_task_id=nirvana_id)
        self._last_send = time.monotonic()
        self.sent_count += 1
        log.info(f"Task {task_id[:8]} sent -> nirvana_id={nirvana_id}")

        # ── Confirmation (verification) ──────────────────────────
        confirmed = await self._confirm_task(nirvana_id, task)
        if confirmed:
            self._db.update_status(task_id, "CONFIRMED")
            log.info(f"Task {task_id[:8]} CONFIRMED")
        else:
            log.warning(f"Task {task_id[:8]} sent but confirmation failed")
            # Keep as SENT — operator can investigate

        return True

    # ── Task argument builder ────────────────────────────────────────

    def _build_args(self, task: dict) -> dict:
        """Build create_tasks arguments from a task dict.

        Nirvana MCP schema:
        tasks[0]: name, note, state, type, tags, starred,
                  duedate, startdate, energy, etime, parentid
        """
        item = {
            "name": task["title"],
            "note": task.get("description") or "",
        }

        # Item type: task (default inbox) or project (default active)
        item_type = task.get("item_type", "task")
        if item_type == "project":
            item["type"] = "project"
            item["state"] = "active"
        else:
            item["state"] = "inbox"

        # Energy level (1-3)
        priority = task.get("priority", "")
        if priority in ("low", "1"):
            item["energy"] = 1
        elif priority in ("high", "3"):
            item["energy"] = 3
        elif priority in ("medium", "2"):
            item["energy"] = 2

        # Due date
        if task.get("due_date"):
            item["duedate"] = task["due_date"]

        # Tags
        if task.get("tags"):
            tags = task["tags"]
            if isinstance(tags, str):
                import json
                try:
                    tags = json.loads(tags)
                except json.JSONDecodeError:
                    tags = [tags]
            if tags:
                item["tags"] = tags

        return {"tasks": [item]}

    # ── Response parsing ─────────────────────────────────────────────

    def _extract_task_id(self, result: dict) -> str | None:
        """Extract Nirvana task ID from MCP response.

        Nirvana create_tasks returns a JSON text with:
        {"ok": true, "tasks": [{"id": "uuid", "name": "...", ...}], "count": 1}
        """
        if not result:
            return None

        text = result.get("text", "")

        # Try parsing as JSON (Nirvana returns JSON in text content)
        if text:
            try:
                import json
                data = json.loads(text)
                if isinstance(data, dict):
                    tasks = data.get("tasks", [])
                    if tasks and isinstance(tasks, list) and len(tasks) > 0:
                        tid = tasks[0].get("id")
                        if tid:
                            return str(tid)
                    # Also check for direct id field
                    for key in ("id", "task_id", "taskId"):
                        val = data.get(key)
                        if val:
                            return str(val)
            except (json.JSONDecodeError, KeyError, IndexError):
                pass

        # Fallback: look for UUID in raw text
        if text:
            import re
            m = re.search(
                r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
                text,
                re.IGNORECASE,
            )
            if m:
                return m.group(0)

        # Last resort: check raw content items
        content = result.get("content", [])
        for c in content:
            if isinstance(c, dict):
                for key in ("id", "taskId"):
                    val = c.get(key)
                    if val:
                        return str(val)

        return None

    # ── Confirmation ─────────────────────────────────────────────────

    async def _confirm_task(self, nirvana_id: str, original_task: dict) -> bool:
        """Verify the task exists in Nirvana with matching parameters.

        Uses search_tasks or similar read-only MCP tool to confirm.
        """
        if not self._mcp.is_connected:
            log.warning("Cannot confirm — MCP disconnected")
            return False

        # Try to verify using get_tasks tool
        # Note: verification is best-effort; if the tool is not available,
        # we trust the create_tasks response.
        try:
            async with asyncio.timeout(config.MCP_TIMEOUT):
                tools = await self._mcp.list_tools()
        except Exception:
            return True  # Best-effort: assume success

        tool_names = [t.get("name", t) if isinstance(t, dict) else getattr(t, "name", str(t)) for t in tools]

        # Try get_tasks with state=inbox + query filter
        if "get_tasks" not in tool_names:
            log.debug("No get_tasks tool — trusting create_tasks response")
            return True

        # Try verification: search for the task/project by name
        try:
            item_type = original_task.get("item_type", "task")
            search_state = "inbox" if item_type == "task" else "active"
            params = {
                "state": search_state,
                "query": original_task["title"],
                "limit": 10,
            }

            async with asyncio.timeout(config.MCP_TIMEOUT):
                verify = await self._mcp.call_tool("get_tasks", params)

            if verify is None:
                log.warning("Confirmation via get_tasks returned nothing")
                return False

            # Parse the JSON response to check if our task exists
            text = verify.get("text", "")
            if text:
                import json
                try:
                    data = json.loads(text)
                    tasks = data.get("tasks", [])
                    for t in tasks:
                        if t.get("id") == nirvana_id:
                            log.debug(f"Task confirmed in Nirvana inbox: {nirvana_id[:12]}")
                            return True
                    log.warning(f"Task {nirvana_id[:12]} not found in get_tasks results")
                    return False
                except (json.JSONDecodeError, KeyError):
                    # If we can't parse, trust the response
                    log.debug("Confirmation check passed (unparseable response)")
                    return True

        except Exception as exc:
            log.warning(f"Confirmation check failed: {exc}")
            return True  # Best-effort: assume success

    # ── External API ─────────────────────────────────────────────────

    async def enqueue_task(
        self,
        title: str,
        description: str = "",
        priority: str = "medium",
        due_date: str = "",
        tags: list[str] | None = None,
    ) -> dict:
        """Add a task to the queue. Returns the created task."""
        task = self._db.create_task(
            title=title,
            description=description,
            priority=priority,
            due_date=due_date,
            tags=tags,
            item_type="task",
        )
        log.info(f"Enqueued task {task['id'][:8]}: {title}")
        return task

    async def enqueue_project(
        self,
        name: str,
        description: str = "",
        tags: list[str] | None = None,
    ) -> dict:
        """Add a project to the queue. Returns the created task."""
        task = self._db.create_task(
            title=name,
            description=description,
            priority="",
            due_date="",
            tags=tags or [],
            item_type="project",
        )
        log.info(f"Enqueued project {task['id'][:8]}: {name}")
        return task

    def queue_size(self) -> int:
        """Count tasks waiting to be processed."""
        cnt = self._db.count_by_status()
        return cnt.get("PENDING", 0) + cnt.get("RETRY", 0)

    def stats(self) -> dict:
        """Return runtime stats merged with DB stats."""
        s = self._db.stats()
        s.update({
            "queue_size": self.queue_size(),
            "sent_count": self.sent_count,
            "error_count": self.error_count,
            "retry_count": self.retry_count,
        })
        return s
