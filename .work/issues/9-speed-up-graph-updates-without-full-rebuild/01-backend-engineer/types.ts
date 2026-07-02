import { TFile, TFolder } from 'obsidian';

export interface ManifestEntry {
  path: string;
  stat: {
    ctime: number;
    mtime: number;
    size: number;
  };
  links: string[];
  backlinks: string[];
}

export interface GraphNode {
  id: string;
  path: string;
  label: string;
  size: number;
  ctime: number;
  mtime: number;
  links: string[];
  backlinks: string[];
}

export interface GraphEdge {
  source: string;
  target: string;
  type: 'link' | 'backlink';
}

export interface GraphDelta {
  added: string[];
  removed: string[];
  updated: string[];
  unchanged: string[];
}

export interface GraphStore {
  nodes: Map<string, GraphNode>;
  edges: Map<string, Set<string>>;
  outEdges: Map<string, Set<string>>;
  inEdges: Map<string, Set<string>>;
}

export type OperationType = 'add' | 'remove' | 'update';

export interface GraphOperation {
  type: OperationType;
  path: string;
  entry?: ManifestEntry;
}

export interface GraphUpdateResult {
  operations: GraphOperation[];
  delta: GraphDelta;
  timestamp: number;
}