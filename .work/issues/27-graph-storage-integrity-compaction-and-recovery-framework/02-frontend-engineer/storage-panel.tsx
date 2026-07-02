// Frontend: Storage Panel — Issue #27
// UI for monitoring storage integrity, compaction, and recovery

import React, { useState, useEffect, useCallback } from 'react';
import { ShardInfo, CompactionStatus } from '../backend/storage-layer';

interface StorageState {
  shards: ShardInfo[];
  compaction: CompactionStatus;
  totalSize: number;
  totalEntries: number;
}

export const StoragePanel: React.FC = () => {
  const [state, setState] = useState<StorageState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchState = useCallback(async () => {
    try {
      const [shardsRes, statusRes] = await Promise.all([
        fetch('/api/storage/shards'),
        fetch('/api/storage/compaction'),
      ]);
      if (!shardsRes.ok || !statusRes.ok) throw new Error('Failed to fetch storage state');
      const shards: ShardInfo[] = await shardsRes.json();
      const compaction: CompactionStatus = await statusRes.json();
      setState({
        shards,
        compaction,
        totalSize: shards.reduce((s, sh) => s + sh.totalSizeBytes, 0),
        totalEntries: shards.reduce((s, sh) => s + sh.entryCount, 0),
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchState();
    const interval = setInterval(fetchState, 5000);
    return () => clearInterval(interval);
  }, [fetchState]);

  const triggerCompaction = useCallback(async () => {
    try {
      const response = await fetch('/api/storage/compaction/trigger', { method: 'POST' });
      if (!response.ok) throw new Error('Failed to trigger compaction');
      await fetchState();
    } catch (err) {
      setError(err.message);
    }
  }, [fetchState]);

  const formatBytes = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  if (isLoading) {
    return <div className="storage-panel loading">Loading storage data...</div>;
  }

  if (error) {
    return (
      <div className="storage-panel error">
        <div className="error-header">
          <span className="error-icon">⚠</span>
          <span>Error: {error}</span>
        </div>
        <button onClick={fetchState}>Retry</button>
      </div>
    );
  }

  return (
    <div className="storage-panel">
      <div className="panel-header">
        <h2>Storage Integrity</h2>
        {state?.compaction.isRunning && <span className="compacting-badge">Compacting...</span>}
      </div>

      <div className="summary-section">
        <div className="summary-card">
          <label>Total Shards</label>
          <span>{state?.shards.length || 0}</span>
        </div>
        <div className="summary-card">
          <label>Total Entries</label>
          <span>{state?.totalEntries || 0}</span>
        </div>
        <div className="summary-card">
          <label>Total Size</label>
          <span>{formatBytes(state?.totalSize || 0)}</span>
        </div>
        <div className="summary-card">
          <label>Last Compaction</label>
          <span>{state?.compaction.lastRun ? new Date(state.compaction.lastRun).toLocaleString() : 'Never'}</span>
        </div>
      </div>

      <div className="actions-section">
        <button onClick={triggerCompaction} disabled={state?.compaction.isRunning}>
          {state?.compaction.isRunning ? 'Compacting...' : 'Trigger Compaction'}
        </button>
      </div>

      <div className="shards-section">
        <h3>Shards</h3>
        {state?.shards.length === 0 ? (
          <div className="empty-state">No shards created yet.</div>
        ) : (
          <div className="shards-table">
            <div className="shards-header">
              <span>Shard ID</span>
              <span>Entries</span>
              <span>Size</span>
              <span>Tombstones</span>
            </div>
            {state?.shards.map((shard) => (
              <div key={shard.id} className="shard-row">
                <span className="shard-id">{shard.id}</span>
                <span>{shard.entryCount}</span>
                <span>{formatBytes(shard.totalSizeBytes)}</span>
                <span className={shard.tombstoneCount > 0 ? 'has-tombstones' : ''}>
                  {shard.tombstoneCount}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
