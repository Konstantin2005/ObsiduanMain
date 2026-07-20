"""
Nirvana Bridge — logging setup with rotation and sanitisation.
"""

import logging
import logging.handlers
import re
import sys
from pathlib import Path

from config import config

# Patterns to redact from logs
_REDACT_PATTERNS = [
    (re.compile(r"(Bearer\s+)[\w\-\.]+"), r"\1***REDACTED***"),
    (re.compile(r'(PAT["\']?\s*[:=]\s*["\']?)[^"\'\s]+'), r"\1***REDACTED***"),
    (re.compile(r"(token\s*[:=]\s*)[^\s,}]+"), r"\1***REDACTED***"),
]


class RedactingFormatter(logging.Formatter):
    """Formatter that redacts sensitive data (tokens, passwords)."""

    def format(self, record: logging.LogRecord) -> str:
        msg = super().format(record)
        for pattern, replacement in _REDACT_PATTERNS:
            msg = pattern.sub(replacement, msg)
        return msg


def setup_logging(name: str = "nirvana_bridge") -> logging.Logger:
    """Configure and return a logger with file rotation and stdout."""
    log_dir = Path(config.LOG_DIR)
    log_dir.mkdir(parents=True, exist_ok=True)

    log_path = log_dir / "bridge.log"
    error_path = log_dir / "error.log"

    logger = logging.getLogger(name)
    logger.setLevel(config.LOG_LEVEL.upper())
    logger.handlers.clear()

    formatter = RedactingFormatter(
        fmt="%(asctime)s [%(levelname).1s] %(name)s:%(lineno)d %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # — File handler (all levels, rotating) —
    file_handler = logging.handlers.RotatingFileHandler(
        log_path, maxBytes=10 * 1024 * 1024, backupCount=5, encoding="utf-8"
    )
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    # — Error file handler (ERROR+) —
    error_handler = logging.handlers.RotatingFileHandler(
        error_path, maxBytes=10 * 1024 * 1024, backupCount=3, encoding="utf-8"
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(formatter)

    # — Stdout handler —
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(config.LOG_LEVEL.upper())
    stdout_handler.setFormatter(
        RedactingFormatter(
            fmt="%(asctime)s [%(levelname).1s] %(message)s",
            datefmt="%H:%M:%S",
        )
    )

    logger.addHandler(file_handler)
    logger.addHandler(error_handler)
    logger.addHandler(stdout_handler)

    return logger
