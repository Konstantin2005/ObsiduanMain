# Decisions Log — Dual-Workflow

| # | Decision | Rationale | Alternatives |
|---|----------|-----------|--------------|
| 1 | READ-ONLY reference | Исключает watcher loop и re-index storm | Read-write (опасно) |
| 2 | Bridge layer как отдельный модуль | Чистое разделение, тестируемость | Встроенный импорт (нарушает изоляцию) |
| 3 | .opencodeignore для LINE B | OpenCode не индексирует reference | No exclude (мусор) |
| 4 | No runtime import между линиями | Исключает recursive loops | Cross-import (loop risk) |
