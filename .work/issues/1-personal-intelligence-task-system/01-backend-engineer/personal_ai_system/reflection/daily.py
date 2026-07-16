import logging
from datetime import datetime
from memory.storage import Storage

logger = logging.getLogger("pits.reflection.daily")


class DailyReflection:
    def __init__(self, storage: Storage):
        self.storage = storage

    def generate(self) -> dict:
        entries_today = self._get_today_entries()
        tasks_today = self._get_today_tasks()
        open_tasks = self.storage.get_tasks_by_status("automatic")
        suggestions = self.storage.get_tasks_by_status("suggested")

        report = {
            "date": datetime.now().isoformat()[:10],
            "new_entries": len(entries_today),
            "new_tasks": len(tasks_today),
            "open_automatic_tasks": len(open_tasks),
            "pending_suggestions": len(suggestions),
            "open_tasks": [{"id": t.id, "title": t.title, "confidence": t.confidence} for t in open_tasks[:5]],
            "suggestions": [{"id": t.id, "title": t.title, "confidence": t.confidence} for t in suggestions[:5]],
        }
        return report

    def _get_today_entries(self):
        today = datetime.now().isoformat()[:10]
        all_entries = self.storage.get_all_entries()
        return [e for e in all_entries if e.created_at and e.created_at.startswith(today)]

    def _get_today_tasks(self):
        today = datetime.now().isoformat()[:10]
        all_tasks = self.storage.get_all_tasks()
        return [t for t in all_tasks if t.created_at and t.created_at.startswith(today)]
