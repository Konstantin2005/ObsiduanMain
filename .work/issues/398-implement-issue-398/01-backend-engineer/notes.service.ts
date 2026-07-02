// Сервис заметок для управления данными

import crypto from 'crypto';
import { DatabaseService } from './database.service';
import { FileServerService } from './file-server.service';
import { ParserService } from './parser.service';
import { NotionService } from './notion.service';

export interface Note {
    id: string;
    title: string;
    content: string;
    syntax: string;
    tags: string[];
    labels: string[];
    path: string;
    owner: string;
    group: string;
    created_at: string;
    updated_at: string;
    status: 'draft' | 'published' | 'archived';
    ttl?: number;
}

export interface NoteCreateData {
    title: string;
    content: string;
    syntax: string;
    tags?: string[];
    labels?: string[];
    path?: string;
    owner?: string;
    group?: string;
    status?: 'draft' | 'published' | 'archived';
    ttl?: number;
}

export interface NoteUpdateData {
    title?: string;
    content?: string;
    syntax?: string;
    tags?: string[];
    labels?: string[];
    path?: string;
    owner?: string;
    group?: string;
    status?: 'draft' | 'published' | 'archived';
    ttl?: number;
    version?: number;
}

export interface PageResult<T> {
    data: T[];
    page: number;
    limit: number;
    total: number;
    has_more: boolean;
}

export class NoteService {
    private databaseService: DatabaseService;
    private fileServerService: FileServerService;
    private parserService: ParserService;
    private notionService: NotionService;

    constructor() {
        this.databaseService = new DatabaseService();
        this.fileServerService = new FileServerService();
        this.parserService = new ParserService();
        this.notionService = new NotionService();
    }

    public async createNote(data: NoteCreateData): Promise<Note> {
        const noteId = crypto.randomUUID();
        const now = new Date().toISOString();
        
        const note: Note = {
            id: noteId,
            title: data.title,
            content: data.content,
            syntax: data.syntax,
            tags: data.tags || [],
            labels: data.labels || [],
            path: data.path || `/documents/${noteId}`,
            owner: data.owner || 'system',
            group: data.group || 'default',
            created_at: now,
            updated_at: now,
            status: data.status || 'draft',
            ttl: data.ttl,
        };

        await this.validateNote(note);

        const storedNote = await this.databaseService.saveNote(note);
        await this.syncNoteToFileSystem(note);

        return storedNote;
    }

    public async getNote(id: string): Promise<Note | null> {
        return await this.databaseService.getNote(id);
    }

    public async updateNote(id: string, data: NoteUpdateData): Promise<Note | null> {
        const note = await this.databaseService.getNote(id);
        if (!note) {
            throw new Error('Note not found');
        }

        const updatedNote: Note = {
            ...note,
            ...data,
            updated_at: new Date().toISOString(),
        };

        await this.validateNote(updatedNote);

        const storedNote = await this.databaseService.saveNote(updatedNote);
        await this.syncNoteToFileSystem(storedNote);

        return storedNote;
    }

    public async deleteNote(id: string): Promise<void> {
        await this.databaseService.deleteNote(id);
        await this.fileServerService.removeNoteFiles(id);
    }

    public async exportNote(id: string, format: string): Promise<Buffer> {
        const note = await this.databaseService.getNote(id);
        if (!note) {
            throw new Error('Note not found');
        }

        switch (format.toLowerCase()) {
            case 'markdown':
                return Buffer.from(note.content, 'utf8');
            case 'txt':
                return Buffer.from(this.stripMarkdown(note.content), 'utf8');
            case 'json':
                return Buffer.from(JSON.stringify(note, null, 2), 'utf8');
            default:
                throw new Error(`Unsupported export format: ${format}`);
        }
    }

    public async listNotes(page: number, limit: number, sort: string): Promise<PageResult<Note>> {
        return await this.databaseService.getNotes(page, limit, sort);
    }

    public async searchNotes(query: string): Promise<Note[]> {
        return await this.databaseService.searchNotes(query);
    }

    public async listContexts(): Promise<string[]> {
        return await this.databaseService.getDistinctLabels();
    }

    public async getStats(): Promise<Record<string, any>> {
        return await this.databaseService.getStats();
    }

    public async healthCheck(): Promise<Record<string, any>> {
        const health = {
            database: await this.databaseService.healthCheck(),
            fileServer: await this.fileServerService.healthCheck(),
        };
        return health;
    }

    public async syncNoteToFileSystem(note: Note): Promise<void> {
        try {
            if (note.path) {
                await this.fileServerService.saveFile(note.path, note);
            }
        } catch (error) {
            console.error(`Failed to sync note ${note.id} to file system:`, error);
        }
    }

    private async validateNote(note: Note): Promise<void> {
        if (!note.title || note.title.trim().length === 0) {
            throw new Error('Title is required');
        }

        if (!note.content || note.content.trim().length === 0) {
            throw new Error('Content is required');
        }

        if (!note.syntax || note.syntax.trim().length === 0) {
            throw new Error('Syntax is required');
        }

        if (note.syntax.length > 100) {
            throw new Error('Syntax must be between 1 and 100 characters');
        }

        if (note.title.length > 255) {
            throw new Error('Title must be between 1 and 255 characters');
        }

        if (note.labels.length > 10) {
            throw new Error('Number of labels must be less than or equal to 10');
        }

        if (note.tags.length > 20) {
            throw new Error('Number of tags must be less than or equal to 20');
        }

        if (note.ttl && note.ttl < 0) {
            throw new Error('TTL must be positive');
        }

        if (note.path && note.path.startsWith('/')) {
            throw new Error('Path cannot be root');
        }
    }

    private stripMarkdown(markdown: string): string {
        return markdown
            .replace(/#{1,6}\s/g, '')
            .replace(/\*\*(.*?)\*\*/g, '$1')
            .replace(/\*(.*?)\*/g, '$1')
            .replace(/\[(.*?)\]\(.*?\)/g, '$1')
            .replace(/`(.*?)`/g, '$1')
            .replace(/\>\s/g, '')
            .replace(/\-\s/g, '')
            .replace(/\d+\.\s/g, '');
    }
}

export default NoteService;