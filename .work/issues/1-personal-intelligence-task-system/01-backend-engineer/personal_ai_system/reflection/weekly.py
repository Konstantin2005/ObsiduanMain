import logging
from datetime import datetime, timedelta
from memory.storage import Storage
from memory.models import Memory

logger = logging.getLogger("pits.reflection.weekly")


class WeeklyReflection:
    def __init__(self, storage: Storage):
        self.storage = storage

    def generate(self) -> dict:
        week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        all_entries = self.storage.get_all_entries()
        week_entries = [e for e in all_entries if e.created_at and e.created_at >= week_ago]
        all_tasks = self.storage.get_all_tasks()
        week_tasks = [t for t in all_tasks if t.created_at and t.created_at >= week_ago]

        by_type = {}
        for m in self.storage.get_all_memories():
            by_type[m.memory_type] = by_type.get(m.memory_type, 0) + 1

        report = {
            "period": f"{week_ago[:10]} - {datetime.now().isoformat()[:10]}",
            "new_entries": len(week_entries),
            "new_tasks": len(week_tasks),
            "memory_by_type": by_type,
            "total_memories": sum(by_type.values()),
            "total_entries": len(all_entries),
            "total_tasks": len(all_tasks),
        }
        return report
