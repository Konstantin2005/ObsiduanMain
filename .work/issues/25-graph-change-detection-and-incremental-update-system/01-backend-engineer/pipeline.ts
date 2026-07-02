// Backend: Incremental Update Pipeline — Issue #25
// Processes change sets through the incremental update pipeline

import { ChangeSet, IncrementalUpdateResult } from './types';
import { NodeUpdater } from './node-updater';
import { EdgeUpdater } from './edge-updater';
import { LayoutUpdater } from './layout-updater';
import { ManifestUpdater } from './manifest-updater';

export class IncrementalPipeline {
  private nodeUpdater: NodeUpdater;
  private edgeUpdater: EdgeUpdater;
  private layoutUpdater: LayoutUpdater;
  private manifestUpdater: ManifestUpdater;

  constructor() {
    this.nodeUpdater = new NodeUpdater();
    this.edgeUpdater = new EdgeUpdater();
    this.layoutUpdater = new LayoutUpdater();
    this.manifestUpdater = new ManifestUpdater();
  }

  async execute(changes: ChangeSet): Promise<IncrementalUpdateResult> {
    const startTime = Date.now();
    const errors: string[] = [];

    try {
      // Phase 1: Handle deletions first (free up resources)
      if (changes.deleted.length > 0) {
        await this.nodeUpdater.removeNodes(changes.deleted.map(d => d.path));
        await this.edgeUpdater.removeEdges(changes.deleted.map(d => d.path));
      }

      // Phase 2: Handle renames (preserve node IDs where possible)
      for (const rename of changes.renamed) {
        await this.nodeUpdater.renameNode(rename.oldPath, rename.newPath);
        await this.edgeUpdater.updateEdgesForRename(rename.oldPath, rename.newPath);
      }

      // Phase 3: Handle additions and modifications
      const allChanges = [...changes.added, ...changes.modified];
      if (allChanges.length > 0) {
        await this.nodeUpdater.upsertNodes(allChanges);
        await this.edgeUpdater.extractAndUpdateEdges(allChanges);
        await this.layoutUpdater.updateLayout(allChanges.map(c => c.path));
      }

      // Phase 4: Update manifest atomically
      const manifestVersion = await this.manifestUpdater.commit(changes);

      return {
        success: true,
        nodesAffected: allChanges.length + changes.deleted.length,
        edgesAffected: changes.renamed.length, // approximation
        manifestVersion,
        duration: Date.now() - startTime,
      };
    } catch (err) {
      errors.push(err.message);
      // Attempt rollback
      await this.rollback(changes);
      return {
        success: false,
        nodesAffected: 0,
        edgesAffected: 0,
        manifestVersion: '',
        errors,
        duration: Date.now() - startTime,
      };
    }
  }

  async fullRebuild(vaultPath: string): Promise<IncrementalUpdateResult> {
    const startTime = Date.now();
    try {
      // Full rescan of vault
      // Rebuild all nodes, edges, layout from scratch
      await this.nodeUpdater.rebuildAll(vaultPath);
      await this.edgeUpdater.rebuildAll(vaultPath);
      await this.layoutUpdater.rebuildAll();
      const manifestVersion = await this.manifestUpdater.commitFull();

      return {
        success: true,
        nodesAffected: -1, // all nodes
        edgesAffected: -1,
        manifestVersion,
        duration: Date.now() - startTime,
      };
    } catch (err) {
      return {
        success: false,
        nodesAffected: 0,
        edgesAffected: 0,
        manifestVersion: '',
        errors: [err.message],
        duration: Date.now() - startTime,
      };
    }
  }

  private async rollback(changes: ChangeSet): Promise<void> {
    // Reverse operations in opposite order
    // Mark manifest as needing recovery
    await this.manifestUpdater.markRecoveryNeeded();
  }
}
