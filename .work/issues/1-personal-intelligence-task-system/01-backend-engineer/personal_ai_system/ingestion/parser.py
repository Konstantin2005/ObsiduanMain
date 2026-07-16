import re
from typing import List, Tuple


class Parser:
    def __init__(self):
        self.entry_separator = re.compile(r"\n\s*(?:[-*_]{3,}|#+\s|---)\s*\n")

    def split_entries(self, text: str) -> List[str]:
        parts = self.entry_separator.split(text)
        return [p.strip() for p in parts if p.strip()]

    def extract_metadata(self, text: str) -> dict:
        metadata = {}
        date_match = re.search(
            r"(?:\d{4}[-/]\d{1,2}[-/]\d{1,2})|"
            r"(?:\d{1,2}[-/]\d{1,2}[-/]\d{4})|"
            r"(?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\s*\d{1,2}\s+"
            r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4})",
            text
        )
        if date_match:
            metadata["date"] = date_match.group(0)

        tags = re.findall(r"#(\w+)", text)
        if tags:
            metadata["tags"] = tags

        return metadata

    def parse_file(self, file_path: str, content: str) -> List[dict]:
        entries = self.split_entries(content)
        results = []
        for entry_text in entries:
            metadata = self.extract_metadata(entry_text)
            results.append({
                "source_file": file_path,
                "raw_text": entry_text,
                "metadata": metadata,
            })
        return results
