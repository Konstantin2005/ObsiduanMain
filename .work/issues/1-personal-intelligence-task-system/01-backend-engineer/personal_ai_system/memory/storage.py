from typing import List, Optional
from .database import Database
from .models import Entry, Memory, Task, Feedback


class Storage:
    def __init__(self, db: Database):
        self.db = db

    def save_entry(self, entry: Entry) -> int:
        cur = self.db.execute(
            "INSERT INTO entries (source, raw_text, cleaned_text, source_file) VALUES (?, ?, ?, ?)",
            (entry.source, entry.raw_text, entry.cleaned_text, entry.source_file)
        )
        return cur.lastrowid

    def get_entry(self, entry_id: int) -> Optional[Entry]:
        row = self.db.fetch_one("SELECT * FROM entries WHERE id = ?", (entry_id,))
        if not row:
            return None
        return Entry(**dict(row))

    def get_all_entries(self, limit: int = 100, offset: int = 0) -> List[Entry]:
        rows = self.db.fetch_all(
            "SELECT * FROM entries ORDER BY created_at DESC LIMIT ? OFFSET ?",
            (limit, offset)
        )
        return [Entry(**dict(r)) for r in rows]

    def save_memory(self, memory: Memory) -> int:
        cur = self.db.execute(
            "INSERT INTO memories (entry_id, content, embedding, memory_type, confidence) VALUES (?, ?, ?, ?, ?)",
            (memory.entry_id, memory.content, memory.embedding, memory.memory_type, memory.confidence)
        )
        return cur.lastrowid

    def get_memory(self, memory_id: int) -> Optional[Memory]:
        row = self.db.fetch_one("SELECT * FROM memories WHERE id = ?", (memory_id,))
        if not row:
            return None
        return Memory(**dict(row))

    def get_memories_by_type(self, memory_type: str, limit: int = 100) -> List[Memory]:
        rows = self.db.fetch_all(
            "SELECT * FROM memories WHERE memory_type = ? ORDER BY created_at DESC LIMIT ?",
            (memory_type, limit)
        )
        return [Memory(**dict(r)) for r in rows]

    def get_all_memories(self) -> List[Memory]:
        rows = self.db.fetch_all("SELECT * FROM memories ORDER BY created_at DESC")
        return [Memory(**dict(r)) for r in rows]

    def save_task(self, task: Task) -> int:
        cur = self.db.execute(
            "INSERT INTO tasks (memory_id, title, description, confidence, status, source_entry_id) VALUES (?, ?, ?, ?, ?, ?)",
            (task.memory_id, task.title, task.description, task.confidence, task.status, task.source_entry_id)
        )
        return cur.lastrowid

    def update_task_status(self, task_id: int, status: str):
        self.db.execute(
            "UPDATE tasks SET status = ? WHERE id = ?",
            (status, task_id)
        )

    def get_tasks_by_status(self, status: str) -> List[Task]:
        rows = self.db.fetch_all(
            "SELECT * FROM tasks WHERE status = ? ORDER BY confidence DESC",
            (status,)
        )
        return [Task(**dict(r)) for r in rows]

    def get_all_tasks(self) -> List[Task]:
        rows = self.db.fetch_all("SELECT * FROM tasks ORDER BY created_at DESC")
        return [Task(**dict(r)) for r in rows]

    def save_feedback(self, feedback: Feedback) -> int:
        cur = self.db.execute(
            "INSERT INTO feedback (task_id, decision, reason) VALUES (?, ?, ?)",
            (feedback.task_id, feedback.decision, feedback.reason)
        )
        return cur.lastrowid

    def get_feedback_for_task(self, task_id: int) -> List[Feedback]:
        rows = self.db.fetch_all(
            "SELECT * FROM feedback WHERE task_id = ? ORDER BY created_at DESC",
            (task_id,)
        )
        return [Feedback(**dict(r)) for r in rows]

    def get_all_feedback(self) -> List[Feedback]:
        rows = self.db.fetch_all("SELECT * FROM feedback ORDER BY created_at DESC")
        return [Feedback(**dict(r)) for r in rows]

    def save_relationship(self, source_id: int, target_id: int, rel_type: str, strength: float = 0.5):
        self.db.execute(
            "INSERT INTO relationships (source_memory_id, target_memory_id, relation_type, strength) VALUES (?, ?, ?, ?)",
            (source_id, target_id, rel_type, strength)
        )
