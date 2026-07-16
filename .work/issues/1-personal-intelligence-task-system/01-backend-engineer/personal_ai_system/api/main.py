import logging
from fastapi import FastAPI
from .routes import router
from config.settings import Settings

logger = logging.getLogger("pits.api")


def create_app(settings: Settings) -> FastAPI:
    app = FastAPI(
        title="PITS — Personal Intelligence Task System",
        version="0.1.0",
        description="Local AI system that analyzes diaries and finds hidden tasks",
    )
    app.include_router(router, prefix="/api/v1")
    app.state.settings = settings
    return app
