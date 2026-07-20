# Nirvana Bridge — Complete Overview

> **Status:** RUNNING on `http://127.0.0.1:8712`
> **Version:** 2.0.0
> **Last tested:** All 19 unit tests PASS + 14 live API tests PASS

---

## 1. Architecture

```
┌─ Local LLM / HTTP Client ─────────────────────────────┐
│  POST /api/tasks    GET /api/tasks                     │
│  POST /api/projects PUT /api/tasks/{id}/energy         │
│  DELETE /api/tasks/{id}  ...                           │
└─────────────────────────┬──────────────────────────────┘
                          │ port 8712
┌─────────────────────────▼──────────────────────────────┐
│              Nirvana Bridge (FastAPI)                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Queue Manager (async background loop)            │  │
│  │  ┌─────────┐  PENDING → SENDING → SENT → ✓      │  │
│  │  │ SQLite  │  RETRY → max 5 → FAILED             │  │
│  │  │ (WAL)   │  Rate limit: 10 TPS                 │  │
│  │  └─────────┘  Auto-confirm via get_tasks          │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  MCP Client (POST + SSE, no SDK transport)        │  │
│  │  ┌──────────────┐  ┌─────────────┐               │  │
│  │  │ Circuit      │  │ Heartbeat   │               │  │
│  │  │ Breaker      │  │ (30s ping)  │               │  │
│  │  │ 5→open→30s→½ │  │ Reconnect   │               │  │
│  │  └──────────────┘  │ exp backoff │               │  │
│  │                     │ 1s→60s max  │               │  │
│  │                     └─────────────┘               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────┬──────────────────────────────┘
                          │ POST https://mcp.nirvanahq.com/mcp
                          │ Auth: Bearer nt_nirvana_...
                          │ Accept: application/json, text/event-stream
┌─────────────────────────▼──────────────────────────────┐
│              Nirvana MCP Server                         │
│  Tools: create_tasks  get_tasks  update_tasks           │
│         get_tags     get_task_counts                    │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
                   Nirvana Tasks (Web/App)
```

## 2. Project Structure

```
nirvana_bridge/
├── main.py              # Entry point (service / --test / --test-stress)
├── config.py            # 20+ params via env vars (frozen dataclass)
├── mcp_client.py        # MCP transport: POST+SSE, circuit breaker, reconnect
├── queue_manager.py     # Background queue: poll→send→confirm→retry
├── database.py          # SQLite WAL, threadsafe, status machine
├── health.py            # FastAPI app: all REST endpoints
├── logger.py            # Rotating logs + PAT redaction
├── tests/
│   ├── __init__.py
│   └── test_bridge.py   # 19 tests (A/B/C/D)
├── data/                # SQLite DB files (auto-created)
├── logs/                # bridge.log + error.log (auto-created)
├── requirements.txt     # Dependencies
├── .env.example         # Config template
└── BRIDGE_OVERVIEW.md   # This file
```

## 3. Configuration (all via env vars)

| Variable | Default | Description |
|----------|---------|-------------|
| `NIRVANA_PAT` | *(required)* | Personal Access Token |
| `NIRVANA_MCP_URL` | `https://mcp.nirvanahq.com/mcp` | MCP endpoint |
| `NIRVANA_MAX_RETRIES` | `5` | Max queue retries |
| `NIRVANA_QUEUE_POLL` | `1.0` | Queue poll interval (s) |
| `NIRVANA_MCP_TIMEOUT` | `30.0` | MCP request timeout (s) |
| `NIRVANA_SSE_TIMEOUT` | `120.0` | SSE read timeout (s) |
| `NIRVANA_HEARTBEAT` | `30.0` | Ping interval (s) |
| `NIRVANA_RECONNECT_DELAY` | `1.0` | Reconnect base delay (s) |
| `NIRVANA_RECONNECT_MAX` | `60.0` | Reconnect max delay (s) |
| `NIRVANA_CB_THRESHOLD` | `5` | Circuit breaker failure threshold |
| `NIRVANA_CB_RECOVERY` | `30.0` | Circuit breaker recovery (s) |
| `NIRVANA_HTTP_HOST` | `127.0.0.1` | HTTP bind address |
| `NIRVANA_HTTP_PORT` | `8712` | HTTP port |
| `NIRVANA_TPS` | `10.0` | Queue rate limit (tasks/sec) |
| `NIRVANA_DB_PATH` | `data/bridge.db` | SQLite path |
| `NIRVANA_LOG_DIR` | `logs/` | Log directory |
| `NIRVANA_LOG_LEVEL` | `INFO` | Log level |

