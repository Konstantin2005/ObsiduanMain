import os
from pathlib import Path
from typing import List, Optional


class Loader:
    SUPPORTED_EXTENSIONS = {".txt", ".md", ".mdx"}

    def __init__(self, data_dirs: Optional[List[str]] = None):
        self.data_dirs = data_dirs or []

    def load_file(self, file_path: str) -> Optional[str]:
        path = Path(file_path)
        if not path.exists():
            return None
        if path.suffix.lower() not in self.SUPPORTED_EXTENSIONS:
            return None
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()

    def load_directory(self, directory: str) -> List[tuple[str, str]]:
        results = []
        path = Path(directory)
        if not path.exists() or not path.is_dir():
            return results
        for file_path in path.rglob("*"):
            if file_path.suffix.lower() in self.SUPPORTED_EXTENSIONS:
                content = self.load_file(str(file_path))
                if content:
                    results.append((str(file_path), content))
        return results

    def load_all_dirs(self) -> List[tuple[str, str]]:
        results = []
        for directory in self.data_dirs:
            results.extend(self.load_directory(directory))
        return results

    def load_text(self, text: str, source: str = "manual") -> tuple[str, str]:
        return (source, text)
