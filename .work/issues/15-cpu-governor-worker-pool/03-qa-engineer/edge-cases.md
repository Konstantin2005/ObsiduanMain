# Edge Cases — Governor → Worker Bridge

## EC-1: Zero metrics
- Input: metrics.sample = {}
- Impact: missing all measurements
- Behavior: Should use default policies from existing data
- Solution: Graceful fallback to existing policy, default config
- Test: Should not crash, should maintain previous state

## EC-2: Negative metrics
- Input: eventLoopDelayP95=-1, memoryUsedRatio=-0.5
- Impact: Invalid negative measurements
- Behavior: Should clamp to zero, prevent negative impacts
- Solution: All negative values clamped to zero using Math.max(0, value)
- Test: All metric values should be >= 0 after processing

## EC-3: No worker controller
- Input: bridge.workerController = null
- Impact: Cannot apply decisions to workers
- Behavior: Should continue observing and returning decisions without application
- Solution: Guard conditions in _applyDecision() prevent null reference
- Test: Should not crash, should log warning, maintain emergency state

## EC-4: NaN metrics
- Input: usefulFactsPerSec = NaN, eventLoopDelayP95 = NaN
- Impact: Mathematical operations fail
- Behavior: Should detect NaN, treat as invalid input
- Solution: Number.isFinite() checks with fallback to defaults
- Test: All NaN metrics should be clamped to valid numbers (0)

## EC-5: Infinity metrics
- Input: usefulFactsPerSec = Infinity, memoryUsedRatio = 1000
- Impact: Overflow risks, unrealistic performance
- Behavior: Should be clamped to reasonable maximum values
- Solution: Math.min(value, MAX_REASONABLE) clamps values
- Test: All infinite/oversized values should be reasonable

## EC-6: Rapid emergency toggle
- Input: emergencyStop() immediately followed by resume() within 1ms
- Impact: Potential state corruption, inconsistent config
- Behavior: Should handle concurrent state changes atomically
- Solution: Check emergencyActive flag before state changes
- Test: Should return to clean state, no contradictions

## EC-7: Worker controller cancel throws
- Input: workerController.cancelStale() throws exception
- Impact: Emergency stop fails, worker state inconsistent
- Behavior: Should catch exception, log error, attempt to recover
- Solution: try-catch in _emergencyStop() with state restoration
- Test: Should not propagate exception, should maintain emergency state

## EC-8: os.cpus() returns empty
- Input: os.cpus() returns undefined or empty array
- Impact: Wrong thread count defaults, incorrect scaling
- Behavior: Should fallback to 1 thread when detection fails
- Solution: Math.max(1, os.cpus().length || 1) ensures minimum
- Test: Should default to 1 core when system detection fails

## EC-9: Extreme memory pressure
- Input: memoryUsedRatio = 0.99+, freeMemory = 0
- Impact: System critically overloaded
- Behavior: Should enter emergency mode immediately
- Solution: Check threshold > 0.95 triggers emergency regardless of other metrics
- Test: Should immediately throttle to minimum workers

## EC-10: Concurrent emergency from multiple sources
- Input: emergency flag from metrics AND manual emergencyStop()
- Impact: Race condition in emergency state
- Behavior: Should handle multiple emergency requests consistently
- Solution: Single emergencyActive flag prevents conflicts
- Test: Should enter emergency mode once, consistent behavior

## EC-11: Configuration validation errors
- Input: invalid workerConfig (chunkBytes > maxInFlightBytes)
- Impact: Invalid configuration applied
- Behavior: Should auto-fix or fallback to safe defaults
- Solution: ValidateAndFixConfig() corrects problematic values
- Test: Invalid config should be corrected to valid values

## EC-12: Metrics collection failure
- Input: os.cpus() throws, process.memoryUsage() throws
- Impact: Cannot collect system metrics
- Behavior: Should fallback to cached metrics or defaults
- Solution: Graceful error handling with previousSample fallback
- Test: Should not crash when metrics collection fails

## EC-13: Decision history memory leak
- Input: observe() called continuously with new decisions
- Impact: Memory usage grows indefinitely
- Behavior: Should bound history size to prevent memory issues
- Solution: Trim decisions to last 100 entries
- Test: History should be bounded, no memory leak

## EC-14: Emergency state persistence
- Input: emergency mode entered, no metrics improvement
- Impact: Workers stuck in emergency mode permanently
- Behavior: Should have automatic exit mechanism
- Solution: resume() called when metrics are clear for extended period
- Test: Should automatically exit emergency when conditions improve

## EC-15: Configuration transition race
- Input: applyDecision() called while transitioning between configs
- Impact: Mid-transition configuration corruption
- Behavior: Should ensure atomic config changes
- Solution: Smooth state changes, rollback on failure
- Test: No corruption during config transitions