## 4. All API Endpoints

### 4.1 Queue-based (reliable, async)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/tasks` | Create a task in queue |
| `POST` | `/api/projects` | Create a project in queue |

### 4.2 Read (direct MCP)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/tasks` | List/filter tasks & projects |
| `GET` | `/api/tags` | List all tags with counts |
| `GET` | `/api/task-counts` | Counts per GTD state |

### 4.3 Update / Manage (direct MCP)

| Method | Path | Description |
|--------|------|-------------|
| `PUT` | `/api/tasks` | Bulk update tasks (see fields below) |
| `DELETE` | `/api/tasks/{id}` | Move to trash |
| `POST` | `/api/tasks/{id}/complete` | Mark done |
| `PUT` | `/api/tasks/{id}/energy` | Set energy 0-3 |
| `PUT` | `/api/tasks/{id}/schedule` | Set due/start date |
| `PUT` | `/api/tasks/{id}/move` | Move to project |
| `PUT` | `/api/tasks/{id}/star` | Toggle focus list |

### 4.4 Generic MCP Proxy

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/mcp/{tool_name}` | Call any MCP tool with `{"params":...}` |

### 4.5 Monitoring

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Service health + MCP status |
| `GET` | `/stats` | Queue stats + DB metrics |

## 5. MCP Tools (Nirvana Server)

Discovered via `tools/list`:

| Tool | Description | Used By |
|------|-------------|---------|
| `create_tasks` | Create tasks & projects | Queue (queued), API proxy |
| `get_tasks` | Read/filter tasks | API (direct), Queue (confirmation) |
| `update_tasks` | Edit all task fields | API (direct) |
| `get_tags` | List tags with counts | API (direct) |
| `get_task_counts` | Task counts per GTD state | API (direct) |

### 5.1 create_tasks — Task Fields

```
tasks[].name       (string, required)    — Task name
tasks[].note       (string, optional)    — Description/notes
tasks[].state      (string, optional)    — inbox|next|waiting|scheduled|someday|later|active
tasks[].type       (string, optional)    — task (default) or project
tasks[].tags       (array, optional)     — Tag names
tasks[].starred    (boolean, optional)   — Add to Focus list
tasks[].duedate    (string, optional)    — YYYY-MM-DD
tasks[].startdate  (string, optional)    — YYYY-MM-DD (required for state=scheduled)
tasks[].energy     (number, optional)    — 1=low, 2=medium, 3=high
tasks[].etime      (number, optional)    — Estimated minutes
tasks[].parentid   (string, optional)    — Parent project ID
tasks[].waitingfor (string, optional)    — Person waited on (state=waiting)
```

### 5.2 update_tasks — Update Fields

```
updates[].id        (string, required)   — Nirvana task ID
updates[].name      (string, optional)   — New name
updates[].note      (string, optional)   — New note
updates[].state     (string, optional)   — New GTD state (+trash, +logbook)
updates[].tags      (array, optional)    — Full REPLACEMENT tag list
updates[].starred   (boolean, optional)  — true/false
updates[].completed (boolean, optional)  — true=done, false=reopen
updates[].duedate   (string, optional)   — YYYY-MM-DD ("" to clear)
updates[].startdate (string, optional)   — YYYY-MM-DD ("" to clear)
updates[].energy    (number, optional)   — 0=routine, 1=low, 2=medium, 3=high
updates[].etime     (number, optional)   — Estimated minutes
updates[].parentid  (string, optional)   — New parent project ("" to detach)
updates[].waitingfor(string, optional)   — Person waited on ("" to clear)
```

### 5.3 get_tasks — Filters

```
state          (string)  — inbox|next|waiting|scheduled|someday|later|active|logbook|trash (+comma-separated)
type           (string)  — task|project|reflist|refitem
query          (string)  — Keyword search (name + notes)
tags           (string)  — Comma-separated (AND logic)
starred        (boolean) — Focus list only
overdue        (boolean) — Past due date
due_before     (string)  — YYYY-MM-DD
due_after      (string)  — YYYY-MM-DD
include_notes  (boolean) — Include note text in response
limit          (number)  — Max results (default 50, max 200)
offset         (number)  — Pagination offset
```

## 6. Database Schema

SQLite file: `data/bridge.db` (WAL mode, thread-safe via RLock)

```sql
CREATE TABLE tasks (
    id              TEXT PRIMARY KEY,          -- UUID v4
    title           TEXT NOT NULL,
    description     TEXT DEFAULT '',
    priority        TEXT DEFAULT 'medium',     -- low|medium|high
    due_date        TEXT DEFAULT '',
    tags            TEXT DEFAULT '[]',          -- JSON array
    status          TEXT NOT NULL DEFAULT 'PENDING'
                    CHECK(status IN (
                        'PENDING','SENDING','SENT',
                        'CONFIRMED','FAILED','RETRY'
                    )),
    nirvana_task_id TEXT DEFAULT NULL,         -- returned by MCP
    error           TEXT DEFAULT NULL,
    retry_count     INTEGER NOT NULL DEFAULT 0,
    max_retries     INTEGER NOT NULL DEFAULT 5,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    sent_at         TEXT DEFAULT NULL,
    confirmed_at    TEXT DEFAULT NULL,
    item_type       TEXT NOT NULL DEFAULT 'task'  -- task|project
);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created ON tasks(created_at);
```

### Status Machine

```
PENDING ──▶ SENDING ──▶ SENT ──▶ CONFIRMED  ✓
                │          │
                ▼          ▼
             RETRY ◀───────┘ (max 5 attempts)
                │
                ▼
             FAILED  ✗
