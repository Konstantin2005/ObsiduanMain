import { injectable } from 'tsyringe';
import { EventEmitter } from 'events';
import Redis from 'ioredis';
import { Logger } from 'winston';
import { PeopleLinkGraph, LinkGenerationTask, TaskStatus, GenerationStatus } from '../types/people-links';

@injectable()
export class PeopleLinkCache {
  private redis: Redis;
  private logger: Logger;

  constructor() {
    this.redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
    this.logger = require('../utils/logger');
  }

  async getCacheKey(manifestHash: string, configVersion: number): Promise<string> {
    return `people-links:${manifestHash}:${configVersion}`;
  }

  async get(key: string): Promise<PeopleLinkGraph | null> {
    try {
      const data = await this.redis.get(key);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      this.logger.error('Cache get error', error);
      return null;
    }
  }

  async set(key: string, graph: PeopleLinkGraph, ttl: number = 3600): Promise<void> {
    try {
      await this.redis.setex(key, ttl, JSON.stringify(graph));
    } catch (error) {
      this.logger.error('Cache set error', error);
    }
  }

  async invalidatePattern(pattern: string): Promise<void> {
    try {
      const keys = await this.redis.keys(pattern);
      if (keys.length > 0) {
        await this.redis.del(...keys);
      }
    } catch (error) {
      this.logger.error('Cache invalidation error', error);
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.redis.ping();
      return true;
    } catch {
      return false;
    }
  }
}
