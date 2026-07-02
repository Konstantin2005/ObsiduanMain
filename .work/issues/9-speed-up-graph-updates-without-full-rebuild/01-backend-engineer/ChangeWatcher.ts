import { TFile, Vault, MetadataCache } from 'obsidian';
import { ManifestEntry } from './types';

export interface VaultEvent {
  type: 'create' | 'delete' | 'modify' | 'rename';
  path: string;
  oldPath?: string;
  file?: TFile;
}

export interface BatchEvent {
  events: VaultEvent[];
  timestamp: number;
}

export type ChangeCallback = (batch: BatchEvent) => void;

export class ChangeWatcher {
  private eventBuffer: VaultEvent[] = [];
  private batchTimer: ReturnType<typeof setTimeout> | null = null;
  private readonly batchInterval: number = 500;

  constructor(
    private vault: Vault,
    private metadataCache: MetadataCache,
    private callback: ChangeCallback
  ) {
    this.setupEventListeners();
  }

  private setupEventListeners(): void {
    this.vault.on('create', (file) => {
      if (file instanceof TFile && this.isMarkdownFile(file)) {
        this.bufferEvent({ type: 'create', path: file.path, file });
      }
    });

    this.vault.on('delete', (file) => {
      if (file instanceof TFile && this.isMarkdownFile(file)) {
        this.bufferEvent({ type: 'delete', path: file.path });
      }
    });

    this.vault.on('modify', (file) => {
      if (file instanceof TFile && this.isMarkdownFile(file)) {
        this.bufferEvent({ type: 'modify', path: file.path, file });
      }
    });

    this.vault.on('rename', (file, oldPath) => {
      if (file instanceof TFile && this.isMarkdownFile(file)) {
        this.bufferEvent({ type: 'rename', path: file.path, oldPath });
      }
    });
  }

  private isMarkdownFile(file: TFile): boolean {
    return file.extension === 'md';
  }

  private bufferEvent(event: VaultEvent): void {
    this.eventBuffer.push(event);

    if (this.batchTimer === null) {
      this.flushBatch();
    }
  }

  private flushBatch(): void {
    if (this.batchTimer !== null) {
      clearTimeout(this.batchTimer);
    }

    this.batchTimer = setTimeout(() => {
      if (this.eventBuffer.length > 0) {
        const batch: BatchEvent = {
          events: [...this.eventBuffer],
          timestamp: Date.now()
        };

        this.eventBuffer = [];
        this.callback(batch);
      }

      this.batchTimer = null;
    }, this.batchInterval);
  }

  public forceFlush(): void {
    if (this.batchTimer !== null) {
      clearTimeout(this.batchTimer);
      this.batchTimer = null;
    }

    if (this.eventBuffer.length > 0) {
      const batch: BatchEvent = {
        events: [...this.eventBuffer],
        timestamp: Date.now()
      };

      this.eventBuffer = [];
      this.callback(batch);
    }
  }

  public destroy(): void {
    if (this.batchTimer !== null) {
      clearTimeout(this.batchTimer);
      this.batchTimer = null;
    }
    this.eventBuffer = [];
  }

  public get bufferLength(): number {
    return this.eventBuffer.length;
  }
}