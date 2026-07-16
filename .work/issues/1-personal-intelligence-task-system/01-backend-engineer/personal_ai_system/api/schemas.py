from pydantic import BaseModel, Field
from typing import List, Optional


class AnalyzeRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Diary entry text to analyze")
    context: Optional[str] = Field(None, description="Optional context from previous entries")


class SuggestionSchema(BaseModel):
    type: str = Field(..., description="task/idea/goal/problem/promise")
    title: str
    confidence: float = Field(..., ge=0, le=100)
    reason: str
    recommended_action: str


class AnalyzeResponse(BaseModel):
    items: List[SuggestionSchema] = []
    tasks_created: int = 0
    tasks_suggested: int = 0


class MemoryEntrySchema(BaseModel):
    id: Optional[int] = None
    source: str = "manual"
    text: str
    created_at: Optional[str] = None


class MemoryResponse(BaseModel):
    entries: List[MemoryEntrySchema] = []
    total: int = 0


class TaskSchema(BaseModel):
    id: Optional[int] = None
    title: str
    description: Optional[str] = None
    confidence: float = 0.0
    status: str = "memory"
    created_at: Optional[str] = None
