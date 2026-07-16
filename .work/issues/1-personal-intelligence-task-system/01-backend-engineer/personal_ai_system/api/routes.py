import logging
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import JSONResponse
from typing import List
from .schemas import AnalyzeRequest, AnalyzeResponse, SuggestionSchema, MemoryResponse, TaskSchema
from memory.database import Database
from memory.storage import Storage
from memory.search import SearchEngine
from memory.models import Entry, Suggestion, Memory
from analyzer import AnalyzerAgent
from decision_engine import DecisionRouter
from config.settings import Settings

logger = logging.getLogger("pits.api.routes")
router = APIRouter()


def get_storage():
    settings = router.settings if hasattr(router, "settings") else None
    if not settings:
        raise HTTPException(status_code=500, detail="Settings not initialized")
    db = Database(settings.db_path)
    db.create_schema()
    return Storage(db)


@router.on_event("startup")
async def startup():
    pass


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(request: AnalyzeRequest):
    try:
        settings = router.settings
        storage = get_storage()
        entry = Entry(source="manual", raw_text=request.text, cleaned_text=request.text)
        entry_id = storage.save_entry(entry)

        analyzer = AnalyzerAgent(settings.ollama_url, settings.ollama_model)
        suggestions = analyzer.analyze(request.text)

        decision = DecisionRouter(storage, settings.auto_threshold, settings.suggest_threshold)
        tasks = decision.route(suggestions, entry_id)

        return AnalyzeResponse(
            items=[SuggestionSchema(
                type=s.type,
                title=s.title,
                confidence=s.confidence,
                reason=s.reason,
                recommended_action=s.recommended_action,
            ) for s in suggestions],
            tasks_created=len([t for t in tasks if t.status == "automatic"]),
            tasks_suggested=len([t for t in tasks if t.status == "suggested"]),
        )
    except Exception as e:
        logger.error("Analyze failed: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/memory", response_model=MemoryResponse)
async def get_memory(limit: int = 100, offset: int = 0):
    try:
        storage = get_storage()
        entries = storage.get_all_entries(limit, offset)
        return MemoryResponse(entries=[{
            "id": e.id,
            "source": e.source,
            "text": e.cleaned_text or e.raw_text,
            "created_at": e.created_at,
        } for e in entries], total=len(entries))
    except Exception as e:
        logger.error("Get memory failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/suggestions", response_model=List[TaskSchema])
async def get_suggestions():
    try:
        storage = get_storage()
        tasks = storage.get_tasks_by_status("suggested")
        return [TaskSchema(
            id=t.id,
            title=t.title,
            description=t.description,
            confidence=t.confidence,
            status=t.status,
        ) for t in tasks]
    except Exception as e:
        logger.error("Get suggestions failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/tasks/auto", response_model=List[TaskSchema])
async def get_auto_tasks():
    try:
        storage = get_storage()
        tasks = storage.get_tasks_by_status("automatic")
        return [TaskSchema(
            id=t.id,
            title=t.title,
            description=t.description,
            confidence=t.confidence,
            status=t.status,
        ) for t in tasks]
    except Exception as e:
        logger.error("Get auto tasks failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/feedback/{task_id}")
async def submit_feedback(task_id: int, decision: str, reason: str = None):
    if decision not in ("accepted", "rejected"):
        raise HTTPException(status_code=400, detail="Decision must be 'accepted' or 'rejected'")
    try:
        storage = get_storage()
        storage.save_feedback({
            "task_id": task_id,
            "decision": decision,
            "reason": reason,
        })
        if decision == "accepted":
            storage.update_task_status(task_id, "approved")
        else:
            storage.update_task_status(task_id, "rejected")
        return {"status": "ok"}
    except Exception as e:
        logger.error("Feedback failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health():
    return {"status": "ok", "service": "pits"}
