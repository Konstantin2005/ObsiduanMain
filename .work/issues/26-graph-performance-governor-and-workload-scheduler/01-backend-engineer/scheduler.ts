// Backend: Workload Scheduler — Issue #26
// Priority-based scheduling with backpressure and load shedding

import { ThrottleLevel } from './governor-core';

export class WorkloadScheduler {
  private highPriorityQueue: WorkItem[] = [];
  private mediumPriorityQueue: WorkItem[] = [];
  private lowPriorityQueue: WorkItem[] = [];
  private isRunning: boolean = false;
  private currentThrottle: ThrottleLevel = 'none';

  constructor() {
    this.processQueue = this.processQueue.bind(this);
  }

  start(): void {
    this.isRunning = true;
    setImmediate(this.processQueue);
  }

  stop(): void {
    this.isRunning = false;
  }

  submit(item: WorkItem): void {
    switch (item.priority) {
      case 'high':
        this.highPriorityQueue.push(item);
        break;
      case 'medium':
        this.mediumPriorityQueue.push(item);
        break;
      case 'low':
        this.lowPriorityQueue.push(item);
        break;
    }
    if (!this.isRunning) this.start();
  }

  setThrottle(throttle: ThrottleLevel): void {
    this.currentThrottle = throttle;
  }

  private async processQueue(): Promise<void> {
    while (this.isRunning) {
      const item = this.dequeue();
      if (!item) {
        this.isRunning = false;
        return;
      }

      // Backpressure check
      if (this.shouldApplyBackpressure(item)) {
        if (item.onBackpressure) {
          item.onBackpressure();
        }
        // Re-queue at appropriate priority
        this.submit({ ...item, priority: 'low' });
        await this.sleep(100);
        continue;
      }

      try {
        await item.execute();
      } catch (err) {
        console.error(`Work item ${item.id} failed:`, err);
      }
    }
  }

  private dequeue(): WorkItem | null {
    // High priority always goes first
    if (this.highPriorityQueue.length > 0) {
      return this.highPriorityQueue.shift()!;
    }

    const throttleMultiplier = this.getThrottleMultiplier();

    // Medium priority with throttle
    if (this.mediumPriorityQueue.length > 0) {
      if (Math.random() < throttleMultiplier) {
        return this.mediumPriorityQueue.shift()!;
      }
      return this.lowPriorityQueue.shift()! || this.mediumPriorityQueue.shift()!;
    }

    return this.lowPriorityQueue.shift()! || null;
  }

  private shouldApplyBackpressure(item: WorkItem): boolean {
    if (item.type === 'interactive') return false; // never backpressure interactive work
    return this.currentThrottle === 'critical' || this.currentThrottle === 'heavy';
  }

  private getThrottleMultiplier(): number {
    switch (this.currentThrottle) {
      case 'none': return 1.0;
      case 'light': return 0.8;
      case 'medium': return 0.5;
      case 'heavy': return 0.3;
      case 'critical': return 0.1;
    }
  }

  getQueueStats(): QueueStats {
    return {
      high: this.highPriorityQueue.length,
      medium: this.mediumPriorityQueue.length,
      low: this.lowPriorityQueue.length,
      throttle: this.currentThrottle,
    };
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export interface WorkItem {
  id: string;
  priority: 'high' | 'medium' | 'low';
  type: 'interactive' | 'background';
  execute: () => Promise<void>;
  onBackpressure?: () => void;
}

export interface QueueStats {
  high: number;
  medium: number;
  low: number;
  throttle: ThrottleLevel;
}
