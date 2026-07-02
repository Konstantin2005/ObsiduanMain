# Validation Rules — Governor → Worker Bridge

## Input Validation

### Metric Validation Rules
- `eventLoopDelayP95`: Number, >= 0, finite (`clampNumber(value, 0, 1000)`)
- `memoryUsedRatio`: Number, >= 0, <= 1 (clamped: `Math.max(0, Math.min(1, value))`)
- `usefulFactsPerSec`: Number, finite (clamped: `!isFinite(value) ? 0 : value`)
- `diskLatencyMs`: Number, >= 0, finite
- `gcPauseMs`: Number, >= 0, finite
- `pauseIoMs`: Number, >= 0, finite (used for emergency throttling)

### WorkerConfig Validation Rules
- `workerCount`: Integer, >= 1, <= maxWorkers (default: 1-16)
- `chunkBytes`: Integer, >= 64KB (65536), <= maxChunkBytes (default: 16KB-256KB)
- `maxInFlightBytes`: Integer, >= chunkBytes, finite
- `maxReadConcurrency`: Integer, >= 1, <= workerCount
- `pauseIoMs`: Integer, >= 0, finite
- `cacheOnlyLowPriority`: Boolean

### Configuration Bounds
```javascript
const CONFIG_BOUNDS = {
  workerCount: { min: 1, max: 16 },           // Based on DEFAULT_POLICY
  chunkBytes: { min: 64 * 1024, max: 256 * 1024 }, // 64KB - 256KB
  maxInFlightBytes: { min: 65536, max: 1024 * 1024 * 16 }, // 64KB - 16MB
  maxReadConcurrency: { min: 1, max: 16 },   // <= workerCount
  pauseIoMs: { min: 0, max: 86400000 },      // 0ms - 24h
  cacheOnlyLowPriority: boolean               // 0 or 1
};
```

## State Machine Validation

### Valid Transitions
```
IDLE → OBSERVING → DECIDING → APPLYING → IDLE
                    ↓
              EMERGENCY → CANCELING → MIN_CONFIG → RECOVERING → IDLE
```

### State Validation Rules
- `OBSERVING`: Must have metrics collected, lastObserveAtMs valid
- `DECIDING`: Must have valid governorDecision, emergency flag allowed
- `APPLYING`: Must have targetConfig, workerController available
- `EMERGENCY`: Must have emergencyActive=true, all actions blocked
- `CANCELING`: Must have cancelStale in progress
- `MIN_CONFIG`: Must have minimal workers applied
- `RECOVERING`: Must be exiting emergency mode, metrics improving

### State Constraints
- Cannot transition to EMERGENCY without reason (must be emergency condition)
- Cannot transition from EMERGENCY to IDLE without recovery
- Cannot be both in EMERGENCY and APPLYING simultaneously
- Canceling tasks should not be resumed until EMERGENCY cleared

## Loop Prevention Rules

### Governor Decision Loop
```
observe() → decision → applyDecision() → should NOT call observe()
```

**Rules:**
1. `observe()` never calls `applyDecision()` directly
2. Bridge calls `applyDecision()` AFTER decision is made
3. `applyDecision()` never calls `observe()`
4. `emergencyStop()` does not trigger `observe()`
5. `resume()` does not trigger `observe()`
6. WorkerConfig changes do not trigger feedback loops

### Dashboard Sampling Loop
```
dashboardSample → decision → applyDecision() → dashboardSample
```

**Rules:**
1. Dashboard sampling never feeds back into governor
2. All dashboard samples are read-only
3. Decision changes are independent of dashboard sampling
4. Emergency mode blocks dashboard sampling
5. Sampling rate limited to prevent feedback loops

### Configuration Feedback Loop
```
workerConfig → decision → applyDecision() → workerConfig
```

**Rules:**
1. WorkerConfig is source of truth for worker pool state
2. WorkerConfig changes do not automatically trigger new observations
3. Configuration changes are explicit decisions from governor
4. Historical configuration does not influence future decisions
5. Configuration is immutable (frozen objects)

## Error State Validation

### Valid Error States
- `error.state = ERROR_COLLLECTION_FAILED`
- `error.state = ERROR_CONFIG_APPLICATION_FAILED`
- `error.state = ERROR_EMERGENCY_START_FAILED`
- `error.state = ERROR_EMERGENCY_RESUME_FAILED`

### Error State Transitions
```
ERROR_COLLLECTION_FAILED → RETRYING
ERROR_CONFIG_APPLICATION_FAILED → RESTORING_PREVIOUS
ERROR_EMERGENCY_START_FAILED → EMERGENCY_ACTIVE_BUT_BACKUP_MODE
ERROR_EMERGENCY_RESUME_FAILED → EMERGENCY_MODE
```

### Error Recovery Rules
- Must have maximum 3 retry attempts per error
- Must fall back to previous valid state on persistent errors
- Must enter emergency mode when critical errors occur
- Must log all errors for post-mortem analysis

## Performance Validation Rules

### Metrics Valid Range
- `eventLoopDelayP95`: 0-1000ms (extreme: system overloaded)
- `memoryUsedRatio`: 0-1.0 (1.0 = 100% used)
- `usefulFactsPerSec`: 0-1000000 (based on system capacity)
- `gcPauseMs`: 0-1000 (1000 = 1 second pause - emergency level)
- `diskLatencyMs`: 0-5000 (5000 = 5 seconds - critical)

### Configuration Performance Bounds
- `maxInFlightBytes` must not exceed available memory
- `pauseIoMs` should be reasonable (max 24 hours for emergency)
- `workerCount` should not exceed logical cores * 2
- `chunkBytes` should fit in memory page size

### Rate Limiting Rules
- Governor calls: max 1 per 100ms (throttle interval)
- Dashboard sampling: max configurable Hz (default: 2Hz)
- Metrics collection: synchronous, non-blocking, < 1ms
- WorkerConfig application: immediate, synchronous

## Testing Strategy Validation

### Unit Test Rules
```
Unit: GovernorWorkerBridge.observe() with mock governor + mock worker
Unit: WorkerTaskController.setWorkerConfig() with various inputs
Integration: ThroughputGovernor + GovernorWorkerBridge
E2E: Full system with os/process metrics
```

**Test Requirements:**
- All unit tests must be isolated
- Integration tests must test real components
- E2E tests require system metrics
- Mock objects must simulate all edge cases
- Tests must cover error scenarios

### Test Coverage Requirements
- Boundary conditions: < 0, = 0, > max, NaN, Infinity
- Concurrent operations: multiple threads, race conditions
- Error conditions: file system, network, memory allocation
- State transitions: all valid and invalid state changes
- Performance requirements: response times, throughput limits

## Production Readiness Validation

### Critical Requirements
1. **No memory leaks**: decisionsHistory bounded, errors bounded
2. **No blocking operations**: all functions return quickly
3. **Graceful degradation**: continue with partial functionality
4. **Error recovery**: automatic recovery from transient errors
5. **Monitoring**: error logging, metrics exposure
6. **Security**: no external dependencies, no network calls
7. **Determinism**: predictable behavior with same inputs
8. **Atomicity**: state changes are atomic and consistent

### Reliability Validation
- Must pass 100% of test cases
- Must handle all edge cases without crashing
- Must recover from all failure scenarios
- Must maintain system stability under stress
- Must not violate safety constraints
- Must provide audit trail for all decisions

### Monitoring Validation
- Error logging for all exceptions
- Metrics exposure for monitoring systems
- Decision history for audit and debugging
- Performance metrics for capacity planning
- Configuration changes for visibility