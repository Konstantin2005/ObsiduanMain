from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List


@dataclass
class Entry:
    id: Optional[int] = None
    source: str = "manual"
    raw_text: str = ""
    cleaned_text: Optional[str] = None
    created_at: Optional[str] = None
    source_file: Optional[str] = None


@dataclass
class Memory:
    id: Optional[int] = None
    entry_id: int = 0
    content: str = ""
    embedding: Optional[bytes] = None
    memory_type: str = "fact"
    confidence: float = 0.0
    created_at: Optional[str] = None


@dataclass
class Task:
    id: Optional[int] = None
    memory_id: Optional[int] = None
    title: str = ""
    description: Optional[str] = None
    confidence: float = 0.0
    status: str = "memory"
    source_entry_id: Optional[int] = None
    created_at: Optional[str] = None


@dataclass
class Suggestion:
    type: str = "task"
    title: str = ""
    confidence: float = 0.0
    reason: str = ""
    recommended_action: str = ""
    task_id: Optional[int] = None


@dataclass
class Feedback:
    id: Optional[int] = None
    task_id: int = 0
    decision: str = ""
    reason: Optional[str] = None
    created_at: Optional[str] = None


@dataclass
class AnalyzeResult:
    items: List[Suggestion] = field(default_factory=list)
