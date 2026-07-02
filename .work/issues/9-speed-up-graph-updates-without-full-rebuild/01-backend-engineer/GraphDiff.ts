import { ManifestEntry, GraphDelta } from './types';

export class GraphDiff {
  compute(oldManifest: Map<string, ManifestEntry>, newManifest: Map<string, ManifestEntry>): GraphDelta {
    const added: string[] = [];
    const removed: string[] = [];
    const updated: string[] = [];
    const unchanged: string[] = [];

    const oldPaths = new Set(oldManifest.keys());
    const newPaths = new Set(newManifest.keys());

    for (const path of newPaths) {
      if (!oldPaths.has(path)) {
        added.push(path);
      } else {
        const oldEntry = oldManifest.get(path)!;
        const newEntry = newManifest.get(path)!;
        
        const hasChanges = this.hasFileChanges(oldEntry, newEntry);
        if (hasChanges) {
          updated.push(path);
        } else {
          unchanged.push(path);
        }
      }
    }

    for (const path of oldPaths) {
      if (!newPaths.has(path)) {
        removed.push(path);
      }
    }

    return { added, removed, updated, unchanged };
  }

  private hasFileChanges(oldEntry: ManifestEntry, newEntry: ManifestEntry): boolean {
    if (oldEntry.stat.mtime !== newEntry.stat.mtime) return true;
    if (oldEntry.stat.size !== newEntry.stat.size) return true;
    if (oldEntry.links.length !== newEntry.links.length) return true;
    if (oldEntry.backlinks.length !== newEntry.backlinks.length) return true;
    
    const oldLinksSet = new Set(oldEntry.links);
    const newLinksSet = new Set(newEntry.links);
    if (oldLinksSet.size !== newLinksSet.size) return true;
    
    for (const link of oldEntry.links) {
      if (!newLinksSet.has(link)) return true;
    }
    
    const oldBacklinksSet = new Set(oldEntry.backlinks);
    const newBacklinksSet = new Set(newEntry.backlinks);
    if (oldBacklinksSet.size !== newBacklinksSet.size) return true;
    
    for (const backlink of oldEntry.backlinks) {
      if (!newBacklinksSet.has(backlink)) return true;
    }
    
    return false;
  }

  computeLinkDelta(entry: ManifestEntry, oldEntry?: ManifestEntry): { added: string[], removed: string[] } {
    if (!oldEntry) {
      return { added: [...entry.links], removed: [] };
    }

    const oldLinks = new Set(oldEntry.links);
    const newLinks = new Set(entry.links);

    const added = entry.links.filter(link => !oldLinks.has(link));
    const removed = oldEntry.links.filter(link => !newLinks.has(link));

    return { added, removed };
  }

  computeBacklinkDelta(entry: ManifestEntry, oldEntry?: ManifestEntry): { added: string[], removed: string[] } {
    if (!oldEntry) {
      return { added: [...entry.backlinks], removed: [] };
    }

    const oldBacklinks = new Set(oldEntry.backlinks);
    const newBacklinks = new Set(entry.backlinks);

    const added = entry.backlinks.filter(link => !oldBacklinks.has(link));
    const removed = oldEntry.backlinks.filter(link => !newBacklinks.has(link));

    return { added, removed };
  }
}