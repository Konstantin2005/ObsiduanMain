import logging
from typing import List
from memory.storage import Storage
from memory.models import Task

logger = logging.getLogger("pits.decision.dedup")


class DedupChecker:
    def __init__(self, storage: Storage):
        self.storage = storage

    def is_duplicate(self, title: str) -> bool:
        existing = self.storage.get_all_tasks()
        title_lower = title.lower().strip()
        for task in existing:
            if self._similar(title_lower, task.title.lower().strip()):
                return True
        return False

    def _similar(self, a: str, b: str) -> bool:
        if a == b:
            return True
        if len(a) < 5 or len(b) < 5:
            return a == b
        words_a = set(a.split())
        words_b = set(b.split())
        if len(words_a) < 3 or len(words_b) < 3:
            intersection = words_a & words_b
            return len(intersection) > 0
        intersection = words_a & words_b
        union = words_a | words_b
        jaccard = len(intersection) / len(union)
        return jaccard > 0.6
