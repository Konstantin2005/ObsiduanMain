"""
Nirvana Bridge — configuration.
All settings come from environment variables with sensible defaults.
"""

import os
from dataclasses import dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class Config:
    # ── Nirvana MCP ──────────────────────────────────────────────────
    NIRVANA_PAT: str = field(
        default_factory=lambda: os.environ.get("NIRVANA_PAT", "")
    )
    NIRVANA_MCP_URL: str = field(
        default_factory=lambda: os.environ.get(
            "NIRVANA_MCP_URL", "https://mcp.nirvanahq.com/mcp"
        )
    )

    # ── Queue ────────────────────────────────────────────────────────
    MAX_RETRIES: int = int(os.environ.get("NIRVANA_MAX_RETRIES", "5"))
    RETRY_BASE_DELAY: float = float(os.environ.get("NIRVANA_RETRY_DELAY", "2.0"))
    QUEUE_POLL_INTERVAL: float = float(os.environ.get("NIRVANA_QUEUE_POLL", "1.0"))

    # ── Connection ───────────────────────────────────────────────────
    MCP_TIMEOUT: float = float(os.environ.get("NIRVANA_MCP_TIMEOUT", "30.0"))
    MCP_SSE_READ_TIMEOUT: float = float(os.environ.get("NIRVANA_SSE_TIMEOUT", "120.0"))
    HEARTBEAT_INTERVAL: float = float(os.environ.get("NIRVANA_HEARTBEAT", "30.0"))
    RECONNECT_BASE_DELAY: float = float(os.environ.get("NIRVANA_RECONNECT_DELAY", "1.0"))
    RECONNECT_MAX_DELAY: float = float(os.environ.get("NIRVANA_RECONNECT_MAX", "60.0"))

    # ── Circuit Breaker ──────────────────────────────────────────────
    CB_FAIL_THRESHOLD: int = int(os.environ.get("NIRVANA_CB_THRESHOLD", "5"))
    CB_RECOVERY_TIMEOUT: float = float(os.environ.get("NIRVANA_CB_RECOVERY", "30.0"))
    CB_HALF_OPEN_MAX: int = int(os.environ.get("NIRVANA_CB_HALF_MAX", "3"))

    # ── HTTP Server ──────────────────────────────────────────────────
    HTTP_HOST: str = os.environ.get("NIRVANA_HTTP_HOST", "127.0.0.1")
    HTTP_PORT: int = int(os.environ.get("NIRVANA_HTTP_PORT", "8712"))

    # ── Paths ────────────────────────────────────────────────────────
    BASE_DIR: Path = Path(__file__).parent.resolve()
    DB_PATH: str = field(
        default_factory=lambda: os.environ.get(
            "NIRVANA_DB_PATH",
            str(Path(__file__).parent / "data" / "bridge.db"),
        )
    )
    LOG_DIR: str = field(
        default_factory=lambda: os.environ.get(
            "NIRVANA_LOG_DIR",
            str(Path(__file__).parent / "logs"),
        )
    )
    LOG_LEVEL: str = os.environ.get("NIRVANA_LOG_LEVEL", "INFO")

    # ── Rate Limiting ────────────────────────────────────────────────
    TASKS_PER_SECOND: float = float(os.environ.get("NIRVANA_TPS", "10.0"))


config = Config()
