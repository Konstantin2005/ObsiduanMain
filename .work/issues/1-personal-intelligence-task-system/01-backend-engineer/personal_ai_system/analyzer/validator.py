from typing import List
from memory.models import Suggestion


class Validator:
    VALID_TYPES = {"task", "idea", "goal", "problem", "promise"}

    def validate(self, suggestions: List[Suggestion]) -> List[Suggestion]:
        valid = []
        for s in suggestions:
            if not self._is_valid(s):
                continue
            valid.append(s)
        return valid

    def _is_valid(self, s: Suggestion) -> bool:
        if s.type not in self.VALID_TYPES:
            return False
        if not s.title or len(s.title) < 3:
            return False
        if s.confidence < 0 or s.confidence > 100:
            return False
        if not s.reason or len(s.reason) < 5:
            return False
        return True

    def is_actionable(self, s: Suggestion) -> bool:
        if s.type != "task":
            return False
        if s.confidence < 30:
            return False
        noise_words = ["maybe", "perhaps", "someday", "eventually", "could", "might"]
        title_lower = s.title.lower()
        noise_count = sum(1 for w in noise_words if w in title_lower)
        if noise_count >= 2:
            return False
        return True
