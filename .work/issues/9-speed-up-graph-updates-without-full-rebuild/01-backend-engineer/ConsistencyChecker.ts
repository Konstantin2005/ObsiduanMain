import { GraphStore, GraphNode, GraphEdge } from './types';

export interface ConsistencyReport {
  valid: boolean;
  errors: string[];
  warnings: string[];
  stats: {
    totalNodes: number;
    totalEdges: number;
    danglingEdges: number;
    orphanedBacklinks: number;
    missingLinks: number;
  };
}

export interface ValidationError {
  type: 'dangling_edge' | 'orphaned_backlink' | 'missing_link' | 'inconsistent_state';
  path: string;
  details: string;
}

export class ConsistencyChecker {
  public validate(graphStore: GraphStore): ConsistencyReport {
    const errors: string[] = [];
    const warnings: string[] = [];

    const danglingEdges = this.checkDanglingEdges(graphStore);
    const orphanedBacklinks = this.checkOrphanedBacklinks(graphStore);
    const missingLinks = this.checkMissingLinks(graphStore);
    const stateConsistency = this.checkStateConsistency(graphStore);

    errors.push(...danglingEdges.map(e => `Dangling edge: ${e.path} → missing target`));
    errors.push(...orphanedBacklinks.map(e => `Orphaned backlink: ${e.path} ← missing source`));
    errors.push(...missingLinks.map(e => `Missing link reference: ${e.details}`));
    errors.push(...stateConsistency.map(e => `Inconsistent state: ${e.details}`));

    this.checkUnreferencedNodes(graphStore, warnings);

    return {
      valid: errors.length === 0,
      errors,
      warnings,
      stats: {
        totalNodes: this.countNodes(graphStore),
        totalEdges: this.countEdges(graphStore),
        danglingEdges: danglingEdges.length,
        orphanedBacklinks: orphanedBacklinks.length,
        missingLinks: missingLinks.length
      }
    };
  }

  private checkDanglingEdges(graphStore: GraphStore): ValidationError[] {
    const errors: ValidationError[] = [];

    for (const [source, targets] of graphStore.outEdges) {
      if (!graphStore.nodes.has(source)) {
        errors.push({
          type: 'dangling_edge',
          path: source,
          details: `Source node does not exist`
        });
      }

      for (const target of targets) {
        if (!graphStore.nodes.has(target)) {
          errors.push({
            type: 'dangling_edge',
            path: source,
            details: `Missing target node: ${target}`
          });
        }
      }
    }

    return errors;
  }

  private checkOrphanedBacklinks(graphStore: GraphStore): ValidationError[] {
    const errors: ValidationError[] = [];

    for (const [target, sources] of graphStore.inEdges) {
      if (!graphStore.nodes.has(target)) {
        errors.push({
          type: 'orphaned_backlink',
          path: target,
          details: `Target node does not exist`
        });
      }

      for (const source of sources) {
        if (!graphStore.nodes.has(source)) {
          errors.push({
            type: 'orphaned_backlink',
            path: source,
            details: `Missing source node: ${source}`
          });
        }
      }
    }

    return errors;
  }

  private checkMissingLinks(graphStore: GraphStore): ValidationError[] {
    const errors: ValidationError[] = [];

    for (const [path, node] of graphStore.nodes) {
      for (const link of node.links) {
        const inEdges = graphStore.inEdges.get(path);
        if (!inEdges || !inEdges.has(link)) {
          const outEdges = graphStore.outEdges.get(link);
          if (!outEdges || !outEdges.has(path)) {
            errors.push({
              type: 'missing_link',
              path,
              details: `Link ${link} not reciprocated`
            });
          }
        }
      }

      for (const backlink of node.backlinks) {
        const outEdges = graphStore.outEdges.get(path);
        if (!outEdges || !outEdges.has(backlink)) {
          const inEdges = graphStore.inEdges.get(backlink);
          if (!inEdges || !inEdges.has(path)) {
            errors.push({
              type: 'missing_link',
              path,
              details: `Backlink ${backlink} not reciprocated`
            });
          }
        }
      }
    }

    return errors;
  }

  private checkStateConsistency(graphStore: GraphStore): ValidationError[] {
    const errors: ValidationError[] = [];

    for (const [path, node] of graphStore.nodes) {
      const outEdges = graphStore.outEdges.get(path);
      if (!outEdges) {
        errors.push({
          type: 'inconsistent_state',
          path,
          details: `Missing outEdges map entry`
        });
      } else {
        const expectedLinks = new Set(node.links);
        const actualTargets = outEdges;
        if (expectedLinks.size !== actualTargets.size) {
          errors.push({
            type: 'inconsistent_state',
            path,
            details: `outEdges size mismatch`
          });
        }
      }

      const inEdges = graphStore.inEdges.get(path);
      if (!inEdges) {
        errors.push({
          type: 'inconsistent_state',
          path,
          details: `Missing inEdges map entry`
        });
      } else {
        const expectedBacklinks = new Set(node.backlinks);
        const actualSources = inEdges;
        if (expectedBacklinks.size !== actualSources.size) {
          errors.push({
            type: 'inconsistent_state',
            path,
            details: `inEdges size mismatch`
          });
        }
      }
    }

    return errors;
  }

  private checkUnreferencedNodes(graphStore: GraphStore, warnings: string[]): void {
    for (const [path, node] of graphStore.nodes) {
      const hasOutgoing = graphStore.outEdges.get(path)?.size ?? 0 > 0;
      const hasIncoming = graphStore.inEdges.get(path)?.size ?? 0 > 0;
      
      if (!hasOutgoing && !hasIncoming) {
        warnings.push(`Unreferenced node: ${path} (isolated)`);
      }
    }
  }

  private countNodes(graphStore: GraphStore): number {
    return graphStore.nodes.size;
  }

  private countEdges(graphStore: GraphStore): number {
    let count = 0;
    for (const targets of graphStore.outEdges.values()) {
      count += targets.size;
    }
    return count;
  }

  public quickValidate(graphStore: GraphStore): boolean {
    for (const [source, targets] of graphStore.outEdges) {
      if (!graphStore.nodes.has(source)) return false;
      for (const target of targets) {
        if (!graphStore.nodes.has(target)) return false;
      }
    }

    for (const [target, sources] of graphStore.inEdges) {
      if (!graphStore.nodes.has(target)) return false;
      for (const source of sources) {
        if (!graphStore.nodes.has(source)) return false;
      }
    }

    return true;
  }
}