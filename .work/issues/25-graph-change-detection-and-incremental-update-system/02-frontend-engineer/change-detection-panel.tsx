// Frontend: Change Detection Panel — Issue #25
// UI component for monitoring incremental graph updates

import React, { useState, useEffect, useCallback } from 'react';
import { ChangeDetectionAPI, IncrementalUpdateResult } from '../backend/change-detection-api';

interface ChangeEvent {
  type: 'added' | 'modified' | 'deleted' | 'renamed';
  path: string;
  timestamp: number;
}

export const ChangeDetectionPanel: React.FC = () => {
  const [isMonitoring, setIsMonitoring] = useState(false);
  const [recentChanges, setRecentChanges] = useState<ChangeEvent[]>([]);
  const [lastUpdateResult, setLastUpdateResult] = useState<IncrementalUpdateResult | null>(null);
  const [status, setStatus] = useState<'idle' | 'monitoring' | 'updating' | 'error'>('idle');
  const [error, setError] = useState<string | null>(null);

  const api = new ChangeDetectionAPI();

  const handleStartMonitoring = useCallback(async () => {
    setStatus('monitoring');
    setError(null);
    try {
      await api.startMonitoring('/path/to/vault');
      setIsMonitoring(true);
    } catch (err) {
      setStatus('error');
      setError(err.message);
      setIsMonitoring(false);
    }
  }, []);

  const handleStopMonitoring = useCallback(async () => {
    await api.stopMonitoring();
    setIsMonitoring(false);
    setStatus('idle');
  }, []);

  const handleFullRebuild = useCallback(async () => {
    setStatus('updating');
    setError(null);
    try {
      const result = await api.fullRebuild('/path/to/vault');
      setLastUpdateResult(result);
      if (result.success) {
        setStatus('monitoring');
      } else {
        setStatus('error');
        setError(result.errors?.join(', ') || 'Full rebuild failed');
      }
    } catch (err) {
      setStatus('error');
      setError(err.message);
    }
  }, []);

  return (
    <div className="change-detection-panel">
      <div className="panel-header">
        <h2>Change Detection</h2>
        <span className={`status-badge ${status}`}>{status}</span>
      </div>

      <div className="controls">
        {!isMonitoring ? (
          <button onClick={handleStartMonitoring} disabled={status === 'monitoring'}>
            Start Monitoring
          </button>
        ) : (
          <button onClick={handleStopMonitoring}>Stop Monitoring</button>
        )}
        <button onClick={handleFullRebuild} disabled={status === 'updating'}>
          Full Rebuild (Fallback)
        </button>
      </div>

      {error && (
        <div className="error-banner">
          <span className="error-icon">⚠</span>
          <span>{error}</span>
        </div>
      )}

      {lastUpdateResult && (
        <div className="update-result">
          <h3>Last Update Result</h3>
          <div className="metrics">
            <div className="metric">
              <label>Success</label>
              <span className={lastUpdateResult.success ? 'success' : 'failure'}>
                {lastUpdateResult.success ? 'Yes' : 'No'}
              </span>
            </div>
            <div className="metric">
              <label>Nodes Affected</label>
              <span>{lastUpdateResult.nodesAffected}</span>
            </div>
            <div className="metric">
              <label>Edges Affected</label>
              <span>{lastUpdateResult.edgesAffected}</span>
            </div>
            <div className="metric">
              <label>Duration</label>
              <span>{lastUpdateResult.duration}ms</span>
            </div>
          </div>
        </div>
      )}

      <div className="recent-changes">
        <h3>Recent Changes</h3>
        {recentChanges.length === 0 ? (
          <div className="empty-state">No changes detected yet.</div>
        ) : (
          <ul>
            {recentChanges.map((change, idx) => (
              <li key={idx} className={`change-item ${change.type}`}>
                <span className="change-type">{change.type}</span>
                <span className="change-path">{change.path}</span>
                <span className="change-time">
                  {new Date(change.timestamp).toLocaleTimeString()}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};
