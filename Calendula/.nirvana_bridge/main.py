"""
Nirvana Bridge — Production service entry point.

Orchestrates:
  - MCP client (persistent connection, reconnect, heartbeat)
  - Queue manager (background task processing)
  - HTTP API (health, stats, task submission)
  - Graceful shutdown (SIGINT / SIGTERM)

Usage:
  python main.py                    # start service
  python main.py --test             # run self-tests
  python main.py --test-stress N    # run stress test with N tasks
"""

import argparse
import asyncio
import logging
import os
import signal
import sys
import time

import uvicorn

from config import config
from database import Database
from health import create_app
from logger import setup_logging
from mcp_client import McpClient
from queue_manager import QueueManager

log = logging.getLogger("nirvana_bridge")


# ═════════════════════════════════════════════════════════════════════════
# SERVICE
# ═════════════════════════════════════════════════════════════════════════


class BridgeService:
    """Top-level orchestrator for the Nirvana bridge."""

    def __init__(self):
        self.db = Database()
        self.mcp = McpClient(
            on_connected=self._on_mcp_connected,
            on_disconnected=self._on_mcp_disconnected,
        )
        self.queue = QueueManager(self.db, self.mcp)
        self._http_server: asyncio.Task | None = None
        self._running = False

    # ── Callbacks ────────────────────────────────────────────────────

    async def _on_mcp_connected(self):
        log.info("MCP connected — queue processing active")

    async def _on_mcp_disconnected(self):
        log.warning("MCP disconnected — queue paused")

    # ── Lifespan ─────────────────────────────────────────────────────

    async def start(self):
        self._running = True
        log.info("=" * 60)
        log.info("Nirvana Bridge starting")
        log.info(f"DB: {config.DB_PATH}")
        log.info(f"MCP: {config.NIRVANA_MCP_URL}")
        log.info(f"HTTP: {config.HTTP_HOST}:{config.HTTP_PORT}")
        log.info("=" * 60)

        # Start MCP client
        await self.mcp.start()

        # Start queue processor
        await self.queue.start()

        # Start HTTP server
        app = create_app(mcp_client=self.mcp, queue_manager=self.queue)
        cfg = uvicorn.Config(
            app,
            host=config.HTTP_HOST,
            port=config.HTTP_PORT,
            log_level="warning",
            loop="asyncio",
        )
        server = uvicorn.Server(cfg)
        self._http_server = asyncio.create_task(server.serve())

        log.info(f"HTTP API at http://{config.HTTP_HOST}:{config.HTTP_PORT}")

    async def stop(self):
        log.info("Shutting down...")

        # Stop queue first (no new tasks sent)
        await self.queue.stop()

        # Stop MCP
        await self.mcp.stop()

        # Stop HTTP
        if self._http_server:
            self._http_server.cancel()
            try:
                await self._http_server
            except (asyncio.CancelledError, KeyboardInterrupt):
                pass

        # Close DB
        self.db.close()

        self._running = False
        log.info("Bye.")


# ═════════════════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════════════════


async def async_main():
    """Start the bridge service and wait for shutdown signal."""
    service = BridgeService()

    # ── Signal handling ──────────────────────────────────────────
    stop_event = asyncio.Event()

    def _signal_handler():
        log.info("Signal received — shutting down")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, _signal_handler)
        except NotImplementedError:
            # Windows doesn't support add_signal_handler fully
            pass

    setup_logging()
    log.info("Logging initialized")

    try:
        await service.start()
        await stop_event.wait()
    except asyncio.CancelledError:
        pass
    finally:
        await service.stop()


def run_service():
    """Entry point: parse args and run service or tests."""
    parser = argparse.ArgumentParser(description="Nirvana Bridge Service")
    parser.add_argument("--test", action="store_true", help="Run self-tests")
    parser.add_argument(
        "--test-stress", type=int, default=0,
        help="Run stress test with N tasks (e.g. --test-stress 100)",
    )
    args = parser.parse_args()

    # Validate PAT early (skip check for --test which uses local DB only)
    if not config.NIRVANA_PAT and not args.test and not args.test_stress:
        print("ERROR: NIRVANA_PAT environment variable is not set.")
        print("       Set it before running:")
        print('       $env:NIRVANA_PAT = "nt_nirvana_..."')
        sys.exit(1)

    if args.test:
        from tests.test_bridge import run_tests
        run_tests()
    elif args.test_stress:
        from tests.test_bridge import run_stress_test
        asyncio.run(run_stress_test(args.test_stress))
    else:
        asyncio.run(async_main())


if __name__ == "__main__":
    run_service()
