// Backend: Shared Types — Issue #25

export interface ChangeSet {
  added: FileChange[];
  modified: FileChange[];
  deleted: FileChange[];
  renamed: { oldPath: string; newPath: string }[];
}

export interface FileChange {
  path: string;
  hash: string;
  content?: string;
  metadata: Record<string, any>;
}

export interface FileMetadata {
  size?: number;
  mtime?: number;
  links?: string[];
}

export interface IncrementalUpdateResult {
  success: boolean;
  nodesAffected: number;
  edgesAffected: number;
  manifestVersion: string;
  errors?: string[];
  duration?: number;
}

export interface GraphNode {
  id: string;
  path: string;
  title: string;
  hash: string;
  links: string[];
  tags: string[];
  position?: { x: number; y: number };
  metadata: Record<string, any>;
}

export interface GraphEdge {
  source: string;
  target: string;
  type: 'link' | 'reference';
  weight: number;
}
