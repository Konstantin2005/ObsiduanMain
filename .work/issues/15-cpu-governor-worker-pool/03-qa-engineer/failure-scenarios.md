# Failure Scenarios — Governor → Worker Bridge

## FS-1: Governor observe() throws exception

**Scenario:**
- Governor.observe() throws due to internal error
- This could happen from: evaluateSla(), createResourceProfile(), or computeThroughputGain()
- The exception propagates through the bridge

**Expected Behavior:**
- Bridge should catch the exception and prevent system crash
- Should return currentDecision if available
- Should log the error for debugging
- Should maintain previous configuration state
- Should not affect worker pool configuration

**Recovery Strategy:**
1. Try-catch wrapper around governor.observe() call
2. Log error with context in _logError()
3. Return currentDecision if no new decision required
4. Keep previous config to maintain system stability
5. Consider increment error counter for monitoring

**Test Case:**
- Input: governor that throws on .observe() call
- Expected: bridge returns currentDecision, logs error, config unchanged

## FS-2: Invalid workerConfig provided to setWorkerConfig()

**Scenario:**
- setWorkerConfig() called with invalid values (negative, NaN, Infinity)
- WorkerTaskController.setWorkerConfig() has its own clamping but may still have edge cases
- Configuration could exceed system limits

**Expected Behavior:**
- Bridge should clamp invalid values to safe ranges
- Should prevent applying obviously invalid configuration
- Should fallback to previous valid configuration on critical errors
- Should log configuration issues for monitoring

**Recovery Strategy:**
1. Validate all configuration values before applying
2. Use _validateAndFixConfig() to correct problematic values
3. Fallback to previous valid config if current is invalid
4. Maintain minimum viable operation even with bad config

**Test Case:**
- Input: workerConfig with negative workerCount, zero maxWorkers
- Expected: values clamped to safe minimum, operation continues

## FS-3: Memory allocation failure during metrics collection

**Scenario:**
- _collectSystemMetrics() fails due to memory pressure
- os.cpus(), process.memoryUsage(), or os.freemem() throws
- Could be OOM (out of memory) condition

**Expected Behavior:**
- Should not crash the entire system
- Should fallback to cached previous metrics
- Should reduce governor observation frequency
- Should possibly trigger emergency mode if memory is critically low

**Recovery Strategy:**
1. Graceful error handling in _collectSystemMetrics()
2. Use previousSample as fallback metrics
3. Increase throttle interval when metrics collection fails
4. Consider triggering emergency mode if memory is critically low

**Test Case:**
- Input: os.cpus() throws, process.memoryUsage() throws
- Expected: uses cached metrics, returns to normal when collection resumes

## FS-4: Concurrent observe() calls from multiple threads

**Scenario:**
- Multiple threads call observe() simultaneously
- Could happen in multi-threaded environments or with async callbacks
- Race conditions in internal state updates

**Expected Behavior:**
- Should serialize all observe() calls
- Should not corrupt internal state (decisionsHistory, currentConfig)
- Should handle all calls eventually
- Should maintain consistent system state

**Recovery Strategy:**
1. Use lastObserveAtMs to throttle and serialize calls
2. Ensure all internal state updates are atomic
3. Use synchronous error handling that doesn't block
4. Keep operations fast and non-blocking

**Test Case:**
- Input: 10 concurrent observe() calls in same millisecond
- Expected: calls serialized by 100ms intervals, consistent state

## FS-5: WorkerTaskController is undefined (dependency missing)

**Scenario:**
- workerController parameter is null/undefined
- Could happen during initialization before controller is created
- Configuration import fails

**Expected Behavior:**
- Bridge should continue operating without worker controller
- Should still collect metrics and make decisions
- Should log warning about missing dependency
- Should buffer decisions for when controller becomes available

**Recovery Strategy:**
1. Check for null workerController before using it
2. Buffer decisions when controller unavailable
3. Apply all buffered decisions when controller becomes available
4. Log warning to help with debugging

**Test Case:**
- Input: workerController = null during observe() calls
- Expected: decisions returned but not applied, warning logged

## FS-6: Emergency stop without resume capability

**Scenario:**
- emergencyStop() called but resume() never called
- Emergency mode persists indefinitely
- Workers stuck at minimum configuration
- System cannot recover even when conditions improve

**Expected Behavior:**
- Should have timeout mechanism for automatic emergency exit
- Should have heartbeat monitoring for emergency state
- Should allow manual configuration override
- Should warn about long-running emergency mode

**Recovery Strategy:**
1. Add emergency timeout (e.g., 30 seconds max emergency)
2. Monitor emergency state duration
3. Allow manual override of emergency mode
4. Log warnings about prolonged emergency mode

**Test Case:**
- Input: emergencyStop() called, conditions improve
- Expected: should exit emergency mode after timeout or manual resume

## FS-7: Error in configuration application

**Scenario:**
- _applyWorkerConfig() fails to apply configuration
- WorkerTaskController.setWorkerConfig() throws
- Could be due to worker pool not initialized

**Expected Behavior:**
- Should not leave system in inconsistent state
- Should attempt to restore previous configuration
- Should maintain emergency state if applicable
- Should log error with details for debugging

**Recovery Strategy:**
1. Try-catch wrapper around configuration application
2. Store previous valid configuration
3. Restore previous config on application failure
4. Keep emergency state active on critical errors

**Test Case:**
- Input: setWorkerConfig() throws exception
- Expected: previous config restored, error logged, emergency mode active

## FS-8: Metrics collection periodic failure

**Scenario:**
- _collectSystemMetrics() intermittently fails
- Some metrics succeed, others fail
- System degrades over time

**Expected Behavior:**
- Should continue operating with partial metrics
- Should degrade performance gracefully
- Should alert on persistent metrics issues
- Should favor system stability over complete accuracy

**Recovery Strategy:**
1. Robust error handling in _collectSystemMetrics()
2. Use complete metrics when available
3. Provide warnings about partial metric data
4. Allow system to continue with degraded capabilities

**Test Case:**
- Input: 50% of metrics collection fails
- Expected: system continues with available metrics, performance degraded