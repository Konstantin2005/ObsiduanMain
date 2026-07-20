"""
Local Nirvana Bridge stub — accepts tasks from PITS without real Nirvana MCP.
"""
import sys, os, json, asyncio, logging
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import uvicorn
from database import Database

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("nirvana.local")

db = Database()
app = FastAPI(title="Nirvana Bridge (Local)")


class TaskIn(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    description: str = ""
    source: str = "manual"


@app.get("/health")
async def health():
    return {"status": "ok", "service": "nirvana-bridge-local", "mode": "local"}


@app.post("/api/tasks")
async def create_task(task: TaskIn):
    db.execute(
        "INSERT INTO tasks (title, description, source, status, created_at) VALUES (?, ?, ?, ?, ?)",
        (task.title, task.description, task.source, "pending", datetime.now().isoformat()),
    )
    task_id = db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
    log.info("Task created: id=%s title=%s", task_id, task.title[:60])
    return {"id": task_id, "status": "queued"}


@app.get("/api/tasks")
async def list_tasks(limit: int = 50):
    rows = db.fetch_all("SELECT * FROM tasks ORDER BY created_at DESC LIMIT ?", (limit,))
    return {"tasks": [dict(r) for r in rows]}


if __name__ == "__main__":
    port = int(os.environ.get("NIRVANA_HTTP_PORT", "8712"))
    log.info("Starting local Nirvana Bridge on port %s", port)
    uvicorn.run(app, host="127.0.0.1", port=port)
