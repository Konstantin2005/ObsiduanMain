# Decisions Log — Error Telemetry

| # | Decision | Rationale | Alternatives |
|---|----------|-----------|--------------|
| 1 | Async only logging | Не блокирует execution | Sync (блокирует) |
| 2 | Buffer queue (50 items / 5s) | Batching, не пишет каждый error | Single write (нагрузка) |
| 3 | JSONL format | Append-only, grep-friendly | JSON array (перезапись) |
| 4 | Fallback local storage | Не теряет данные если git repo недоступен | Skip on fail (потеря) |
| 5 | Git push в background | Асинхронно, не влияет на main thread | Sync push (блокирует) |
