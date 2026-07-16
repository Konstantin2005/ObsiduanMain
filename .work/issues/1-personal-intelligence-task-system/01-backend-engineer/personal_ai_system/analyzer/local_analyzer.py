import re
import logging
from typing import List, Set
from memory.models import Suggestion

logger = logging.getLogger("pits.analyzer.local")


class LocalAnalyzer:
    def __init__(self):
        self.patterns = {
            "task": {
                "ru_strong": [
                    r"(нужно|надо|должен|необходимо)\s+([^.]{5,80})",
                    r"надо\s+бы(ло)?\s+([^.]{5,60})",
                    r"надо\s+будет\s+([^.]{5,60})",
                    r"нужно\s+будет\s+([^.]{5,60})",
                    r"заняться\s+([^.]{5,60})",
                    r"разобраться\s+([^.]{5,60})",
                ],
                "ru_medium": [
                    r"не успеваю\s+([^.]{5,50})",
                    r"сделать\s+([^.]{5,50})",
                    r"(билеты|списки|план)\s+([^.]{5,50})",
                    r"составить\s+([^.]{5,50})",
                    r"решить\s+([^.]{5,50})",
                ],
                "en_strong": [
                    r"(need to|have to|must)\s+([^.]{5,70})",
                    r"next step\s+(is\s+to\s+|is\s+|:)?\s*([^.]{5,60})",
                    r"important task",
                ],
                "en_medium": [
                    r"I need\s+([^.]{5,70})",
                    r"I need to\s+(understand|find|learn|translate|write|build|take|focus)\s+([^.]{5,60})",
                    r"focus on\s+([^.]{5,60})",
                    r"take\s+(a few|some)\s+([^.]{5,50})",
                ],
            },
            "idea": {
                "ru_medium": [
                    r"(идея|мысль)\s+([^.]{5,60})",
                    r"(можно|хороший\s+вариант)\s+([^.]{5,60})",
                    r"придумал\s+([^.]{5,60})",
                ],
                "en_medium": [
                    r"I (?:am\s+)?thinking\s+about\s+([^.]{5,60})",
                    r"(idea|thought)\s+([^.]{5,60})",
                ],
            },
            "goal": {
                "ru_medium": [
                    r"(хочу|цель)\s+([^.]{5,60})",
                    r"(научиться|освоить|выучить)\s+([^.]{5,50})",
                    r"(планирую|собираюсь)\s+([^.]{5,50})",
                ],
                "en_medium": [
                    r"I (?:want|plan|intend)\s+to\s+([^.]{5,60})",
                    r"I will\s+([^.]{5,60})",
                    r"build(?:ing)? a new\s+([^.]{5,50})",
                ],
            },
            "problem": {
                "ru_medium": [
                    r"(проблема|сложность)\s+([^.]{5,60})",
                    r"не успеваю\s+([^.]{5,50})",
                    r"(сложно|тяжело)\s+([^.]{5,60})",
                    r"не\s+(получается|выходит)\s+([^.]{5,50})",
                    r"откладываю\s+([^.]{5,50})",
                ],
                "en_medium": [
                    r"(problem|issue)\s+(is\s+|with\s+)?([^.]{5,60})",
                    r"I can'?t\s+([^.]{5,50})",
                    r"lack of\s+([^.]{5,50})",
                ],
            },
            "promise": {
                "ru_medium": [
                    r"(обещал|пообещал)\s+([^.]{5,60})",
                    r"должен\s+был\s+([^.]{5,50})",
                ],
                "en_medium": [
                    r"(promised|commit(?:ment)?)\s+([^.]{5,60})",
                ],
            },
        }

        self.noise_words = [
            "maybe", "perhaps", "someday", "eventually", "could", "might",
            "может", "возможно", "когда-нибудь", "наверное",
        ]

    def analyze(self, text: str) -> List[Suggestion]:
        suggestions = []
        seen_blocks: List[str] = []

        for category, lang_patterns in self.patterns.items():
            for lang, p_list in lang_patterns.items():
                for pattern in p_list:
                    matches = re.finditer(pattern, text, re.IGNORECASE)
                    for match in matches:
                        suggestion = self._build_suggestion(match, category, lang, pattern)
                        if suggestion is None:
                            continue
                        block_key = self._content_hash(suggestion.title)
                        if block_key in seen_blocks:
                            continue
                        seen_blocks.append(block_key)
                        suggestions.append(suggestion)

        suggestions.sort(key=lambda s: s.confidence, reverse=True)
        suggestions = self._smart_dedup(suggestions)
        return suggestions

    def _build_suggestion(self, match, category: str, lang: str, pattern: str):
        groups = match.groups()
        title = self._extract_phrase(groups, match.group(0))
        if not title or len(title) < 5:
            return None
        if len(title) > 80:
            title = title[:80]
        title = self._clean_title(title)

        confidence = self._calc_confidence(category, lang)
        noise_penalty = self._check_noise(title)
        confidence = max(10, min(95, confidence - noise_penalty))

        return Suggestion(
            type=category,
            title=title,
            confidence=confidence,
            reason=self._make_reason(category, match.group(0)),
            recommended_action=self._make_action(category, title),
        )

    def _extract_phrase(self, groups, full_match: str) -> str:
        if not groups:
            return full_match.strip()
        if len(groups) >= 2 and groups[-1]:
            return groups[-1].strip()
        if groups[0]:
            return groups[0].strip()
        return full_match.strip()

    def _clean_title(self, title: str) -> str:
        title = re.sub(r"^[,\s]+", "", title)
        title = re.sub(r"[,\s]+$", "", title)
        title = re.sub(r"\s+", " ", title)
        title = title.strip('.,!?:;#- \t\n\r')
        if title and title[0].islower():
            title = title[0].upper() + title[1:]
        return title.strip()[:80]

    def _calc_confidence(self, category: str, lang: str) -> int:
        base_map = {
            "ru_strong": 80, "en_strong": 80,
            "ru_medium": 60, "en_medium": 60,
        }
        base = base_map.get(lang, 50)
        if category == "task":
            base += 5
        return min(95, base)

    def _check_noise(self, title: str) -> int:
        title_lower = title.lower()
        noise_count = sum(1 for w in self.noise_words if w in title_lower)
        return noise_count * 8

    def _make_reason(self, category: str, match_text: str) -> str:
        prefix = match_text[:60].strip()
        reasons = {
            "task": f"Task signal in text: \"{prefix}\"",
            "idea": f"Idea mentioned: \"{prefix}\"",
            "goal": f"Goal identified: \"{prefix}\"",
            "problem": f"Problem detected: \"{prefix}\"",
            "promise": f"Promise/commitment: \"{prefix}\"",
        }
        return reasons.get(category, f"Pattern match: \"{prefix}\"")

    def _make_action(self, category: str, title: str) -> str:
        actions = {
            "task": "Create task and schedule in project",
            "idea": "Save for future reference",
            "goal": "Break into actionable milestones",
            "problem": "Analyze root cause, create resolution plan",
            "promise": "Follow up and set reminder",
        }
        return actions.get(category, "Review and file")

    def _content_hash(self, title: str) -> str:
        return re.sub(r"\s+", " ", title.lower().strip())

    def _smart_dedup(self, suggestions: List[Suggestion]) -> List[Suggestion]:
        if not suggestions:
            return []
        result = [suggestions[0]]
        for s in suggestions[1:]:
            is_dup = False
            for existing in result:
                if self._titles_overlap(s.title, existing.title):
                    is_dup = True
                    break
            if not is_dup:
                result.append(s)
        return result

    def _titles_overlap(self, a: str, b: str) -> bool:
        a = re.sub(r"\s+", " ", a.lower().strip())
        b = re.sub(r"\s+", " ", b.lower().strip())
        if a == b:
            return True
        if len(a) < 5 or len(b) < 5:
            return a == b
        if a in b or b in a:
            return True
        words_a = set(a.split())
        words_b = set(b.split())
        if not words_a or not words_b:
            return False
        intersection = words_a & words_b
        union = words_a | words_b
        if len(intersection) / len(union) > 0.5:
            return True
        if len(intersection) >= 2 and (len(words_a) <= 3 or len(words_b) <= 3):
            return True
        return False
