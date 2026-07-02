import { injectable } from 'tsyringe';
import { EventEmitter } from 'events';
import { PeopleLinkCache } from './cache/PeopleLinkCache';
import { PeopleLinkGenerator } from './generators/PeopleLinkGenerator';
import { LinkGenerationTask, GenerationStatus, TaskStatus, PeopleLinkGraph } from '../types/people-links';

@injectable()
export class PeopleLinkService {
  private cache: PeopleLinkCache;
  private generator: PeopleLinkGenerator;
  private taskEmitter: EventEmitter;

  constructor() {
    this.cache = new PeopleLinkCache();
    this.generator = new PeopleLinkGenerator();
    this.taskEmitter = new EventEmitter();
  }

  async getPeopleLinks(
    manifestHash: string,
    configVersion: number,
    triggerGeneration: boolean = false
  ): Promise<{ graph: PeopleLinkGraph | null; taskId?: string }> {
    const cacheKey = await this.cache.getCacheKey(manifestHash, configVersion);
    
    // Try to get from cache first
    let graph = await this.cache.get(cacheKey);
    
    if (graph) {
      return { graph };
    }
    
    if (triggerGeneration) {
      // Cache miss, trigger background generation
      const taskId = await this.startGenerationTask(manifestHash, configVersion);
      return { graph: null, taskId };
    }
    
    // Cache miss without trigger - return empty
    return { graph: null };
  }

  async startGenerationTask(
    manifestHash: string,
    configVersion: number,
    changedNotes?: string[]
  ): Promise<string> {
    const task: LinkGenerationTask = {
      taskId: `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      vaultId: 'main',
      manifestHash,
      configVersion,
      changedNotes,
      priority: 'background',
      timestamp: Date.now()
    };
    
    // Emit task for worker to pick up
    this.taskEmitter.emit('task:created', task);
    return task.taskId;
  }

  async getTaskStatus(taskId: string): Promise<GenerationStatus | null> {
    const status = await this.generator.getTaskStatus?.(taskId);
    return status || null;
  }

  async healthCheck(): Promise<any> {
    const cacheHealth = await this.cache.healthCheck();
    const generatorHealth = await this.generator.healthCheck?.() || { status: 'not_implemented' };
    
    return {
      cache: cacheHealth,
      generator: generatorHealth,
      status: cacheHealth && generatorHealth.status === 'healthy' ? 'healthy' : 'degraded'
    };
  }

  onTaskCreated(callback: (task: LinkGenerationTask) => void): void {
    this.taskEmitter.on('task:created', callback);
  }

  onTaskCompleted(callback: (status: GenerationStatus) => void): void {
    this.taskEmitter.on('task:completed', callback);
  }
}

