// TypeScript types for people links generation

export interface PeopleNode {
  id: string;
  name: string;
  aliases: string[];
  noteIds: string[];
}

export interface PeopleEdge {
  sourceId: string;
  targetId: string;
  weight: number;
  contexts: string[];
}

export interface PeopleLinkGraph {
  version: number;
  generatedAt: number;
  manifestHash: string;
  nodes: Map<string, PeopleNode>;
  edges: PeopleEdge[];
}

export interface LinkGenerationTask {
  taskId: string;
  vaultId: string;
  manifestHash: string;
  configVersion: number;
  changedNotes?: string[];
  priority: 'foreground' | 'background';
  timestamp: number;
}

export enum TaskStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

export interface GenerationStatus {
  taskId: string;
  status: TaskStatus;
  progress: number; // 0-100
  startedAt: number;
  completedAt?: number;
  error?: string;
  result?: PeopleLinkGraph;
}

export interface CacheEntry {
  key: string;
  graph: PeopleLinkGraph;
  ttl: number;
  createdAt: number;
}
