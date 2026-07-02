// Frontend: Governor Panel — Issue #26
// UI for monitoring and controlling the performance governor

import React, { useState, useEffect, useCallback } from 'react';
import { ResourceUsage, ThrottleLevel, QueueStats } from '../backend/governor-core';

interface GovernorState {
  usage: ResourceUsage;
  throttle: ThrottleLevel;
  config: { maxCPU: number; maxMemory: number; adaptive: boolean };
  queue: QueueStats;
}

export const GovernorPanel: React.FC = () => {
  const [state, setState] = useState<GovernorState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchState = async () => {
      try {
        const response = await fetch('/api/governor/status');
        if (!response.ok) throw new Error('Failed to fetch governor state');
        const data = await response.json();
        setState(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setIsLoading(false);
      }
    };

    fetchState();
    const interval = setInterval(fetchState, 2000);
    return () => clearInterval(interval);
  }, []);

  const getThrottleColor = (throttle: ThrottleLevel): string => {
    const colors = {
      none: '#28a745',
      light: '#ffc107',
      medium: '#fd7e14',
      heavy: '#dc3545',
      critical: '#dc3545',
    };
    return colors[throttle] || '#666';
  };

  if (isLoading) {
    return <div className="governor-panel loading">Loading governor data...</div>;
  }

  if (error) {
    return (
      <div className="governor-panel error">
        <div className="error-header">
          <span className="error-icon">⚠</span>
          <span>Error: {error}</span>
        </div>
        <button onClick={() => window.location.reload()}>Retry</button>
      </div>
    );
  }

  return (
    <div className="governor-panel">
      <div className="panel-header">
        <h2>Performance Governor</h2>
        <span
          className="throttle-badge"
          style={{ backgroundColor: getThrottleColor(state?.throttle || 'none') }}
        >
          {state?.throttle || 'none'}
        </span>
      </div>

      <div className="resource-section">
        <h3>Resource Usage</h3>
        <div className="resource-grid">
          <div className="resource-card">
            <label>CPU</label>
            <div className="progress-bar">
              <div
                className="progress-fill"
                style={{ width: `${Math.min((state?.usage.cpuPercent || 0) / (state?.config.maxCPU || 100) * 100, 100)}%` }}
              />
            </div>
            <span className="resource-value">{(state?.usage.cpuPercent || 0).toFixed(1)}%</span>
          </div>

          <div className="resource-card">
            <label>Memory</label>
            <div className="progress-bar">
              <div
                className="progress-fill"
                style={{ width: `${Math.min((state?.usage.memoryMB || 0) / (state?.config.maxMemory || 1000) * 100, 100)}%` }}
              />
            </div>
            <span className="resource-value">{state?.usage.memoryMB || 0} MB</span>
          </div>

          <div className="resource-card">
            <label>Throughput</label>
            <span className="resource-value large">{(state?.usage.throughput || 0).toFixed(0)} ops/s</span>
          </div>
        </div>
      </div>

      <div className="queue-section">
        <h3>Work Queue</h3>
        <div className="queue-stats">
          <div className="queue-item high">
            <label>High Priority</label>
            <span>{state?.queue.high || 0}</span>
          </div>
          <div className="queue-item medium">
            <label>Medium Priority</label>
            <span>{state?.queue.medium || 0}</span>
          </div>
          <div className="queue-item low">
            <label>Low Priority</label>
            <span>{state?.queue.low || 0}</span>
          </div>
        </div>
      </div>

      <div className="config-section">
        <h3>Configuration</h3>
        <div className="config-row">
          <label>Adaptive Mode</label>
          <span className={state?.config.adaptive ? 'enabled' : 'disabled'}>
            {state?.config.adaptive ? 'Enabled' : 'Disabled'}
          </span>
        </div>
        <div className="config-row">
          <label>Max CPU</label>
          <span>{state?.config.maxCPU || 80}%</span>
        </div>
        <div className="config-row">
          <label>Max Memory</label>
          <span>{state?.config.maxMemory || 1024} MB</span>
        </div>
      </div>
    </div>
  );
};
