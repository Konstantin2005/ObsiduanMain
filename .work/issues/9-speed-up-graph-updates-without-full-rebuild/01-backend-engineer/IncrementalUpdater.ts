import { GraphStore, GraphNode, GraphEdge, ManifestEntry, GraphDelta, GraphOperation } from './types';

export class IncrementalUpdater {
  constructor(private graphStore: GraphStore) {}

  public apply(delta: GraphDelta, manifest: Map<string, ManifestEntry>): void {
    const operations: GraphOperation[] = [];

    for (const path of delta.added) {
      const entry = manifest.get(path);
      if (entry) {
        this.addNode(entry);
        this.addEdgeFrom(entry);
        operations.push({ type: 'add', path, entry });
      }
    }

    for (const path of delta.removed) {
      this.removeNode(path);
      operations.push({ type: 'remove', path });
    }

    for (const path of delta.updated) {
      const entry = manifest.get(path);
      if (entry) {
        this.updateNode(entry);
        this.updateEdges(entry);
        operations.push({ type: 'update', path, entry });
      }
    }

    this.ensureConsistency();
  }

  private addNode(entry: ManifestEntry): void {
    const node: GraphNode = {
      id: entry.path,
      path: entry.path,
      label: this.extractLabel(entry.path),
      size: entry.stat.size,
      ctime: entry.stat.ctime,
      mtime: entry.stat.mtime,
      links: [...entry.links],
      backlinks: [...entry.backlinks]
    };

    this.graphStore.nodes.set(entry.path, node);
    this.graphStore.outEdges.set(entry.path, new Set());
    this.graphStore.inEdges.set(entry.path, new Set());
  }

  private removeNode(path: string): void {
    this.removeOutgoingEdges(path);
    this.removeIncomingEdges(path);
    
    this.graphStore.nodes.delete(path);
    this.graphStore.outEdges.delete(path);
    this.graphStore.inEdges.delete(path);
  }

  private removeOutgoingEdges(path: string): void {
    const outEdges = this.graphStore.outEdges.get(path);
    if (outEdges) {
      for (const target of outEdges) {
        this.graphStore.inEdges.get(target)?.delete(path);
      }
      this.graphStore.outEdges.delete(path);
    }
  }

  private removeIncomingEdges(path: string): void {
    const inEdges = this.graphStore.inEdges.get(path);
    if (inEdges) {
      for (const source of inEdges) {
        this.graphStore.outEdges.get(source)?.delete(path);
      }
      this.graphStore.inEdges.delete(path);
    }
  }

  private updateNode(entry: ManifestEntry): void {
    const node = this.graphStore.nodes.get(entry.path);
    if (node) {
      node.mtime = entry.stat.mtime;
      node.size = entry.stat.size;
      node.links = [...entry.links];
      node.backlinks = [...entry.backlinks];
    }
  }

  private updateEdges(entry: ManifestEntry): void {
    const oldOutEdges = this.graphStore.outEdges.get(entry.path);
    const newOutEdges = new Set(entry.links);

    if (oldOutEdges) {
      for (const target of oldOutEdges) {
        if (!newOutEdges.has(target)) {
          this.graphStore.inEdges.get(target)?.delete(entry.path);
        }
      }
    }

    this.graphStore.outEdges.set(entry.path, new Set(entry.links));

    for (const link of entry.links) {
      if (!this.graphStore.inEdges.has(link)) {
        this.graphStore.inEdges.set(link, new Set());
      }
      this.graphStore.inEdges.get(link)?.add(entry.path);
    }
  }

  private addEdgeFrom(entry: ManifestEntry): void {
    this.graphStore.outEdges.set(entry.path, new Set(entry.links));

    for (const link of entry.links) {
      if (!this.graphStore.inEdges.has(link)) {
        this.graphStore.inEdges.set(link, new Set());
      }
      this.graphStore.inEdges.get(link)?.add(entry.path);
    }
  }

  private ensureConsistency(): void {
    const danglingEdges = this.findDanglingEdges();
    if (danglingEdges.length > 0) {
      throw new Error(`Consistency check failed: ${danglingEdges.length} dangling edges detected`);
    }
  }

  private findDanglingEdges(): string[] {
    const dangling: string[] = [];

    for (const [source, targets] of this.graphStore.outEdges) {
      for (const target of targets) {
        if (!this.graphStore.nodes.has(target)) {
          dangling.push(`${source} -> ${target}`);
        }
      }
    }

    for (const [target, sources] of this.graphStore.inEdges) {
      for (const source of sources) {
        if (!this.graphStore.nodes.has(source)) {
          dangling.push(`${source} -> ${target}`);
        }
      }
    }

    return dangling;
  }

  private extractLabel(path: string): string {
    const parts = path.split('/');
    const filename = parts[parts.length - 1];
    return filename.replace('.md', '');
  }

  public getNode(path: string): GraphNode | undefined {
    return this.graphStore.nodes.get(path);
  }

  public getNeighbors(path: string): GraphNode[] {
    const neighbors: GraphNode[] = [];
    const outEdges = this.graphStore.outEdges.get(path);

    if (outEdges) {
      for (const target of outEdges) {
        const node = this.graphStore.nodes.get(target);
        if (node) neighbors.push(node);
      }
    }

    const inEdges = this.graphStore.inEdges.get(path);
    if (inEdges) {
      for (const source of inEdges) {
        const node = this.graphStore.nodes.get(source);
        if (node && !neighbors.some(n => n.path === source)) {
          neighbors.push(node);
        }
      }
    }

    return neighbors;
  }
}