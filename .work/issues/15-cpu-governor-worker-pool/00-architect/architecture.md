# Architecture: CPU Governor → Worker Pool

## Существующие компоненты

### ThroughputGovernor (graph-throughput-governor.js)
- Принимает: SLA report, resource profile, metrics sample
- Решает: scale up/down, emergency throttle, keep
- Выдаёт: GovernorDecision с actions, nextPolicy

### WorkerTaskController (graph-worker-layer.js)
- Принимает: type + payload + handler
- Управляет: generation (stale cancellation), taskId sequence
- Не имеет: динамической конфигурации (useWorker только boolean)

### GraphScheduler (graph-scheduler.js)
- Принимает: frame durations, input signals
- Решает: backpressure actions, adaptive profile
- Выдаёт: общий план рендера

## Новая архитектура: GovernorWorkerBridge

```
┌─────────────────────┐    observe()    ┌──────────────────────┐
│  ThroughputGovernor │◄───────────────│  GovernorWorkerBridge  │
│  (decides what)     │                │  (adapts worker pool)  │
└─────────┬───────────┘                └──────────┬────────────┘
          │ decision                              │ applyDecision
          ▼                                       ▼
┌─────────────────────┐                ┌──────────────────────┐
│  GovernorDecision   │                │  WorkerTaskController │
│  { actions,         │                │  (task execution)    │
│    nextPolicy }     │                └──────────────────────┘
└─────────────────────┘
```

### Поток данных
1. GovernorWorkerBridge собирает метрики (через SLA report + resource profile + system metrics)
2. Вызывает ThroughputGovernor.observe() → получает GovernorDecision
3. Применяет решение: меняет workerCount, chunk sizes, throttle policies
4. WorkerTaskController использует обновлённую конфигурацию для новых задач
5. Dashboard получает sample для отображения

### Правила SAFE MODE
- GovernorWorkerBridge НЕ вызывает ThroughputGovernor чаще 1 раза в 100ms
- Bridge НЕ хранит состояние — всё через ThroughputGovernor
- Emergency throttle форсирует minWorkers и cacheOnlyLowPriority
- Все решения логируются, но не триггерят новые решения
