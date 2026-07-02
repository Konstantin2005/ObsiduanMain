// Backend API сервис для заметок и управления документами

import express from 'express';
import { NoteService } from './notes.service';
import { ParserService } from './parser.service';
import { FileServerService } from './file-server.service';

export class NotesAPI {
    private app: express.Express;
    private noteService: NoteService;
    private parserService: ParserService;
    private fileServerService: FileServerService;

    constructor() {
        this.app = express();
        this.noteService = new NoteService();
        this.parserService = new ParserService();
        this.fileServerService = new FileServerService();
        this.initializeRoutes();
    }

    private initializeRoutes(): void {
        this.app.post('/api/notes', this.createNote.bind(this));
        this.app.get('/api/notes/:id', this.getNote.bind(this));
        this.app.put('/api/notes/:id', this.updateNote.bind(this));
        this.app.delete('/api/notes/:id', this.deleteNote.bind(this));
        this.app.post('/api/notes/:id/export', this.exportNote.bind(this));
        this.app.get('/api/notes', this.listNotes.bind(this));
        this.app.get('/api/notes/search', this.searchNotes.bind(this));
        this.app.get('/api/contexts', this.listContexts.bind(this));
        this.app.get('/api/stats', this.getStats.bind(this));
        this.app.get('/api/health', this.healthCheck.bind(this));
        this.app.get('/api/static/:path', this.serveStaticFiles.bind(this));
    }

    public async createNote(req: express.Request, res: express.Response): Promise<void> {
        try {
            const noteData = req.body;
            const note = await this.noteService.createNote(noteData);
            res.status(201).json(note);
        } catch (error) {
            res.status(400).json({ error: (error as Error).message });
        }
    }

    public async getNote(req: express.Request, res: express.Response): Promise<void> {
        try {
            const { id } = req.params;
            const note = await this.noteService.getNote(id);
            if (!note) {
                res.status(404).json({ error: 'Note not found' });
                return;
            }
            res.json(note);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async updateNote(req: express.Request, res: express.Response): Promise<void> {
        try {
            const { id } = req.params;
            const updateData = req.body;
            const note = await this.noteService.updateNote(id, updateData);
            if (!note) {
                res.status(404).json({ error: 'Note not found' });
                return;
            }
            res.json(note);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async deleteNote(req: express.Request, res: express.Response): Promise<void> {
        try {
            const { id } = req.params;
            await this.noteService.deleteNote(id);
            res.status(204).send();
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async exportNote(req: express.Request, res: express.Response): Promise<void> {
        try {
            const { id } = req.params;
            const { format } = req.body;
            const exportData = await this.noteService.exportNote(id, format);
            res.setHeader('Content-Type', this.getContentType(format));
            res.setHeader('Content-Disposition', `attachment; filename=note-${id}.${format}`);
            res.send(exportData);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async listNotes(req: express.Request, res: express.Response): Promise<void> {
        try {
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 10;
            const sort = req.query.sort as string || 'created_at';
            const notes = await this.noteService.listNotes(page, limit, sort);
            res.json(notes);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async searchNotes(req: express.Request, res: express.Response): Promise<void> {
        try {
            const { query } = req.query;
            const results = await this.noteService.searchNotes(query as string);
            res.json(results);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async listContexts(req: express.Request, res: express.Response): Promise<void> {
        try {
            const contexts = await this.noteService.listContexts();
            res.json(contexts);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async getStats(req: express.Request, res: express.Response): Promise<void> {
        try {
            const stats = await this.noteService.getStats();
            res.json(stats);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async healthCheck(req: express.Request, res: express.Response): Promise<void> {
        try {
            const health = await this.noteService.healthCheck();
            res.json(health);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    public async serveStaticFiles(req: express.Request, res: express.Response): Promise<void> {
        try {
            const { path } = req.params;
            const fileData = await this.fileServerService.getFile(path);
            if (!fileData) {
                res.status(404).send('File not found');
                return;
            }
            res.send(fileData);
        } catch (error) {
            res.status(500).json({ error: (error as Error).message });
        }
    }

    private getContentType(format: string): string {
        const mimeTypes: Record<string, string> = {
            'markdown': 'text/markdown',
            'txt': 'text/plain',
            'json': 'application/json',
            'pdf': 'application/pdf',
        };
        return mimeTypes[format] || 'application/octet-stream';
    }

    public start(port: number): void {
        this.app.listen(port, () => {
            console.log(`Notes API listening on port ${port}`);
        });
    }
}

export default NotesAPI;