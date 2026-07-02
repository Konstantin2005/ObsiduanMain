# Test Cases — Governor → Worker Bridge

## TC-1: Normal operation — no throttling
- Input: eventLoopDelayP95=8, memoryUsedRatio=0.4, usefulFactsPerSec=1000
- Expected: GovernorDecision with KEEP action, workerCount unchanged

## TC-2: Frame budget exceeded → emergency throttle
- Input: eventLoopDelayP95=40, memoryUsedRatio=0.5
- Expected: EMERGENCY_THROTTLE action, cancelStale called, workerCount halved

## TC-3: Memory pressure → emergency throttle
- Input: memoryUsedRatio=0.9, eventLoopDelayP95=12
- Expected: EMERGENCY_THROTTLE, pauseIoMs >= 500, cacheOnlyLowPriority=true

## TC-4: Low throughput gain → scale down
- Input: usefulFactsPerSec=100, previousUsefulFactsPerSec=100
- Expected: SCALE_DOWN, workerCount reduced by 1

## TC-5: All clear → scale up
- Input: eventLoopDelayP95=8, memoryUsedRatio=0.3, usefulFactsPerSec=1000, previousUsefulFactsPerSec=800
- Expected: SCALE_UP, workerCount increased by 1 (until maxWorkers)

## TC-6: Governor throttle interval (100ms minimum)
- Steps: call observe() twice in same ms
- Expected: second call returns currentDecision without invoking governor

## TC-7: Emergency stop → resume
- Steps: call emergencyStop(), verify workerConfig forced to min, call resume()
- Expected: After resume(), workerConfig returns to DEFAULT_POLICY

## TC-8: Dashboard sample rate limiting
- Steps: observe() with maxHz=2, verify dashboardSample updated at most 2/sec
- Expected: shouldSampleDashboard returns false for intervening calls

## TC-9: WorkerConfig immutability
- Steps: call setWorkerConfig({ workerCount: 4 }), then mutate returned config
- Expected: Original config unchanged (frozen)

## TC-10: Decision history bounded
- Steps: call observe() 150 times
- Expected: decisions.length <= 100

## Edge Cases

| # | Scenario | Input | Expected |
|---|----------|-------|----------|
| EC-1 | Zero metrics | sample={} | Default policy, no crash |
| EC-2 | Negative metrics | eventLoopDelayP95=-1 | Clamped to 0 |
| EC-3 | No worker controller | bridge.workerController=null | observe returns decision, no crash |
| EC-4 | NaN metrics | usefulFactsPerSec=NaN | Clamped to 0 |
| EC-5 | Infinity throughput | usefulFactsPerSec=Infinity | Clamped to reasonable value |
| EC-6 | Rapid emergency toggle | emergencyStop() then resume() in 1ms | Clean state |
| EC-7 | WorkerController cancel throws | cancelStale throws | Bridge catches, no propagate |
| EC-8 | os.cpus() returns empty | System mock | Defaults to 1 |

## Failure Scenarios

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| FS-1 | governor.observe() throws | Bridge does not crash, returns null |
| FS-2 | setWorkerConfig() with invalid config | Clamped to safe defaults |
| FS-3 | Memory allocation failure in metrics | Graceful fallback to previous metrics |
| FS-4 | Concurrent observe() calls | Serialized by 100ms interval |

## Integration Scenarios

| # | Scenario | Input | Expected |
|---|----------|-------|----------|
| IS-1 | Metrics with emergency flag | sample.emergency=true | Immediate emergency throttle |
| IS-2 | Battery safe mode | sample.batterySafeMode=true | minWorkers enforced, cache-only |
| IS-3 | syncStorm detected | sample.syncStorm=true | EMERGENCY_THROTTLE, all actions |
| IS-4 | High GC pressure | sample.gcPauseMs=100 | Emergency throttle with 500ms pauseIoMs |
| IS-5 | Disk latency spike | sample.diskLatencyMs=100 | Emergency throttle, IO pause |
| IS-6 | Low throughput gain sustained | gain=0.05 for 3 calls | Progressive scale down |
| IS-7 | Rapid scale up then down | alternating SCALE_UP/SCALE_DOWN | No oscillation, smooth transitions |
| IS-8 | Extreme memory pressure | memoryUsedRatio=0.99 | Immediate cancellation, min config |

## Performance Tests

| # | Test | Metric | Requirement |
|---|------|--------|-------------|
| PT-1 | observe() call overhead | execution time | < 5ms per call |
| PT-2 | emergencyStop latency | time to first cancellation | < 10ms |
| PT-3 | config application | applyDecision time | < 2ms |
| PT-4 | history memory | decisions[100] size | < 50KB |
| PT-5 | error recovery | after error state | returns to normal within 100ms |