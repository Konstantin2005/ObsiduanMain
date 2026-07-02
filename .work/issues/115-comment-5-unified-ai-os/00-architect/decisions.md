# Decisions — Unified AI OS

| # | Decision | Rationale | Status |
|---|----------|-----------|--------|
| 1 | Control Plane как runtime/ | Выше agent-os/, управляет всем | ✅ |
| 2 | Adapters для каждого типа репо | Plug-in архитектура, легко добавлять | ✅ |
| 3 | Global context JSON | Единый source of truth | ✅ |
| 4 | Agent указывает target_repo | Явное связывание задачи с репо | ✅ |
| 5 | Central logs | Одна точка мониторинга | ✅ |
