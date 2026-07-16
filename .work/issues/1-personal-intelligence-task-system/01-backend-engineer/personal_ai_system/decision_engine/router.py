import logging
from typing import List, Tuple
from memory.models import Suggestion, Task
from memory.storage import Storage
from .dedup import DedupChecker
from .feedback import FeedbackLearner

logger = logging.getLogger("pits.decision")


class DecisionRouter:
    def __init__(self, storage: Storage, auto_threshold: float = 85.0, suggest_threshold: float = 50.0):
        self.storage = storage
        self.auto_threshold = auto_threshold
        self.suggest_threshold = suggest_threshold
        self.dedup = DedupChecker(storage)
        self.learner = FeedbackLearner(storage)

    def route(self, suggestions: List[Suggestion], entry_id: int) -> List[Task]:
        created_tasks = []
        for suggestion in suggestions:
            task = self._process_suggestion(suggestion, entry_id)
            if task:
                created_tasks.append(task)
        return created_tasks

    def _process_suggestion(self, suggestion: Suggestion, entry_id: int) -> Task:
        confidence = suggestion.confidence
        adjusted = self.learner.adjust_confidence(suggestion)
        logger.info("Suggestion '%s': raw=%.1f, adjusted=%.1f", suggestion.title, confidence, adjusted)

        if adjusted < self.suggest_threshold:
            status = "memory"
            logger.debug("Below suggest threshold -> memory only")
        elif adjusted >= self.auto_threshold:
            if self.dedup.is_duplicate(suggestion.title):
                logger.info("Duplicate detected, skipping auto-create: %s", suggestion.title)
                status = "memory"
            else:
                status = "automatic"
                logger.info("Auto-creating task: %s (confidence=%.1f)", suggestion.title, adjusted)
        else:
            status = "suggested"
            logger.info("Suggesting task: %s (confidence=%.1f)", suggestion.title, adjusted)

        task = Task(
            title=suggestion.title,
            description=f"{suggestion.reason}\n{suggestion.recommended_action}",
            confidence=adjusted,
            status=status,
            source_entry_id=entry_id,
        )
        task_id = self.storage.save_task(task)
        task.id = task_id
        return task

    def set_thresholds(self, auto: float, suggest: float):
        self.auto_threshold = auto
        self.suggest_threshold = suggest
