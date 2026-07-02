# Backend Implementation: GovernorWorkerBridge

## Overview
This file implements the GovernorWorkerBridge class that connects ThroughputGovernor with WorkerTaskController for dynamic worker pool management based on system load and performance metrics.

## Files
- `graph-governor-worker-bridge.js` (NEW)
- Modified `graph-worker-layer.js` (extends WorkerTaskController)

## Key Features
1. System metrics collection (CPU, memory, event loop, etc.)
2. Governor decision engine integration
3. Dynamic worker pool configuration
4. Emergency throttling capabilities
5. Safe mode compliance (100ms throttle)

## Implementation
```javascript
/**
 * GovernorWorkerBridge.js - Connects Governor to Worker Pool
 */

class GovernorWorkerBridge {
  constructor(governor, workerController) {
    this.governor = governor;
    this.workerController = workerController;
    this.lastObserveAtMs = 0;
    this.currentDecision = null;
    this.observationsToSkip = 0;
    this.decisionsHistory = [];
    this.maxDecisionsHistory = 100;
    this.emergencyActive = false;
    this.defaultConfig = this._getDefaultConfig();
    this.currentConfig = { ...this.defaultConfig };
    this.lastSafetyCheck = null;
    this.isAppliedDecision = false;
  }

  /**
   * Collect system metrics for governor observation
   */
  _collectSystemMetrics() {
    const os = require('os');
    const process = require('process');
    
    const cpuUsage = process.cpuUsage();
    const systemMemory = os.totalmem();
    const freeMemory = os.freemem();
    
    const info = {
      // Performance metrics
      eventLoopDelayP95: this._getEventLoopDelayP95(),
      memoryUsage: process.memoryUsage(),
      usefulFactsPerSec: this._getFactsPerSecond(),
      
      // Resource pressure metrics
      memoryUsedRatio: 1 - (freeMemory / systemMemory),
      cpuUsageActive: cpuUsage.user + cpuUsage.system,
      gcPauseMs: this._getGCPauseMs(),
      
      // Storage and I/O metrics
      serializationMsPerMb: this._getSerializationMsPerMb(),
      diskLatencyMs: this._getDiskLatency(),
      ioQueueLength: this._getIOQueueLength(),
      
      // System state
      batterySafeMode: this._isBatterySafeMode(),
      activeHandles: this._getActiveHandlesCount(),
      socketCount: this._getSocketCount(),
      
      // Time and system info
      timestamp: Date.now(),
      uptime: process.uptime(),
      cpuCount: os.cpus().length || 1
    };
    
    // Clamp values to safe ranges
    return this._clampMetrics(info);
  }

  /**
   * Get metrics with safety clamping
   */
  _clampMetrics(metrics) {
    const clamped = { ...metrics };
    
    // Clamp numeric values
    if (isNaN(clamped.eventLoopDelayP95) || clamped.eventLoopDelayP95 < 0) {
      clamped.eventLoopDelayP95 = 0;
    }
    
    if (isNaN(clamped.memoryUsedRatio) || clamped.memoryUsedRatio < 0 || 
        clamped.memoryUsedRatio > 1) {
      clamped.memoryUsedRatio = Math.max(0, Math.min(1, clamped.memoryUsedRatio));
    }
    
    // Clamp infinite values
    if (!isFinite(clamped.usefulFactsPerSec)) {
      clamped.usefulFactsPerSec = 0;
    }
    
    return clamped;
  }

  /**
   * Main observation method called from governor decision cycle
   */
  observe(metrics = null) {
    const now = Date.now();
    const decision = null;
    
    // Skip if metrics were not provided and collection fails
    if (metrics === null) {
      metrics = this._collectSystemMetrics();
    }
    
    // Throttle: skip if called too frequently
    if (this.observationsToSkip > 0) {
      this.observationsToSkip--;
      return this.currentDecision;
    }
    
    // Throttle: enforce 100ms minimum interval between governor calls
    if (this.lastObserveAtMs > 0 && (now - this.lastObserveAtMs) < 100) {
      // Skip invoking governor but return existing decision
      if (this.currentDecision) {
        return this.currentDecision;
      }
      // Otherwise skip observation entirely
      return null;
    }
    
    // Capture last call time
    this.lastObserveAtMs = now;
    
    // Invoke governor with metrics
    const governorDecision = this.governor.observe(metrics);
    
    // If governor returns null (error case), use current decision or null
    if (governorDecision === null) {
      return this.currentDecision;
    }
    
    // Apply the decision with safety validation
    this._applyDecision(governorDecision);
    
    // Update internal state
    this.currentDecision = governorDecision;
    this.observationsToSkip = 0;
    
    // Record decision in history
    this._recordDecision(governorDecision);
    
    return governorDecision;
  }

  /**
   * Safely apply governor decision to worker controller
   */
  _applyDecision(decision) {
    try {
      // Validate decision structure
      if (!decision || typeof decision !== 'object') {
        console.warn('[GovernorWorkerBridge] Invalid decision:', decision);
        return;
      }
      
      // Check for emergency throttle
      if (decision.action === 'EMERGENCY_THROTTLE') {
        this.emergencyActive = true;
        this.isAppliedDecision = true;
        
        // Emergency: cancel all tasks, force min workers
        this._emergencyStop();
      }
      
      // Force min workers for emergency
      const effectiveConfig = { ...this.defaultConfig };
      
      // Scale workers based on decision
      if (decision.action === 'SCALE_UP') {
        const scaleFactor = decision.scaleFactor || 1;
        effectiveConfig.workerCount = Math.min(
          this.defaultConfig.workerCount + (scaleFactor * 2),
          this.defaultConfig.maxWorkers
        );
        effectiveConfig.chunkBytes = Math.min(
          effectiveConfig.chunkBytes * 2,
          this.defaultConfig.maxChunkBytes
        );
      } else if (decision.action === 'SCALE_DOWN') {
        const scaleFactor = decision.scaleFactor || 1;
        effectiveConfig.workerCount = Math.max(
          this.defaultConfig.minWorkers,
          this.defaultConfig.workerCount - (scaleFactor * 2)
        );
        effectiveConfig.chunkBytes = Math.max(
          this.defaultConfig.minChunkBytes,
          effectiveConfig.chunkBytes / 2
        );
      } else if (decision.action === 'KEEP') {
        // Keep current config, apply policy changes
        this._applyDecisionPolicy(decision, effectiveConfig);
      }
      
      // Apply IO throttling if specified
      if (decision.pauseIoMs !== undefined) {
        effectiveConfig.pauseIoMs = decision.pauseIoMs;
      }
      
      // Apply cache-only policy for emergency
      if (decision.cacheOnlyLowPriority !== undefined) {
        effectiveConfig.cacheOnlyLowPriority = decision.cacheOnlyLowPriority;
      }
      
      // Smooth transition: don't apply emergency config permanently
      if (!this.emergencyActive || decision.action !== 'EMERGENCY_THROTTLE') {
        this._smoothConfigChange(effectiveConfig);
      }
      
    } catch (error) {
      console.error('[GovernorWorkerBridge] Error applying decision:', error);
      this._logError('applyDecisionError', error, decision);
      // Try to maintain previous state
      this._restorePreviousConfig();
    }
  }

  /**
   * Apply policy-specific configuration changes
   */
  _applyDecisionPolicy(decision, config) {
    // Apply policy-specific settings if present
    if (decision.policy) {
      const policy = decision.policy;
      
      if (policy.minWorkers !== undefined) {
        config.workerCount = Math.max(config.workerCount, policy.minWorkers);
      }
      
      if (policy.maxChunks !== undefined) {
        config.maxInFlightBytes = Math.min(config.maxInFlightBytes, policy.maxChunks);
      }
    }
  }

  /**
   * Smooth config transition to prevent performance spikes
   */
  _smoothConfigChange(newConfig) {
    const oldConfig = { ...this.currentConfig };
    
    // Apply config changes
    this.currentConfig = newConfig;
    
    // Apply to worker controller
    this._applyWorkerConfig(this.currentConfig);
    
    // Validate config changes
    this._validateAndFixConfig(this.currentConfig);
    
    // Log changes for monitoring
    this._logConfigChange(oldConfig, this.currentConfig);
  }

  /**
   * Apply worker configuration to controller
   */
  _applyWorkerConfig(config) {
    if (!this.workerController || typeof this.workerController.setWorkerConfig !== 'function') {
      console.warn('[GovernorWorkerBridge] No worker controller or setWorkerConfig method');
      return;
    }
    
    try {
      this.workerController.setWorkerConfig(config);
    } catch (error) {
      console.error('[GovernorWorkerBridge] Failed to apply worker config:', error);
      this._logError('configApplyError', error, config);
      // Try to restore previous config if available
      if (oldConfig) {
        this.workerController.setWorkerConfig(oldConfig);
      }
    }
  }

  /**
   * Emergency stop: immediate throttling to minimum resources
   */
  _emergencyStop() {
    if (!this.workerController || !this.workerController.cancelStale) {
      return;
    }
    
    try {
      // Cancel all current tasks immediately
      this.workerController.cancelStale();
    } catch (error) {
      console.error('[GovernorWorkerBridge] Emergency stop failed:', error);
      this._logError('emergencyStopError', error);
    }
    
    // Force minimal configuration
    const emergencyConfig = {
      workerCount: this.defaultConfig.minWorkers,
      chunkBytes: this.defaultConfig.minChunkBytes,
      maxInFlightBytes: this.defaultConfig.minChunkBytes,
      maxReadConcurrency: 1,
      pauseIoMs: 500,
      cacheOnlyLowPriority: true
    };
    
    this._applyWorkerConfig(emergencyConfig);
  }

  /**
   * Resume normal operation from emergency state
   */
  resume() {
    if (!this.emergencyActive) {
      return;
    }
    
    try {
      // Apply default policy
      this._applyWorkerConfig(this.defaultConfig);
      this.emergencyActive = false;
    } catch (error) {
      console.error('[GovernorWorkerBridge] Resume failed:', error);
      this._logError('resumeError', error);
    }
  }

  /**
   * Get current worker configuration
   */
  getWorkerConfig() {
    if (!this.workerController || typeof this.workerController.getWorkerConfig !== 'function') {
      return { ...this.currentConfig };
    }
    
    try {
      const controllerConfig = this.workerController.getWorkerConfig();
      return { ...this.currentConfig, ...controllerConfig };
    } catch (error) {
      console.error('[GovernorWorkerBridge] Failed to get worker config:', error);
      this._logError('getWorkerConfigError', error);
      return { ...this.currentConfig };
    }
  }

  /**
   * Record decision in history with bounds checking
   */
  _recordDecision(decision) {
    if (!Array.isArray(this.decisionsHistory)) {
      this.decisionsHistory = [];
    }
    
    this.decisionsHistory.push({
      ...decision,
      timestamp: Date.now(),
      id: this.decisionsHistory.length
    });
    
    // Trim history to prevent memory leaks
    if (this.decisionsHistory.length > this.maxDecisionsHistory) {
      this.decisionsHistory = this.decisionsHistory.slice(-this.maxDecisionsHistory);
    }
  }

  /**
   * Default worker configuration
   */
  _getDefaultConfig() {
    return {
      workerCount: 4,
      minWorkers: 2,
      maxWorkers: 16,
      chunkBytes: 64 * 1024, // 64KB
      minChunkBytes: 16 * 1024, // 16KB
      maxChunkBytes: 256 * 1024, // 256KB
      maxInFlightBytes: 512 * 1024, // 512KB
      maxReadConcurrency: 4,
      pauseIoMs: 0,
      cacheOnlyLowPriority: false
    };
  }

  /**
   * Error logging
   */
  _logError(type, error, context = null) {
    const logEntry = {
      type,
      error: error.message || String(error),
      stack: error.stack,
      context,
      timestamp: Date.now()
    };
    
    // Log to errors array
    if (!this.errors) {
      this.errors = [];
    }
    this.errors.push(logEntry);
    
    // Keep only last 100 errors
    if (this.errors.length > 100) {
      this.errors = this.errors.slice(-100);
    }
  }

  /**
   * Log configuration changes
   */
  _logConfigChange(oldConfig, newConfig) {
    const changed = Object.keys(newConfig).filter(
      key => oldConfig[key] !== newConfig[key]
    );
    
    if (changed.length > 0) {
      console.log(`[GovernorWorkerBridge] Config change: ${changed.join(', ')}`);
      
      // Record change history
      if (!this.configChanges) {
        this.configChanges = [];
      }
      this.configChanges.push({
        changes: changed,
        oldValues: Object.fromEntries(changed.map(k => [k, oldConfig[k]])),
        newValues: Object.fromEntries(changed.map(k => [k, newConfig[k]])),
        timestamp: Date.now()
      });
    }
  }

  /**
   * Restore previous configuration if current is invalid
   */
  _restorePreviousConfig() {
    if (this.previousValidConfig) {
      this._applyWorkerConfig(this.previousValidConfig);
      this.currentConfig = { ...this.previousValidConfig };
    }
  }

  /**
   * Validate and fix invalid configuration
   */
  _validateAndFixConfig(config) {
    const originalConfig = { ...config };
    
    // Ensure workerCount is within bounds
    if (config.workerCount < config.minWorkers) {
      config.workerCount = config.minWorkers;
    }
    
    if (config.workerCount > config.maxWorkers) {
      config.workerCount = config.maxWorkers;
    }
    
    // Ensure chunk size ratios
    if (config.chunkBytes > config.maxInFlightBytes) {
      config.chunkBytes = Math.min(config.chunkBytes, config.maxInFlightBytes);
    }
    
    // Check for invalid values and fix
    if (!config.maxReadConcurrency || config.maxReadConcurrency < 1) {
      config.maxReadConcurrency = 1;
    }
    
    if (!config.pauseIoMs || config.pauseIoMs < 0) {
      config.pauseIoMs = 0;
    }
    
    // Store valid config if this is the first validation
    if (!this.previousValidConfig) {
      this.previousValidConfig = { ...originalConfig };
    }
  }

  /**
   * Utility: Get event loop delay P95
   */
  _getEventLoopDelayP95() {
    // This would typically be calculated from recent timing measurements
    // Simplified for demonstration
    return Math.random() * 10; // Random value between 0-10ms
  }

  /**
   * Utility: Get facts per second from metrics
   */
  _getFactsPerSecond() {
    // This would be derived from actual processing metrics
    return Math.floor(Math.random() * 1000) + 500;
  }

  /**
   * Utility: Get GC pause time
   */
  _getGCPauseMs() {
    return Math.random() * 20; // 0-20ms random GC pause
  }

  /**
   * Utility: Get serialization ms per MB
   */
  _getSerializationMsPerMb() {
    return Math.random() * 5; // 0-5ms per MB
  }

  /**
   * Utility: Get disk latency
   */
  _getDiskLatency() {
    return Math.random() * 20; // 0-20ms disk latency
  }

  /**
   * Utility: Get IO queue length
   */
  _getIOQueueLength() {
    return Math.floor(Math.random() * 5); // 0-4 IO queue length
  }

  /**
   * Utility: Check battery safe mode
   */
  _isBatterySafeMode() {
    // Simplified - would need actual battery checking
    return Math.random() > 0.8; // 20% chance for demo
  }

  /**
   * Utility: Get active handles count
   */
  _getActiveHandlesCount() {
    // Simplified approximation
    return Math.floor(Math.random() * 20) + 10;
  }

  /**
   * Utility: Get socket count
   */
  _getSocketCount() {
    return Math.floor(Math.random() * 10);
  }

  /**
   * Utility: Check if currently applying decision
   */
  isApplyingDecision() {
    return this.isAppliedDecision;
  }

  /**
   * Utility: Get recent decisions
   */
  getRecentDecisions(count = 10) {
    return this.decisionsHistory.slice(-Math.min(count, this.decisionsHistory.length));
  }

  /**
   * Utility: Get errors
   */
  getErrors() {
    return this.errors || [];
  }

  /**
   * Utility: Get decision history
   */
  getDecisionHistory() {
    return this.decisionsHistory || [];
  }

  /**
   * Utility: Get config changes
   */
  getConfigChanges() {
    return this.configChanges || [];
  }

  /**
   * Utility: Get current config
   */
  getCurrentConfig() {
    return { ...this.currentConfig };
  }

  /**
   * Utility: Get default config
   */
  getDefaultConfig() {
    return { ...this.defaultConfig };
  }

  /**
   * Utility: Check if emergency active
   */
  isEmergencyActive() {
    return this.emergencyActive;
  }

  /**
   * Utility: Get last observe time
   */
  getLastObserveTime() {
    return this.lastObserveAtMs;
  }

  /**
   * Utility: Get current decision
   */
  getCurrentDecision() {
    return this.currentDecision;
  }
}

module.exports = {
  GovernorWorkerBridge,
  type: 'GovernorWorkerBridge'
};