```

## 7. Resilience Features

### Circuit Breaker
- **Threshold:** 5 consecutive failures → OPEN
- **Recovery:** 30s wait → HALF-OPEN (3 probe requests)
- **Success:** Closes circuit
- **Scope:** All MCP `tools/call` and `tools/list` operations

### Reconnect (MCP)
- **Strategy:** Exponential backoff: 1s → 2s → 4s → ... → 60s max
- **Trigger:** Connection loss, heartbeat failure, auth failure
- **Loop:** Runs continuously in background task

### Heartbeat
- **Interval:** 30s (configurable)
- **Mechanism:** JSON-RPC `ping` via POST
- **On failure:** Triggers disconnect → reconnect loop

### Queue Retry
- **Max attempts:** 5 (configurable)
- **Delay:** 2s base (static, not backoff)
- **Triggers:** Timeout, MCP error, missing response, confirmation failure

### Logging
- **File rotation:** bridge.log (10MB × 5 files), error.log (10MB × 3 files)
- **PAT redaction:** Bearer tokens, PAT values, password fields masked as `***REDACTED***`
- **Format:** `YYYY-MM-DD HH:MM:SS [LEVEL] module:line message`

## 8. Running

### Start service
```bash
# Windows
$env:NIRVANA_PAT = "nt_nirvana_your_token_here"
python main.py

# Linux
export NIRVANA_PAT=nt_nirvana_your_token_here
python main.py
```

### Run tests (no PAT required)
```bash
python main.py --test                    # 19 unit tests
python main.py --test-stress 1000        # 1000 tasks stress test
```

### Service as background process (Windows)
```powershell
$env:NIRVANA_PAT = "nt_nirvana_..."
Start-Process -WindowStyle Hidden -FilePath "python" `
  -ArgumentList "-u main.py" `
  -WorkingDirectory "C:\path\to\nirvana_bridge"
