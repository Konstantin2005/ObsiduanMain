"""
Nirvana Bridge — MCP client wrapper.

Uses raw HTTP POST + SSE parsing instead of the full MCP SDK transport,
because Nirvana's MCP server uses one-shot POST requests with SSE responses
(inline, not persistent GET streaming).

Provides:
- Reconnect with exponential backoff
- Heartbeat (periodic ping)
- Circuit breaker pattern
- Graceful shutdown
"""

import asyncio
import json
import logging
import re
import time
from enum import Enum
from typing import Callable

import httpx

from config import config

log = logging.getLogger("nirvana_bridge.mcp")


class CircuitState(Enum):
    CLOSED = "closed"       # normal operation
    OPEN = "open"           # failing — reject fast
    HALF_OPEN = "half_open" # testing recovery


class CircuitBreaker:
    """Simple circuit breaker for MCP operations."""

    def __init__(self):
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.threshold = config.CB_FAIL_THRESHOLD
        self.recovery_timeout = config.CB_RECOVERY_TIMEOUT
        self.half_open_max = config.CB_HALF_OPEN_MAX
        self._last_failure_time = 0.0
        self._half_open_attempts = 0

    def on_success(self) -> None:
        self.failure_count = 0
        self._half_open_attempts = 0
        if self.state == CircuitState.HALF_OPEN:
            log.info("Circuit breaker: half-open -> closed (success)")
            self.state = CircuitState.CLOSED

    def on_failure(self) -> bool:
        """Record a failure. Returns True if circuit is now open."""
        self.failure_count += 1
        self._last_failure_time = time.monotonic()

        if self.state == CircuitState.HALF_OPEN:
            self._half_open_attempts += 1
            if self._half_open_attempts >= self.half_open_max:
                log.warning(
                    f"Circuit breaker: half-open -> open "
                    f"({self._half_open_attempts} failures)"
                )
                self.state = CircuitState.OPEN
                return True
            return False

        if self.failure_count >= self.threshold:
            log.warning(
                f"Circuit breaker: closed -> open "
                f"({self.failure_count} failures)"
            )
            self.state = CircuitState.OPEN
            return True
        return False

    def allow_request(self) -> bool:
        if self.state == CircuitState.CLOSED:
            return True
        if self.state == CircuitState.OPEN:
            elapsed = time.monotonic() - self._last_failure_time
            if elapsed >= self.recovery_timeout:
                log.info("Circuit breaker: open -> half-open (timeout elapsed)")
                self.state = CircuitState.HALF_OPEN
                self._half_open_attempts = 0
                return True
            return False
        return self._half_open_attempts < self.half_open_max

    @property
    def state_name(self) -> str:
        return self.state.value


