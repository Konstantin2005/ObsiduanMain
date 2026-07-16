import re
from typing import List


class Cleaner:
    def __init__(self):
        self.strip_patterns = [
            (re.compile(r"http\S+"), "[URL]"),
            (re.compile(r"!\[.*?\]\(.*?\)"), "[IMAGE]"),
            (re.compile(r"\[([^\]]+)\]\([^)]+\)"), r"\1"),
            (re.compile(r"#{1,6}\s+"), ""),
            (re.compile(r"\*{1,3}"), ""),
            (re.compile(r"_{1,3}"), ""),
            (re.compile(r"`{1,3}[^`]*`{1,3}"), ""),
            (re.compile(r">\s+"), ""),
            (re.compile(r"\|\|.*?\|\|"), ""),
            (re.compile(r"~~.*?~~"), ""),
        ]

    def clean(self, text: str) -> str:
        result = text
        for pattern, replacement in self.strip_patterns:
            result = pattern.sub(replacement, result)
        result = re.sub(r"\n{3,}", "\n\n", result)
        result = re.sub(r" {2,}", " ", result)
        return result.strip()

    def clean_entries(self, entries: List[dict]) -> List[dict]:
        for entry in entries:
            entry["cleaned_text"] = self.clean(entry["raw_text"])
        return entries
