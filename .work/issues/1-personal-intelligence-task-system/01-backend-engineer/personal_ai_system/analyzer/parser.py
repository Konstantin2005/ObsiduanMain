import json
import re
import logging
from typing import List
from memory.models import Suggestion

logger = logging.getLogger("pits.analyzer.parser")


class ResponseParser:
    def parse(self, raw_response: str) -> List[Suggestion]:
        if not raw_response:
            return []
        json_str = self._extract_json(raw_response)
        if not json_str:
            logger.warning("No JSON found in response")
            return []
        try:
            data = json.loads(json_str)
        except json.JSONDecodeError as e:
            logger.warning("JSON parse error: %s", e)
            cleaned = self._repair_json(json_str)
            if cleaned:
                try:
                    data = json.loads(cleaned)
                except json.JSONDecodeError:
                    return []
            else:
                return []

        items = data.get("items", [])
        if not isinstance(items, list):
            return []

        suggestions = []
        for item in items:
            try:
                suggestion = Suggestion(
                    type=item.get("type", "task"),
                    title=item.get("title", ""),
                    confidence=float(item.get("confidence", 0)),
                    reason=item.get("reason", ""),
                    recommended_action=item.get("recommended_action", ""),
                )
                suggestions.append(suggestion)
            except (ValueError, TypeError) as e:
                logger.warning("Invalid suggestion item: %s", e)
                continue
        return suggestions

    def _extract_json(self, text: str) -> str:
        json_match = re.search(r"\{[\s\S]*\}", text)
        if json_match:
            return json_match.group(0)
        return ""

    def _repair_json(self, text: str) -> str:
        text = re.sub(r",\s*}", "}", text)
        text = re.sub(r",\s*]", "]", text)
        return text
