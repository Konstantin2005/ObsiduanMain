import logging
from typing import Dict, List
from memory.storage import Storage
from memory.models import Feedback

logger = logging.getLogger("pits.user_model.learner")


class Learner:
    def __init__(self, storage: Storage):
        self.storage = storage
        self.auto_threshold_adjustment = 0.0

    def learn_from_feedback(self):
        feedbacks = self.storage.get_all_feedback()
        if len(feedbacks) < 5:
            return

        accepted = sum(1 for f in feedbacks if f.decision == "accepted")
        rejected = sum(1 for f in feedbacks if f.decision == "rejected")
        rate = accepted / (accepted + rejected) if (accepted + rejected) > 0 else 0.5

        if rate >= 0.8:
            self.auto_threshold_adjustment = -5.0
            logger.info("High acceptance rate (%.2f), lowering auto threshold by 5", rate)
        elif rate <= 0.2:
            self.auto_threshold_adjustment = 10.0
            logger.info("Low acceptance rate (%.2f), raising auto threshold by 10", rate)
        else:
            self.auto_threshold_adjustment = 0.0
