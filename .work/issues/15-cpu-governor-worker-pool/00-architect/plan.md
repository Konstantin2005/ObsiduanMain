# Plan: Wire CPU Governor to Worker Pool (#15)

## Goal
Сделать runtime self-throttling под нагрузкой: ThroughputGovernor динамически управляет WorkerTaskController.

## Разбиение задачи

### Phase 1 — Архитектура
- [x] Анализ существующего кода: ThroughputGovernor, WorkerTaskController, GraphScheduler
- [x] API контракт между governor и worker pool
- [x] Разделение ответственности

### Phase 2 — Backend (реализация)
- [ ] GovernorWorkerBridge — адаптер между governor и worker pool
- [ ] Интеграция с ThroughputGovernor.observe()
- [ ] Динамическое изменение workerCount, chunkBytes, maxInFlightBytes
- [ ] Emergency throttle: pause IO, drop low priority, cache-only
- [ ] Dashboard sampling integration

### Phase 3 — Frontend
- [ ] SAFE MODE диаграмма потока governor→worker
- [ ] Hard constraints для bridge

### Phase 4 — QA
- [ ] Test cases для всех сценариев throttle
- [ ] Edge cases (memory pressure, battery, sync storm)

### Phase 5 — Code Review
- [ ] Security, bugs, improvements
- [ ] Production readiness

## API контракт
```
GovernorWorkerBridge
  .observe(metrics) → GovernorDecision
  .applyDecision(decision) → void  // мутирует worker pool config
  .getWorkerConfig() → WorkerConfig
  .emergencyStop() → void
  .resume() → void

WorkerConfig {
  workerCount: number
  chunkBytes: number
  maxInFlightBytes: number
  maxReadConcurrency: number
  pauseIoMs: number
  cacheOnlyLowPriority: boolean
}
```
