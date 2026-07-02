# SAFE MODE — Governor → Worker Bridge

## Data Flow Diagram

```
System Metrics
  ├── eventLoopDelay
  ├── memoryUsage (process + os)
  ├── usefulFactsPerSec
  ├── gcPauseMs
  └── serializationMsPerMb
       │
       ▼
┌──────────────────────┐
│  GovernorWorkerBridge │
│  .observe(sample)     │
└──────────┬───────────┘
           │ 100ms min interval
           ▼
┌──────────────────────┐
│  ThroughputGovernor  │
│  .observe()          │
│  → GovernorDecision  │
└──────────┬───────────┘
           │ actions + nextPolicy
           ▼
┌──────────────────────┐
│  GovernorWorkerBridge │
│  .#applyDecision()    │
└──────────┬───────────┘
           │
      ┌────┴────┐
      ▼         ▼
┌─────────┐ ┌──────────────┐
│ Worker  │ │ WorkerConfig │
│Controller│ │ {           │
│ .cancel  │ │  workerCount│
│ .setConf │ │  chunkBytes │
│ .getConf │ │  maxInFlight│
└─────────┘ │  ...        │
            └──────────────┘
```

## 10 Hard Constraints

1. **Governor вызывается не чаще 1/100ms** — throttle через lastObserveAtMs
2. **Bridge не хранит решения** — всё через ThroughputGovernor (source of truth)
3. **Emergency throttle форсирует cancelStale** — немедленная остановка задач
4. **applyDecision не вызывает observe** — нет feedback loop
5. **Dashboard sampling не влияет на решения** — read-only
6. **workerConfig всегда freeze** — иммутабельные конфиги
7. **Bridge не переопределяет governor** — всегда через governor.observe()
8. **Metrics collection не блокирует** — синхронные os/process вызовы
9. **resume() сбрасывает в DEFAULT_POLICY** — гарантированный выход из emergency
10. **decisions history ограничен 100** — нет утечки памяти
