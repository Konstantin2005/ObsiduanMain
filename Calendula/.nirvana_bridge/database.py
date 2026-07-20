"""
Nirvana Bridge — SQLite-backed task queue storage.

Thread-safe: uses a single connection with WAL mode and retry on locked.
"""

import json
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Generator

from config import config

# ISO-8601 timestamp helper
def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class Database:
    """SQLite store for bridge tasks. Thread-safe via RLock."""

    def __init__(self, db_path: str | None = None):
        self._path = db_path or config.DB_PATH
        self._lock = threading.RLock()

        # Ensure directory exists
        Path(self._path).parent.mkdir(parents=True, exist_ok=True)

        self._conn: sqlite3.Connection | None = None
        self._connect()
        self._migrate()

    # ── Connection ────────────────────────────────────────────────────

    def _connect(self) -> None:
        conn = sqlite3.connect(self._path, check_same_thread=False)
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA busy_timeout=5000")
        conn.execute("PRAGMA foreign_keys=ON")
        conn.row_factory = sqlite3.Row
        self._conn = conn

    def _migrate(self) -> None:
        with self._conn:
            self._conn.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id              TEXT PRIMARY KEY,
                    title           TEXT NOT NULL,
                    description     TEXT DEFAULT '',
                    priority        TEXT DEFAULT 'medium',
                    due_date        TEXT DEFAULT '',
                    tags            TEXT DEFAULT '[]',
                    status          TEXT NOT NULL DEFAULT 'PENDING'
                                    CHECK(status IN (
                                        'PENDING','SENDING','SENT',
                                        'CONFIRMED','FAILED','RETRY'
                                    )),
                    nirvana_task_id TEXT DEFAULT NULL,
                    error           TEXT DEFAULT NULL,
                    retry_count     INTEGER NOT NULL DEFAULT 0,
                    max_retries     INTEGER NOT NULL DEFAULT 5,
                    created_at      TEXT NOT NULL,
                    updated_at      TEXT NOT NULL,
                    sent_at         TEXT DEFAULT NULL,
                    confirmed_at    TEXT DEFAULT NULL,
                    item_type       TEXT NOT NULL DEFAULT 'task'
                )
            """)
            # Migration: add item_type if missing (older DBs)
            try:
                self._conn.execute("ALTER TABLE tasks ADD COLUMN item_type TEXT NOT NULL DEFAULT 'task'")
            except Exception:
                pass  # Column already exists
            self._conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_tasks_status
                ON tasks(status)
            """)
            self._conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_tasks_created
                ON tasks(created_at)
            """)

    def close(self) -> None:
        with self._lock:
            if self._conn:
                self._conn.close()
                self._conn = None

    @contextmanager
    def _tx(self) -> Generator[sqlite3.Cursor, None, None]:
        with self._lock:
            cursor = self._conn.cursor()
            try:
                yield cursor
                self._conn.commit()
            except Exception:
                self._conn.rollback()
                raise
            finally:
                cursor.close()

    # ── CRUD ──────────────────────────────────────────────────────────

    def create_task(
        self,
        title: str,
        description: str = "",
        priority: str = "medium",
        due_date: str = "",
        tags: list[str] | None = None,
        max_retries: int | None = None,
        item_type: str = "task",
    ) -> dict:
        """Insert a new PENDING task. Returns the task dict."""
        task_id = str(uuid.uuid4())
        now = _now()
        tags_json = json.dumps(tags or [], ensure_ascii=False)
        max_r = max_retries if max_retries is not None else config.MAX_RETRIES

        with self._tx() as cur:
            cur.execute(
                """
                INSERT INTO tasks
                    (id, title, description, priority, due_date, tags,
                     status, retry_count, max_retries,
                     created_at, updated_at, item_type)
                VALUES (?,?,?,?,?,?, 'PENDING',0,?,?,?,?)
                """,
                (task_id, title, description, priority, due_date,
                 tags_json, max_r, now, now, item_type),
            )
        return self.get_task(task_id)

    def get_task(self, task_id: str) -> dict | None:
        """Fetch a single task by id."""
        with self._lock:
            row = self._conn.execute(
                "SELECT * FROM tasks WHERE id = ?", (task_id,)
            ).fetchone()
        return dict(row) if row else None

    def get_tasks_by_status(self, *statuses: str) -> list[dict]:
        """Fetch all tasks matching any of the given statuses."""
        placeholders = ",".join("?" for _ in statuses)
        with self._lock:
            rows = self._conn.execute(
                f"SELECT * FROM tasks WHERE status IN ({placeholders})"
                " ORDER BY created_at ASC",
                statuses,
            ).fetchall()
        return [dict(r) for r in rows]

    def count_by_status(self) -> dict[str, int]:
        """Return counts per status."""
        with self._lock:
            rows = self._conn.execute(
                "SELECT status, COUNT(*) as cnt FROM tasks GROUP BY status"
            ).fetchall()
        return {r["status"]: r["cnt"] for r in rows}

    def update_status(
        self,
        task_id: str,
        status: str,
        nirvana_task_id: str | None = None,
        error: str | None = None,
        inc_retry: bool = False,
    ) -> None:
        """Update task status and optional fields."""
        now = _now()
        sets = ["status = ?", "updated_at = ?"]
        params: list = [status, now]

        if nirvana_task_id is not None:
            sets.append("nirvana_task_id = ?")
            params.append(nirvana_task_id)
        if error is not None:
            sets.append("error = ?")
            params.append(error)
        if inc_retry:
            sets.append("retry_count = retry_count + 1")
        if status == "SENT":
            sets.append("sent_at = ?")
            params.append(now)
        if status == "CONFIRMED":
            sets.append("confirmed_at = ?")
            params.append(now)
        if status in ("FAILED", "RETRY"):
            sets.append("retry_count = retry_count + 1")

        params.append(task_id)
        with self._tx() as cur:
            cur.execute(
                f"UPDATE tasks SET {', '.join(sets)} WHERE id = ?", params
            )

    def mark_for_retry(self, task_id: str, error: str) -> None:
        """Move task to RETRY or FAILED depending on retry count."""
        task = self.get_task(task_id)
        if not task:
            return
        if task["retry_count"] >= task["max_retries"]:
            self.update_status(task_id, "FAILED", error=error)
        else:
            self.update_status(task_id, "RETRY", error=error, inc_retry=True)

    # ── Stats ─────────────────────────────────────────────────────────

    def stats(self) -> dict:
        """Aggregate statistics."""
        cnt = self.count_by_status()
        with self._lock:
            row = self._conn.execute(
                "SELECT COUNT(*) as total,"
                " AVG(CASE WHEN confirmed_at IS NOT NULL AND sent_at IS NOT NULL"
                "     THEN (julianday(confirmed_at) - julianday(sent_at)) * 86400"
                "     ELSE NULL END) as avg_confirm_sec,"
                " SUM(retry_count) as total_retries"
                " FROM tasks"
            ).fetchone()

        return {
            "total_tasks": row["total"],
            "by_status": cnt,
            "total_retries": row["total_retries"] or 0,
            "avg_confirm_time_sec": (
                round(row["avg_confirm_sec"], 2)
                if row["avg_confirm_sec"]
                else None
            ),
        }

    def last_success(self) -> str | None:
        """Return timestamp of most recent CONFIRMED task."""
        with self._lock:
            row = self._conn.execute(
                "SELECT confirmed_at FROM tasks"
                " WHERE status = 'CONFIRMED'"
                " ORDER BY confirmed_at DESC LIMIT 1"
            ).fetchone()
        return row["confirmed_at"] if row else None
