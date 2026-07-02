# Architectural Decisions

## ADR-1: Bridge pattern вместо прямого импорта
**Контекст:** ThroughputGovernor не должен знать о WorkerTaskController.
**Решение:** GovernorWorkerBridge — адаптер, который вызывает governor и применяет решение.
**Альтернатива:** Прямой вызов governor из worker — отклонено (SRP violation).

## ADR-2: ThroughputGovernor остаётся pure function по decision-making
**Контекст:** Governor уже pure (observe → decision).
**Решение:** Не добавляем мутацию в governor. Bridge применяет решение.
**Альтернатива:** Сделать governor stateful с apply — отклонено (чистота и тесты).

## ADR-3: WorkerTaskController получает config через setConfig()
**Контекст:** У WorkerTaskController нет динамической конфигурации.
**Решение:** Добавляем setWorkerConfig(config) и геттер getWorkerConfig().
**Альтернатива:** Параметр при каждом scheduleTask — отклонено (избыточно).

## ADR-4: Metrics collection внутри Bridge
**Контекст:** Метрики CPU, event loop, memory нужны для governor.
**Решение:** Bridge собирает метрики через performance.now(), process.cpuUsage(), os.freemem().
**Альтернатива:** Отдельный MetricsCollector — отклонено (overengineering для v1).

## ADR-5: Emergency throttle форсирует отмену всех задач
**Контекст:** При emergency throttle надо быстро снизить нагрузку.
**Решение:** Bridge вызывает cancelStale() на WorkerTaskController при emergency.
**Альтернатива:** Ждать завершения задач — отклонено (слишком медленно).

## ADR-6: Governor вызывается не чаще 1/100ms
**Контекст:** Слишком частые вызовы governor создают лишнюю нагрузку.
**Решение:** Throttle-интервал 100ms через setTimeout / lastCall timestamp.
**Альтернатива:** requestAnimationFrame — отклонено (не в рендер-лупе).
