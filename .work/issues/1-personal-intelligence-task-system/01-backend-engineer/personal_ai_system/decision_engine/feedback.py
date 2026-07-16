import logging
from typing import Dict
from memory.storage import Storage
from memory.models import Suggestion, Feedback

logger = logging.getLogger("pits.decision.feedback")


class FeedbackLearner:
    def __init__(self, storage: Storage):
        self.storage = storage
        self.type_adjustments: Dict[str, float] = {}

    def adjust_confidence(self, suggestion: Suggestion) -> float:
        feedbacks = self.storage.get_all_feedback()
        if not feedbacks:
            return suggestion.confidence

        same_type_feedbacks = []
        for fb in feedbacks:
            task = self.storage.get_all_tasks()
            for t in task:
                if t.id == fb.task_id:
                    same_type_feedbacks.append(fb)
                    break

        if not same_type_feedbacks:
            return suggestion.confidence

        accept_rate = sum(1 for fb in same_type_feedbacks if fb.decision == "accepted") / len(same_type_feedbacks)
        if accept_rate > 0.7:
            return min(100, suggestion.confidence + 10)
        elif accept_rate < 0.3:
            return max(0, suggestion.confidence - 15)
        return suggestion.confidence

    def record_feedback(self, task_id: int, decision: str, reason: str = None):
        feedback = Feedback(task_id=task_id, decision=decision, reason=reason)
        self.storage.save_feedback(feedback)
        logger.info("Feedback recorded: task=%s, decision=%s", task_id, decision)
