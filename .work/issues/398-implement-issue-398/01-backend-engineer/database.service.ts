// Сервис базы данных

import sqlite3 from 'sqlite3';
import { Note } from './notes.service';

export class DatabaseService {
    private db: sqlite3.Database;

    constructor() {
        this.db = new sqlite3.Database('./data/notes.db');
        this.initializeDatabase();
    }

    public async saveNote(note: Note): Promise<Note> {
        return new Promise((resolve, reject) => {
            const sql = `\n                INSERT INTO notes (id, title, content, syntax, tags, labels, path, owner, group, created_at, updated_at, status, ttl)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    content = excluded.content,
                    syntax = excluded.syntax,
                    tags = excluded.tags,
                    labels = excluded.labels,
                    path = excluded.path,
                    owner = excluded.owner,
                    group = excluded.group,
                    updated_at = excluded.updated_at,
                    status = excluded.status,
                    ttl = excluded.ttl
                RETURNING *;
            `;

            const params = [
                note.id,
                note.title,
                note.content,
                note.syntax,
                JSON.stringify(note.tags),
                JSON.stringify(note.labels),
                note.path,
                note.owner,
                note.group,
                note.created_at,
                note.updated_at,
                note.status,
                note.ttl,
            ];

            this.db.run(sql, params, function (err) {
                if (err) {
                    reject(err);
                } else {
                    resolve(note);
                }
            });
        });
    }

    public async getNote(id: string): Promise<Note | null> {
        return new Promise((resolve, reject) => {
            const sql = 'SELECT * FROM notes WHERE id = ?';
            this.db.get(sql, [id], (err, row: Note) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row || null);
                }
            });
        });
    }

    public async updateNote(id: string, data: Partial<Note>): Promise<Note | null> {
        const note = await this.getNote(id);
        if (!note) {
            throw new Error('Note not found');
        }

        const updatedNote: Note = { ...note, ...data };
        return await this.saveNote(updatedNote);
    }

    public async deleteNote(id: string): Promise<void> {
        return new Promise((resolve, reject) => {
            const sql = 'DELETE FROM notes WHERE id = ?';
            this.db.run(sql, [id], function (err) {
                if (err) {
                    reject(err);
                } else {
                    resolve();n                }
            });
        });
    }

    public async getNotes(page: number, limit: number, sort: string): Promise<{ data: Note[], page: number, limit: number, total: number, has_more: boolean }> {
        const offset = (page - 1) * limit;
        const allowedSorts = ['created_at', 'updated_at', 'title'];
        const sortField = allowedSorts.includes(sort) ? sort : 'created_at';
        const order = 'DESC';

        const countSql = 'SELECT COUNT(*) as total FROM notes';
        const dataSql = `SELECT * FROM notes ORDER BY ${sortField} ${order} LIMIT ? OFFSET ?`;n
        const total = await this.getCount(countSql);
        const notes = await this.getNotesWithParams(dataSql, [limit, offset]);

        return {
            data: notes,
            page,
            limit,
            total,
            has_more: page * limit < total,
        };
    }

    public async searchNotes(query: string): Promise<Note[]> {
        const sql = 'SELECT * FROM notes WHERE title LIKE ? OR content LIKE ?';
        const param = `%${query}%`;
        return await this.getNotesWithParams(sql, [param, param]);
    }

    public async getDistinctLabels(): Promise<string[]> {
        const sql = 'SELECT DISTINCT labels FROM notes WHERE labels != ""';
        return await this.getNotesWithParams(sql, []);
    }

    public async getStats(): Promise<Record<string, any>> {
        const stats: Record<string, any> = {};

        const totalNotesSql = 'SELECT COUNT(*) as total FROM notes';
        stats.totalNotes = await this.getCount(totalNotesSql);

        const statusSql = 'SELECT status, COUNT(*) as count FROM notes GROUP BY status';
        stats.byStatus = await this.getNotesWithParams(statusSql, []);

        const syntaxSql = 'SELECT syntax, COUNT(*) as count FROM notes GROUP BY syntax';
        stats.bySyntax = await this.getNotesWithParams(syntaxSql, []);

        return stats;
    }

    public async healthCheck(): Promise<Record<string, any>> {
        try {
            await this.getCount('SELECT 1');
            return { status: 'healthy' };
        } catch (error) {
            return { status: 'unhealthy', error: (error as Error).message };
        }
    }

    public async initializeDatabase(): void {
        const sql = `\n            CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                syntax TEXT NOT NULL,
                tags TEXT NOT NULL,
                labels TEXT NOT NULL,
                path TEXT NOT NULL,
                owner TEXT NOT NULL,
                group TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                status TEXT NOT NULL,
                ttl INTEGER
            );
            \n            CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);
            CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
            CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title);
        `;

        this.db.exec(sql, (err) => {
            if (err) {
                console.error('Error initializing database:', err);
            }
        });
    }

    private async getCount(sql: string, params: any[] = []): Promise<number> {
        return new Promise((resolve, reject) => {
            this.db.get(sql, params, (err, row: { total: number }) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row?.total || 0);
                }
            });
        });
    }

    private async getNotesWithParams(sql: string, params: any[] = []): Promise<any[]> {
        return new Promise((resolve, reject) => {
            const results: any[] = [];
            this.db.all(sql, params, (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    for (const row of rows) {
                        const note: Note = { ...row };
                        if (note.tags) {
                            note.tags = JSON.parse(note.tags);
                        }
                        if (note.labels) {
                            note.labels = JSON.parse(note.labels);
                        }
                        results.push(note);
                    }
                    resolve(results);
                }
            });
        });
    }
}

export default DatabaseService;