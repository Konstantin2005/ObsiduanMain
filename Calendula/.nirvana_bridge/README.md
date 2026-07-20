# Nirvana Bridge

Production-ready service that bridges local AI (LLM) with Nirvana task management via the official MCP protocol.

## Architecture

```
Local LLM
    │
    │  POST /task  {title, description, priority, ...}
    ▼
┌─────────────────────────────────────┐
│         Nirvana Bridge Service      │
│                                     │
│  ┌────────────┐   ┌──────────────┐  │
│  │ Queue      │──▶│ MCP Client   │──┼──▶ Nirvana MCP Server
│  │ Manager    │   │ (reconnect,  │  │        │
│  │ (SQLite)   │   │  heartbeat)  │  │        ▼
│  └────────────┘   └──────────────┘  │   Nirvana Tasks
│                                     │
│  ┌──────────────────────────────┐   │
│  │  HTTP API (FastAPI)          │   │
│  │  /health  /stats  /task      │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Set your Personal Access Token
$env:NIRVANA_PAT = "nt_nirvana_your_token"    # Windows PowerShell

# 2. Install
cd nirvana_bridge
pip install -r requirements.txt

# 3. Run
python main.py
```

## API Endpoints

| Method | Path       | Description                        |
|--------|------------|------------------------------------|
| POST   | `/task`    | Submit a new task to the queue     |
| GET    | `/health`  | Service health check               |
| GET    | `/stats`   | Detailed statistics                |

### POST /task

```json
{
  "title": "Buy groceries",
  "description": "Milk, eggs, bread",
  "priority": "medium",
  "due_date": "2026-07-20",
  "tags": ["shopping", "personal"]
}
```

Response:

```json
{
  "status": "queued",
  "nirvana_task_id": "",
  "created_at": "2026-07-14T12:00:00+00:00",
  "message": "Task abc12345 queued"
}
```

## Configuration

All settings via environment variables (see `.env.example`):

| Variable              | Default                            | Description                    |
|-----------------------|------------------------------------|--------------------------------|
| `NIRVANA_PAT`         | — **(required)**                   | Personal Access Token          |
| `NIRVANA_MCP_URL`     | `https://mcp.nirvanahq.com/mcp`    | MCP server URL                 |
| `NIRVANA_HTTP_PORT`   | `8712`                             | HTTP API port                  |
| `NIRVANA_HTTP_HOST`   | `127.0.0.1`                        | HTTP bind address              |
| `NIRVANA_MAX_RETRIES` | `5`                                | Max retries per task           |
| `NIRVANA_HEARTBEAT`   | `30`                               | Heartbeat interval (seconds)   |
| `NIRVANA_TPS`         | `10`                               | Rate limit (tasks/sec)         |
| `NIRVANA_LOG_LEVEL`   | `INFO`                             | Log level                      |

## Reliability Features

- **Persistent connection**: automatic reconnect with exponential backoff (1s → 60s)
- **Heartbeat**: periodic ping every 30s to detect disconnection
- **Circuit breaker**: opens after 5 consecutive failures, recovers after 30s
- **Local queue**: SQLite-backed, survives service restart
- **Retry policy**: automatic retry with configurable max attempts and delay
- **Rate limiting**: configurable tasks/second throttle
- **Graceful shutdown**: drains in-flight operations on SIGINT/SIGTERM
- **Secure logging**: PAT/tokens automatically redacted from logs

## Running as a Service

### Windows (NSSM)

```powershell
# Install NSSM: https://nssm.cc/download
nssm install NirvanaBridge "C:\Python314\python.exe" "C:\path\to\nirvana_bridge\main.py"
nssm set NirvanaBridge AppEnvironmentExtra NIRVANA_PAT=nt_nirvana_...
nssm start NirvanaBridge
```

### Linux (systemd)

```ini
# /etc/systemd/system/nirvana-bridge.service
[Unit]
Description=Nirvana Bridge
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/opt/nirvana_bridge
Environment=NIRVANA_PAT=nt_nirvana_...
ExecStart=/usr/bin/python3 /opt/nirvana_bridge/main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable nirvana-bridge
sudo systemctl start nirvana-bridge
```

## Testing

```bash
# Unit tests (database, queue, circuit breaker)
python main.py --test

# Stress test (1000 tasks through DB layer)
python main.py --test-stress 1000

# With real MCP connection (requires valid PAT)
$env:NIRVANA_PAT=nt_nirvana_real_token
python main.py --test
```

## Monitoring

```bash
# Health check
curl http://127.0.0.1:8712/health

# Stats
curl http://127.0.0.1:8712/stats

# Submit a task
curl -X POST http://127.0.0.1:8712/task \
  -H "Content-Type: application/json" \
  -d '{"title":"Test from curl","description":"Hello Nirvana!"}'
```

## Checking 24/7 Operation

```bash
# Watch health every 5 seconds
watch -n5 'curl -s http://127.0.0.1:8712/health | python -m json.tool'

# Check logs for errors
tail -f logs/error.log

# Monitor stats over time
watch -n30 'curl -s http://127.0.0.1:8712/stats | python -m json.tool'

# Verify task delivery in Nirvana
# Open https://focus.nirvanahq.com → Inbox
```

## Logs

| File              | Contents                        |
|-------------------|---------------------------------|
| `logs/bridge.log` | All events (rotating, 10MB×5)   |
| `logs/error.log`  | Errors only (rotating, 10MB×3)  |

## Project Structure

```
nirvana_bridge/
├── main.py              # Entry point, lifecycle
├── config.py            # Env-based configuration
├── logger.py            # Logging with redaction
├── database.py          # SQLite task queue
├── mcp_client.py        # MCP connection (reconnect, heartbeat, CB)
├── queue_manager.py     # Queue processor
├── health.py            # FastAPI HTTP server
├── tests/
│   └── test_bridge.py   # Tests A/B/C/D
├── data/                # SQLite DB location
├── logs/                # Log file location
├── .env.example         # Config template
├── requirements.txt
└── README.md
```