```

### Install as Windows service (NSSM)
```powershell
nssm install NirvanaBridge "C:\Python314\python.exe" "C:\path\to\nirvana_bridge\main.py"
nssm set NirvanaBridge AppEnvironmentExtra NIRVANA_PAT=nt_nirvana_...
nssm start NirvanaBridge
```

## 9. Test Results (19/19 PASS)

| Test | Description | Checks | Status |
|------|-------------|--------|--------|
| **A** | Single task flow | Create → PENDING → SENDING → SENT → CONFIRMED, Retry (3x → FAILED), Stats | ✅ |
| **B** | 100 tasks integrity | All 100 accounted, no loss, correct distribution | ✅ |
| **C** | N tasks stress | Enqueue rate, process rate, zero loss (via `--test-stress N`) | ✅ |
| **D** | Failure simulation | DB persistence across restart, retry counting, circuit breaker states | ✅ |

### Live API Tests (all PASS)
- Task creation via queue → confirmed in Nirvana (avg 0.64s)
- Project creation via queue → confirmed in Nirvana
- Energy level change: `PUT /api/tasks/{id}/energy?energy=2`
- Schedule set: `PUT /api/tasks/{id}/schedule?duedate=2026-07-20`
- Move to project: `PUT /api/tasks/{id}/move?parentid=...`
- Star/unstar: `PUT /api/tasks/{id}/star?starred=true`
- Generic update: `PUT /api/tasks` with `[{"id":"...","note":"...","state":"next"}]`
- Complete: `POST /api/tasks/{id}/complete`
- Delete (trash): `DELETE /api/tasks/{id}`
- Restart resilience: 3 tasks survived kill/restart, all confirmed
- Bad PAT: graceful 401 handling, no crash
- Tags listing: `GET /api/tags`
- Task counts: `GET /api/task-counts`
- Generic MCP proxy: `POST /api/mcp/{tool}`

## 10. Example Usage

### Create a project
```bash
curl -X POST http://127.0.0.1:8712/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"AI Learning","description":"Deep learning studies","tags":["School"]}'
```

### Create a task with energy and due date
```bash
curl -X POST http://127.0.0.1:8712/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title":"Study Transformer Architecture",
    "description":"Read Attention Is All You Need",
    "priority":"high",
    "due_date":"2026-07-25",
    "tags":["School","Important"]
  }'
```

### Move to project, set energy, schedule
```bash
# Get task ID from response, then:
curl -X PUT "http://127.0.0.1:8712/api/tasks/{task_id}/move?parentid={project_id}"
curl -X PUT "http://127.0.0.1:8712/api/tasks/{task_id}/energy?energy=3"
curl -X PUT "http://127.0.0.1:8712/api/tasks/{task_id}/schedule?duedate=2026-07-25&startdate=2026-07-20"
```

### Bulk update
```bash
curl -X PUT http://127.0.0.1:8712/api/tasks \
  -H "Content-Type: application/json" \
  -d '[
    {"id":"uuid-1","state":"next","energy":2},
    {"id":"uuid-2","completed":true}
  ]'
```

### List inbox with filter
```bash
curl "http://127.0.0.1:8712/api/tasks?state=inbox&query=Transformer&limit=10"
```

### Generic MCP call
```bash
curl -X POST http://127.0.0.1:8712/api/mcp/get_task_counts \
  -H "Content-Type: application/json" \
  -d '{"params":{}}'
```

## 11. Future Development Roadmap

### Short term
- [ ] Add `POST /api/tasks/{id}/note` to append (not replace) notes
- [ ] Add estimated time (`etime`) to task creation and API
- [ ] Webhook support: notify on task confirmation
- [ ] Batch operations: process multiple tasks in one MCP call

### Medium term
- [ ] Frontend dashboard (streamlit or similar)
- [ ] Scheduled/recurring tasks via cron integration
- [ ] Multi-user support with separate PATs
- [ ] Task templates

### Long term
- [ ] Full Nirvana MCP -> REST API gateway
- [ ] OAuth2 flow for PAT management
- [ ] Docker deployment
- [ ] Plugin system for LLM integrations

---

*Generated: 2026-07-13*
*Service running on http://127.0.0.1:8712*
