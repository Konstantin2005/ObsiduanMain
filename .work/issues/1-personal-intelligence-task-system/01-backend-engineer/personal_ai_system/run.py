#!/usr/bin/env python3
import sys
import os
import logging
import uvicorn
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.settings import load_config
from api.main import create_app


def setup_logging(log_dir: str = "logs"):
    Path(log_dir).mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
        handlers=[
            logging.FileHandler(os.path.join(log_dir, "pits.log"), encoding="utf-8"),
            logging.StreamHandler(),
        ],
    )


def main():
    settings = load_config()
    setup_logging(settings.log_dir)
    logger = logging.getLogger("pits")
    logger.info("Starting PITS — Personal Intelligence Task System")
    logger.info("DB: %s", settings.db_path)
    logger.info("Auto threshold: %.1f, Suggest threshold: %.1f", settings.auto_threshold, settings.suggest_threshold)
    logger.info("Ollama: %s (model: %s)", settings.ollama_url, settings.ollama_model)

    app = create_app(settings)
    uvicorn.run(app, host="127.0.0.1", port=8100, log_level="info")


if __name__ == "__main__":
    main()
