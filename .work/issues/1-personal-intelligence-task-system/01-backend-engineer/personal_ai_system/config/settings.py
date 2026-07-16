import yaml
import os
from pathlib import Path
from dataclasses import dataclass
from typing import Optional


@dataclass
class Settings:
    ollama_url: str = "http://localhost:11434"
    ollama_model: str = "llama3"
    llm_fallback: str = "lm_studio"
    lm_studio_url: str = "http://localhost:1234/v1"
    auto_threshold: float = 85.0
    suggest_threshold: float = 50.0
    db_path: str = "pits_memory.db"
    vector_dim: int = 384
    log_dir: str = "logs"
    data_dirs: list = None

    def __post_init__(self):
        if self.data_dirs is None:
            self.data_dirs = ["./diary"]


def load_config(path: Optional[str] = None) -> Settings:
    if path is None:
        path = os.path.join(os.path.dirname(__file__), "config.yaml")
    if os.path.exists(path):
        with open(path, "r") as f:
            data = yaml.safe_load(f)
        return Settings(**data.get("pits", data))
    return Settings()