class McpClient:
    """Managed MCP connection with auto-reconnect.

    Uses direct HTTP POST + SSE parsing to talk to the Nirvana MCP server.
    The server responds to each POST with a text/event-stream response
    containing one or more JSON-RPC messages.
    """

    def __init__(
        self,
        on_connected: Callable = None,
        on_disconnected: Callable = None,
    ):
        self._url = config.NIRVANA_MCP_URL
        self._timeout = config.MCP_TIMEOUT
        self._heartbeat_interval = config.HEARTBEAT_INTERVAL

        # Connection state
        self._connected = False
        self._http_client: httpx.AsyncClient | None = None

        # Protocol capabilities (negotiated during init)
        self._server_caps: dict = {}
        self._server_info: dict = {}
        self._protocol_version: str | None = None

        # Lifespan
        self._running = False
        self._tasks: list[asyncio.Task] = []

        # Circuit breaker
        self.circuit = CircuitBreaker()

        # Callbacks
        self.on_connected = on_connected
        self.on_disconnected = on_disconnected

        # JSON-RPC request counter
        self._req_id = 0

        self.log = logging.getLogger("nirvana_bridge.mcp")

    # ── Properties ───────────────────────────────────────────────────

    @property
    def is_connected(self) -> bool:
        return self._connected

    @property
    def transport(self) -> str:
        return "streamable-http" if self._connected else "disconnected"

    # ── Auth headers ─────────────────────────────────────────────────

    def _auth_headers(self) -> dict[str, str]:
        pat = config.NIRVANA_PAT
        if not pat:
            self.log.warning("NIRVANA_PAT is empty — auth will fail")
        return {
            "Authorization": f"Bearer {pat}",
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }

    # ── HTTP helpers ─────────────────────────────────────────────────

    def _client(self) -> httpx.AsyncClient:
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(
                timeout=httpx.Timeout(self._timeout, read=120.0),
            )
        return self._http_client

    async def _close_http(self) -> None:
        if self._http_client:
            await self._http_client.aclose()
            self._http_client = None

    # ── SSE parsing ──────────────────────────────────────────────────

    def _parse_sse(self, text: str) -> list[dict]:
        """Parse a text/event-stream body into JSON-RPC messages."""
        messages = []
        data_buf = []

        for line in text.split("\n"):
            line = line.strip()
            if line.startswith("data: "):
                data_buf.append(line[6:])
            elif line.startswith("data:"):
                data_buf.append(line[5:])
            elif line == "" and data_buf:
                # Empty line = end of event
                payload = "".join(data_buf)
                data_buf = []
                if payload.strip():
                    try:
                        messages.append(json.loads(payload))
                    except json.JSONDecodeError as e:
                        self.log.debug(f"SSE parse error: {e}")
            elif line.startswith("event: "):
                pass  # We don't need event type for MCP

        # Handle case where there's no trailing empty line
        if data_buf:
            payload = "".join(data_buf)
            if payload.strip():
                try:
                    messages.append(json.loads(payload))
                except json.JSONDecodeError as e:
                    self.log.debug(f"SSE parse error (final): {e}")

        return messages

    # ── JSON-RPC call ────────────────────────────────────────────────

    async def _rpc_call(self, method: str, params: dict | None = None, *, check_connected: bool = True) -> dict | None:
        """Make a JSON-RPC call via POST and return the result."""
        if check_connected and not self._connected:
            self.log.warning(f"RPC call {method!r} while disconnected")
            return None

        if not self.circuit.allow_request():
            self.log.warning(f"Circuit breaker open — RPC {method!r} rejected")
            return None

        self._req_id += 1
        req_id = self._req_id

        body = {
            "jsonrpc": "2.0",
            "id": req_id,
            "method": method,
            "params": params or {},
        }

        headers = self._auth_headers()

        try:
            async with asyncio.timeout(self._timeout):
                response = await self._client().post(
                    self._url,
                    json=body,
                    headers=headers,
                )

            if response.status_code == 401:
                self.log.error("Authentication failed — check NIRVANA_PAT")
                self.circuit.on_failure()
                return None

            response.raise_for_status()
            content_type = response.headers.get("content-type", "").lower()

            if "text/event-stream" in content_type:
                messages = self._parse_sse(response.text)
                for msg in messages:
                    # Match by id or if no id, take first result
                    if msg.get("id") == req_id:
                        if "error" in msg:
                            err = msg["error"]
                            self.log.error(
                                f"RPC {method!r} error: "
                                f"[{err.get('code')}] {err.get('message')}"
                            )
                            self.circuit.on_failure()
                            return None
                        self.circuit.on_success()
                        return msg.get("result")
                # If no matching id found, return first result
                for msg in messages:
                    if "result" in msg and "error" not in msg:
                        self.circuit.on_success()
                        return msg["result"]
                    if "error" in msg:
                        self.log.error(f"RPC {method!r} error: {msg['error']}")
                        self.circuit.on_failure()
                        return None
            else:
                # Try JSON response
                try:
                    data = response.json()
                except Exception:
                    self.log.error(
                        f"RPC {method!r}: unexpected response "
                        f"(status={response.status_code}, "
                        f"type={content_type})"
                    )
                    self.circuit.on_failure()
                    return None

                if "error" in data:
                    err = data["error"]
                    self.log.error(
                        f"RPC {method!r} error: "
                        f"[{err.get('code')}] {err.get('message')}"
                    )
                    self.circuit.on_failure()
                    return None

                self.circuit.on_success()
                return data.get("result")

        except asyncio.TimeoutError:
            self.log.error(f"RPC {method!r} timed out")
            self.circuit.on_failure()
            return None
        except httpx.HTTPStatusError as e:
            self.log.error(f"RPC {method!r} HTTP error: {e.response.status_code}")
            self.circuit.on_failure()
            return None
        except httpx.RequestError as e:
            self.log.error(f"RPC {method!r} request error: {e}")
            self.circuit.on_failure()
            return None
        except Exception as e:
            self.log.error(f"RPC {method!r} unexpected error: {e}")
            self.circuit.on_failure()
            return None

    # ── Connect / Disconnect ─────────────────────────────────────────

    async def connect(self) -> bool:
        """Connect to the MCP server by sending an initialize request."""
        pat = config.NIRVANA_PAT
        if not pat:
            self.log.error("NIRVANA_PAT not set — cannot connect")
            return False

        if not self.circuit.allow_request():
            self.log.warning(
                f"Circuit breaker {self.circuit.state_name} — "
                f"connection refused"
            )
            return False

        # Send initialize (bypass connected check — we're connecting)
        result = await self._rpc_call("initialize", {
            "protocolVersion": "2025-03-26",
            "capabilities": {},
            "clientInfo": {
                "name": "nirvana-bridge",
                "version": "1.0.0",
            },
        }, check_connected=False)

        if result is None:
            return False

        # Store server info
        self._server_caps = result.get("capabilities", {})
        self._server_info = result.get("serverInfo", {})
        self._protocol_version = result.get("protocolVersion")

        self.log.info(
            f"Connected to {self._server_info.get('name', 'MCP')} "
            f"v{self._server_info.get('version', '?')} "
            f"(protocol {self._protocol_version})"
        )
        self.log.info(
            f"Server: {self._server_info.get('description', '')[:80]}"
        )

        self._connected = True
        self.circuit.on_success()

        if self.on_connected:
            await self._safe_call(self.on_connected)

        return True

    async def disconnect(self) -> None:
        """Tear down the connection."""
        self._connected = False
        if self.on_disconnected:
            await self._safe_call(self.on_disconnected)
        self.log.info("Disconnected")

    async def _safe_call(self, fn) -> None:
        try:
            if asyncio.iscoroutinefunction(fn):
                await fn()
            else:
                fn()
        except Exception as exc:
            self.log.warning(f"Callback failed: {exc}")

    # ── Heartbeat ────────────────────────────────────────────────────

    async def _heartbeat_loop(self) -> None:
        """Periodic ping to verify connection health."""
        while self._running:
            await asyncio.sleep(self._heartbeat_interval)
            if not self._connected:
                continue
            try:
                ok = await self._rpc_call("ping")
                if ok is not None:
                    self.log.debug("Heartbeat OK")
                else:
                    self.log.warning("Heartbeat failed")
                    await self._handle_disconnect()
            except Exception as exc:
                self.log.warning(f"Heartbeat error: {exc}")
                await self._handle_disconnect()

    # ── Reconnect Loop ───────────────────────────────────────────────

    async def _reconnect_loop(self) -> None:
        """Background task: keep connection alive with exponential backoff."""
        delay = config.RECONNECT_BASE_DELAY

        while self._running:
            if not self._connected:
                self.log.info(
                    f"Reconnecting in {delay:.0f}s "
                    f"(circuit: {self.circuit.state_name})"
                )
                await asyncio.sleep(delay)

                ok = await self.connect()
                if ok:
                    delay = config.RECONNECT_BASE_DELAY
                else:
                    delay = min(delay * 2, config.RECONNECT_MAX_DELAY)
            else:
                await asyncio.sleep(1)

    async def _handle_disconnect(self) -> None:
        """Called when the connection drops unexpectedly."""
        self.log.warning("Connection lost")
        was_connected = self._connected
        self._connected = False
        # Don't need explicit reconnect call — _reconnect_loop picks it up

    # ── Tool Calling ─────────────────────────────────────────────────

    async def call_tool(self, name: str, arguments: dict) -> dict | None:
        """Call an MCP tool. Returns structured content or None on error."""
        if not self._connected:
            self.log.warning(f"Tool {name!r} called while disconnected")
            return None

        result = await self._rpc_call("tools/call", {
            "name": name,
            "arguments": arguments,
        })

        if result is None:
            return None

        # Extract text content from result
        response = {}
        if "content" in result:
            texts = []
            for c in result["content"]:
                if isinstance(c, dict) and c.get("type") == "text":
                    texts.append(c.get("text", ""))
                elif isinstance(c, dict) and c.get("text"):
                    texts.append(c["text"])
            response["text"] = "\n".join(texts)
            response["content"] = result["content"]

        # Check for isError
        if result.get("isError"):
            err_text = response.get("text", "unknown error")
            self.log.error(f"Tool {name!r} returned error: {err_text}")
            self.circuit.on_failure()
            return None

        self.circuit.on_success()
        return response

    async def list_tools(self) -> list:
        """List available MCP tools. Returns empty list on error."""
        result = await self._rpc_call("tools/list")
        if result is None:
            return []
        return result.get("tools", [])

    # ── High-level helpers ───────────────────────────────────────────

    async def create_tasks(self, tasks: list[dict]) -> dict | None:
        """Create one or more tasks/projects. 
        
        Each item supports: name, note, state, type, tags, starred,
        duedate, startdate, energy, etime, parentid, waitingfor.
        """
        return await self.call_tool("create_tasks", {"tasks": tasks})

    async def update_tasks(self, updates: list[dict]) -> dict | None:
        """Update one or more tasks/projects.
        
        Each item must have 'id' plus any fields to change.
        Fields: name, note, state, tags, starred, completed,
        duedate, startdate, energy, etime, parentid, waitingfor.
        """
        return await self.call_tool("update_tasks", {"updates": updates})

    async def get_tasks(self, **params) -> list[dict] | None:
        """Get tasks from Nirvana with optional filters.
        
        Filters: state, type, tags, query, starred, overdue,
        due_before, due_after, include_notes, limit, offset.
        Returns list of task dicts or None on error.
        """
        result = await self.call_tool("get_tasks", params or {})
        if result is None:
            return None
        text = result.get("text", "")
        if text:
            try:
                import json
                data = json.loads(text)
                return data.get("tasks", [])
            except json.JSONDecodeError:
                pass
        return []

    async def delete_task(self, task_id: str) -> dict | None:
        """Move a task/project to trash."""
        return await self.update_tasks([{"id": task_id, "state": "trash"}])

    async def complete_task(self, task_id: str) -> dict | None:
        """Mark a task as completed."""
        return await self.update_tasks([{"id": task_id, "completed": True}])

    async def set_energy(self, task_id: str, energy: int) -> dict | None:
        """Set energy level (1=low, 2=medium, 3=high)."""
        energy = max(0, min(3, int(energy)))
        return await self.update_tasks([{"id": task_id, "energy": energy}])

    async def set_schedule(self, task_id: str, *, due_date: str = "", start_date: str = "") -> dict | None:
        """Set due date and/or scheduled start date (YYYY-MM-DD)."""
        update = {"id": task_id}
        if due_date:
            update["duedate"] = due_date
        if start_date:
            update["startdate"] = start_date
        return await self.update_tasks([update])

    # ── Lifespan ─────────────────────────────────────────────────────

    async def start(self) -> None:
        """Launch heartbeat and reconnect loops."""
        self._running = True
        self._tasks = [
            asyncio.create_task(self._heartbeat_loop(), name="mcp-heartbeat"),
            asyncio.create_task(self._reconnect_loop(), name="mcp-reconnect"),
        ]
        # Initial connection (non-blocking — reconnect loop handles it)
        await self.connect()

    async def stop(self) -> None:
        """Graceful shutdown."""
        self._running = False
        for t in self._tasks:
            t.cancel()
        await asyncio.gather(*self._tasks, return_exceptions=True)
        self._tasks.clear()
        await self.disconnect()
        await self._close_http()
