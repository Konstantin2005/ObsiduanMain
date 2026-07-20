"""
Nirvana Bridge — HTTP API.

Full REST proxy to all Nirvana MCP tools:
  create_tasks  (queued)  POST /api/tasks
  get_tasks               GET  /api/tasks
  update_tasks            PUT  /api/tasks
  get_tags                GET  /api/tags
  get_task_counts         GET  /api/task-counts
  generic call            POST /api/mcp/{tool}

Convenience shortcuts:
  create project          POST /api/projects
  delete task/project     DELETE /api/tasks/{id}
  complete task           POST /api/tasks/{id}/complete
  set energy              PUT  /api/tasks/{id}/energy
  set schedule            PUT  /api/tasks/{id}/schedule
  move task               PUT  /api/tasks/{id}/move
"""

import json
import logging
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException, Request, Path, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from config import config

log = logging.getLogger("nirvana_bridge.http")

# ═════════════════════════════════════════════════════════════════════════
# Pydantic models
# ═════════════════════════════════════════════════════════════════════════


class TaskIn(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    description: str = ""
    priority: str = "medium"  # low, medium, high
    due_date: str = ""
    tags: list[str] = []


class ProjectIn(BaseModel):
    name: str = Field(min_length=1, max_length=500)
    description: str = ""
    tags: list[str] = []


class TaskUpdate(BaseModel):
    id: str = Field(min_length=1)
    name: str | None = None
    note: str | None = None
    state: str | None = None
    completed: bool | None = None
    starred: bool | None = None
    tags: list[str] | None = None
    energy: int | None = Field(default=None, ge=0, le=3)
    etime: int | None = Field(default=None, ge=0)
    duedate: str | None = None
    startdate: str | None = None
    parentid: str | None = None
    waitingfor: str | None = None


class McpCall(BaseModel):
    params: dict = {}


# ═════════════════════════════════════════════════════════════════════════
# App factory
# ═════════════════════════════════════════════════════════════════════════


def create_app(mcp_client=None, queue_manager=None) -> FastAPI:
    """Build the FastAPI application with optional dependencies."""
    app = FastAPI(
        title="Nirvana Bridge API",
        version="2.0.0",
        description="Full REST API for Nirvana MCP — tasks, projects, tags, energy, schedule",
    )

    start_time = datetime.now(timezone.utc)

    # ── Helpers ───────────────────────────────────────────────────

    async def _mcp_call(tool: str, params: dict) -> dict:
        if mcp_client is None:
            raise HTTPException(503, "MCP client not available")
        result = await mcp_client.call_tool(tool, params)
        if result is None:
            raise HTTPException(502, f"MCP tool {tool!r} returned no result")
        return result

    def _parse_text(result: dict) -> dict:
        """Extract JSON payload from MCP text response."""
        text = result.get("text", "")
        if text:
            try:
                return json.loads(text)
            except json.JSONDecodeError:
                pass
        return result

    # ── Middleware ────────────────────────────────────────────────

    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        response = await call_next(request)
        if request.url.path in ("/health",):
            return response
        log.info(f"{request.method} {request.url.path} -> {response.status_code}")
        return response

    # ═══════════════════════════════════════════════════════════════
    # TASKS
    # ═══════════════════════════════════════════════════════════════

    @app.post("/api/tasks")
    async def create_task(body: TaskIn):
        """Create a task (queued for reliable async processing)."""
        if queue_manager is None:
            raise HTTPException(503, "Queue manager not available")
        task = await queue_manager.enqueue_task(
            title=body.title,
            description=body.description,
            priority=body.priority,
            due_date=body.due_date,
            tags=body.tags,
        )
        return {"status": "queued", "id": task["id"], "message": f"Task {task['id'][:8]} queued"}

    @app.get("/api/tasks")
    async def get_tasks(
        state: str = Query(None, description="GTD state filter"),
        type: str = Query(None, alias="item_type", description="item type: task/project"),
        query: str = Query(None, description="keyword search"),
        tags: str = Query(None, description="comma-separated tags"),
        starred: bool = Query(None),
        overdue: bool = Query(None),
        due_before: str = Query(None),
        due_after: str = Query(None),
        include_notes: bool = Query(False),
        limit: int = Query(50, ge=1, le=200),
        offset: int = Query(0, ge=0),
    ):
        """Get tasks/projects from Nirvana with filters."""
        params = {"limit": limit, "offset": offset, "include_notes": include_notes}
        if state:
            params["state"] = state
        if type:
            params["type"] = type
        if query:
            params["query"] = query
        if tags:
            params["tags"] = tags
        if starred is not None:
            params["starred"] = starred
        if overdue is not None:
            params["overdue"] = overdue
        if due_before:
            params["due_before"] = due_before
        if due_after:
            params["due_after"] = due_after

        data = await _mcp_call("get_tasks", params)
        payload = _parse_text(data)
        return payload

    @app.put("/api/tasks")
    async def update_tasks(updates: list[TaskUpdate]):
        """Update one or more tasks/projects. Each needs 'id' + fields to change."""
        updates_dict = [u.model_dump(exclude_none=True) for u in updates]
        data = await _mcp_call("update_tasks", {"updates": updates_dict})
        return _parse_text(data)

    @app.delete("/api/tasks/{task_id}")
    async def delete_task(task_id: str = Path(..., description="Nirvana task ID")):
        """Move a task/project to trash."""
        data = await _mcp_call("update_tasks", {"updates": [{"id": task_id, "state": "trash"}]})
        return _parse_text(data)

    @app.post("/api/tasks/{task_id}/complete")
    async def complete_task(task_id: str):
        """Mark task as done."""
        data = await _mcp_call("update_tasks", {"updates": [{"id": task_id, "completed": True}]})
        return _parse_text(data)

    @app.put("/api/tasks/{task_id}/energy")
    async def set_energy(task_id: str, energy: int = Query(1, ge=0, le=3)):
        """Set energy level: 0=routine, 1=low, 2=medium, 3=high."""
        data = await _mcp_call("update_tasks", {"updates": [{"id": task_id, "energy": energy}]})
        return _parse_text(data)

    @app.put("/api/tasks/{task_id}/schedule")
    async def set_schedule(
        task_id: str,
        duedate: str = Query("", description="Due date YYYY-MM-DD"),
        startdate: str = Query("", description="Scheduled start YYYY-MM-DD"),
    ):
        """Set due date and/or scheduled start date."""
        update = {"id": task_id}
        if duedate:
            update["duedate"] = duedate
        if startdate:
            update["startdate"] = startdate
        data = await _mcp_call("update_tasks", {"updates": [update]})
        return _parse_text(data)

    @app.put("/api/tasks/{task_id}/move")
    async def move_task(task_id: str, parentid: str = Query(..., description="Parent project ID")):
        """Move task under a parent project."""
        data = await _mcp_call("update_tasks", {"updates": [{"id": task_id, "parentid": parentid}]})
        return _parse_text(data)

    @app.put("/api/tasks/{task_id}/star")
    async def star_task(task_id: str, starred: bool = Query(True)):
        """Add to or remove from Focus list."""
        data = await _mcp_call("update_tasks", {"updates": [{"id": task_id, "starred": starred}]})
        return _parse_text(data)

    # ═══════════════════════════════════════════════════════════════
    # PROJECTS
    # ═══════════════════════════════════════════════════════════════

    @app.post("/api/projects")
    async def create_project(body: ProjectIn):
        """Create a project (queued for reliable async processing)."""
        if queue_manager is None:
            raise HTTPException(503, "Queue manager not available")
        task = await queue_manager.enqueue_project(
            name=body.name,
            description=body.description,
            tags=body.tags,
        )
        return {"status": "queued", "id": task["id"], "message": f"Project {task['id'][:8]} queued"}

    # ═══════════════════════════════════════════════════════════════
    # TAGS
    # ═══════════════════════════════════════════════════════════════

    @app.get("/api/tags")
    async def get_tags():
        """List all tags with usage counts."""
        data = await _mcp_call("get_tags", {})
        return _parse_text(data)

    # ═══════════════════════════════════════════════════════════════
    # TASK COUNTS
    # ═══════════════════════════════════════════════════════════════

    @app.get("/api/task-counts")
    async def get_task_counts():
        """Get task counts per GTD state."""
        data = await _mcp_call("get_task_counts", {})
        return _parse_text(data)

    # ═══════════════════════════════════════════════════════════════
    # GENERIC MCP PROXY
    # ═══════════════════════════════════════════════════════════════

    @app.post("/api/mcp/{tool_name}")
    async def call_mcp_tool(tool_name: str, body: McpCall = McpCall()):
        """Call any MCP tool directly. Body.params = tool arguments."""
        data = await _mcp_call(tool_name, body.params)
        return _parse_text(data)

    # ═══════════════════════════════════════════════════════════════
    # HEALTH & STATS
    # ═══════════════════════════════════════════════════════════════

    @app.get("/health")
    async def health():
        mcp_ok = mcp_client.is_connected if mcp_client else False
        qsize = queue_manager.queue_size() if queue_manager else 0
        last = ""
        if queue_manager:
            last = queue_manager._db.last_success() or ""
        return {
            "status": "online",
            "mcp_connection": "ok" if mcp_ok else "disconnected",
            "queue_size": qsize,
            "last_success": last,
        }

    @app.get("/stats")
    async def stats():
        qs = queue_manager.stats() if queue_manager else {}
        uptime = (datetime.now(timezone.utc) - start_time).total_seconds() / 3600
        return {
            "total_tasks": qs.get("total_tasks", 0),
            "by_status": qs.get("by_status", {}),
            "queue_size": qs.get("queue_size", 0),
            "sent_count": qs.get("sent_count", 0),
            "error_count": qs.get("error_count", 0),
            "total_retries": qs.get("total_retries", 0),
            "avg_confirm_time_sec": qs.get("avg_confirm_time_sec"),
            "mcp_connected": mcp_client.is_connected if mcp_client else False,
            "mcp_circuit": mcp_client.circuit.state_name if mcp_client else "",
            "uptime_hours": round(uptime, 2),
        }

    # ── Global error handler ─────────────────────────────────────────

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        log.error(f"Unhandled error on {request.method} {request.url.path}: {exc}")
        return JSONResponse(
            status_code=500,
            content={"status": "error", "reason": "Internal server error"},
        )

    return app
