// Frontend: API Integration Layer — Issue #25
// Bridges frontend UI with backend change detection API

import { IncrementalUpdateResult } from '../01-backend-engineer/types';

// Abstracted API service for frontend consumption
export class ChangeDetectionService {
  private apiUrl: string;
  private wsConnection: WebSocket | null = null;

  constructor(apiUrl: string = 'http://localhost:8080/api') {
    this.apiUrl = apiUrl;
  }

  async startMonitoring(): Promise<void> {
    const response = await fetch(`${this.apiUrl}/monitoring/start`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to start monitoring');
  }

  async stopMonitoring(): Promise<void> {
    const response = await fetch(`${this.apiUrl}/monitoring/stop`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to stop monitoring');
  }

  async getStatus(): Promise<{ isMonitoring: boolean; lastUpdate: string | null }> {
    const response = await fetch(`${this.apiUrl}/monitoring/status`);
    if (!response.ok) throw new Error('Failed to get status');
    return response.json();
  }

  async triggerFullRebuild(): Promise<IncrementalUpdateResult> {
    const response = await fetch(`${this.apiUrl}/monitoring/rebuild`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Full rebuild failed');
    return response.json();
  }

  async getRecentChanges(limit: number = 50): Promise<any[]> {
    const response = await fetch(`${this.apiUrl}/monitoring/changes?limit=${limit}`);
    if (!response.ok) throw new Error('Failed to get changes');
    return response.json();
  }

  // WebSocket connection for real-time updates
  connectWebSocket(onChange: (change: any) => void, onError: (err: Event) => void): void {
    if (this.wsConnection) {
      this.wsConnection.close();
    }
    this.wsConnection = new WebSocket(`ws://localhost:8080/ws/changes`);
    this.wsConnection.onmessage = (event) => {
      const change = JSON.parse(event.data);
      onChange(change);
    };
    this.wsConnection.onerror = onError;
  }

  disconnectWebSocket(): void {
    if (this.wsConnection) {
      this.wsConnection.close();
      this.wsConnection = null;
    }
  }
}
