// Backend: Change Detection API — Issue #25
// API endpoints for the change detection and incremental update system

import { ChangeSet, IncrementalUpdateResult, FileMetadata } from './types';
import { FileWatcher } from './watcher';
import { ContentHasher } from './hasher';
import { DiffEngine } from './diff-engine';
import { IncrementalPipeline } from './pipeline';

export class ChangeDetectionAPI {
  private watcher: FileWatcher;
  private hasher: ContentHasher;
  private diffEngine: DiffEngine;
  private pipeline: IncrementalPipeline;

  constructor() {
    this.watcher = new FileWatcher({ debounceMs: 300, ignorePatterns: ['.git', '.obsidian', '.trash'] });
    this.hasher = new ContentHasher();
    this.diffEngine = new DiffEngine();
    this.pipeline = new IncrementalPipeline();
  }

  // Start monitoring the vault for changes
  async startMonitoring(vaultPath: string): Promise<void> {
    await this.hasher.initialize(vaultPath);
    this.watcher.start(vaultPath, async (events) => {
      const changes = await this.processEvents(events);
      if (changes.changed.size > 0) {
        await this.applyIncrementalUpdate(changes);
      }
    });
  }

  // Process raw file system events into structured changes
  private async processEvents(events: FileSystemEvent[]): Promise<ChangeSet> {
    const added: FileChange[] = [];
    const modified: FileChange[] = [];
    const deleted: FileChange[] = [];
    const renamed: { oldPath: string; newPath: string }[] = [];

    for (const event of events) {
      switch (event.type) {
        case 'add':
          added.push(await this.buildFileChange(event.path));
          break;
        case 'change':
          modified.push(await this.buildFileChange(event.path));
          break;
        case 'unlink':
          deleted.push({ path: event.path, hash: '', metadata: {} });
          break;
      }
    }

    // Detect renames by matching content hashes
    const renameCandidates = this.diffEngine.detectRenames(added, deleted);
    renamed.push(...renameCandidates);

    return { added, modified, deleted, renamed };
  }

  private async buildFileChange(path: string): Promise<FileChange> {
    const content = await this.readFile(path);
    const hash = this.hasher.compute(content);
    return { path, hash, content, metadata: await this.getMetadata(path) };
  }

  // Apply incremental update to graph
  async applyIncrementalUpdate(changes: ChangeSet): Promise<IncrementalUpdateResult> {
    return this.pipeline.execute(changes);
  }

  // Force full rebuild fallback
  async fullRebuild(vaultPath: string): Promise<IncrementalUpdateResult> {
    return this.pipeline.fullRebuild(vaultPath);
  }

  async stopMonitoring(): Promise<void> {
    this.watcher.stop();
  }
}

// Types
export interface FileSystemEvent {
  type: 'add' | 'change' | 'unlink';
  path: string;
}

interface FileChange {
  path: string;
  hash: string;
  content?: string;
  metadata: Record<string, any>;
}
