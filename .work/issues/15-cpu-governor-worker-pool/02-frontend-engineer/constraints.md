# Constraints & Safety Rules

## Throttle Scenarios

| Condition | Action | Recovery |
|-----------|--------|----------|
| eventLoopDelayP95 > 32ms | Scale down workers, reduce chunks | Next observe() if metrics improve |
| memoryUsedRatio > 0.85 | Emergency throttle, cancel all tasks | resume() when memory freed |
| throughputGain < 0.08 | Scale down 1 worker, reduce in-flight | Scale up when gain improves |
| diskLatencyMs > 50 | Pause IO, cache-only low priority | Resume IO after 1 observe cycle |
| gcPauseMs > 40 | Reduce workers, reduce chunks | Gradual scale up |
| batterySafeMode | Force minWorkers, cache-only | resume() on AC power |

## Integration Points

### WorkerTaskController changes
- `setWorkerConfig(config)` — динамическая смена конфига
- `getWorkerConfig()` — чтение текущего конфига
- WorkerConfig влияет на: количество параллельных задач, размер чанков, IO паузы

### ThroughputGovernor changes (none)
- Остаётся pure decision-maker
- Bridge адаптирует решение под WorkerTaskController API

### GraphScheduler relationship
- Scheduler управляет frame budget и adaptive profile
- Bridge управляет worker pool и throughput
- Не пересекаются: scheduler → frame, bridge → throughput
