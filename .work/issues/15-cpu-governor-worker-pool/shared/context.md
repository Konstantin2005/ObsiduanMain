# Context: Wire CPU Governor to Worker Pool (#15)

## Source
GitHub Issue #15: Подключить управление нагрузкой CPU и пропускной способностью

## Цель
Связать ThroughputGovernor (принимает решения) с WorkerTaskController (исполняет задачи), чтобы runtime автоматически throttлился под нагрузкой.

## Существующие файлы
- `Technical/Scripts/Obsidian/graph-throughput-governor.js` — ThroughputGovernor, SLA evaluation, resource profiling
- `Technical/Scripts/Obsidian/graph-worker-layer.js` — WorkerTaskController, task scheduling, cancellation
- `Technical/Scripts/Obsidian/graph-governors.js` — FrameGovernor, MemoryGovernor, IOGovernor, BudgetPolicy
- `Technical/Scripts/Rendering/graph-scheduler.js` — GraphScheduler, backpressure detection

## Новый файл
- `Technical/Scripts/Obsidian/graph-governor-worker-bridge.js` — GovernorWorkerBridge

## Изменяемый файл
- `Technical/Scripts/Obsidian/graph-worker-layer.js` — добавить setWorkerConfig/getWorkerConfig

## Статус
- [x] Architect — план, архитектура, решения
- [x] Backend — GovernorWorkerBridge + WorkerTaskController config
- [x] Frontend — SAFE MODE диаграмма + 10 constraints
- [x] QA — 10 test cases + edge cases + failure scenarios
- [x] Code Review — approved

## Итог
- Новый файл: `Technical/Scripts/Obsidian/graph-governor-worker-bridge.js`
- Изменён: `Technical/Scripts/Obsidian/graph-worker-layer.js` (+setWorkerConfig/getWorkerConfig)
- Все 10 safety constraints соблюдены
- Production ready ✓
