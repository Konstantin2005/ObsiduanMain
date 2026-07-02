# Decisions — Error → Task → Execution

| # | Decision | Rationale | Status |
|---|----------|-----------|--------|
| 1 | Task schema with dedup_key | Исключает duplicate tasks | ✅ |
| 2 | State machine (7 states) | Чёткий lifecycle, нет тупиков | ✅ |
| 3 | readiness_score для выбора | Приоритизация задач | ✅ |
| 4 | Max 3 retries | Не зацикливается | ✅ |
| 5 | /meta/ для dedup cache | Быстрая проверка без сканирования | ✅ |
