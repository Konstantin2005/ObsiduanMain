import logging
from typing import Dict, List
from memory.storage import Storage

logger = logging.getLogger("pits.user_model")


class UserProfile:
    def __init__(self, storage: Storage):
        self.storage = storage

    def get_statistics(self) -> Dict:
        tasks = self.storage.get_all_tasks()
        feedbacks = self.storage.get_all_feedback()
        entries = self.storage.get_all_entries()

        total_tasks = len(tasks)
        by_status = {}
        for t in tasks:
            by_status[t.status] = by_status.get(t.status, 0) + 1

        total_feedback = len(feedbacks)
        accepted = sum(1 for f in feedbacks if f.decision == "accepted")
        rejected = sum(1 for f in feedbacks if f.decision == "rejected")

        return {
            "total_entries": len(entries),
            "total_tasks": total_tasks,
            "tasks_by_status": by_status,
            "total_feedback": total_feedback,
            "accepted": accepted,
            "rejected": rejected,
            "acceptance_rate": (accepted / total_feedback * 100) if total_feedback > 0 else 0,
        }

    def get_task_type_preferences(self) -> Dict[str, int]:
        tasks = self.storage.get_all_tasks()
        feedbacks = self.storage.get_all_feedback()
        type_counts = {"task": 0, "idea": 0, "goal": 0, "problem": 0, "promise": 0}
        for fb in feedbacks:
            for t in tasks:
                if t.id == fb.task_id and fb.decision == "accepted":
                    type_counts[t.status] = type_counts.get(t.status, 0) + 1
        return type_counts
