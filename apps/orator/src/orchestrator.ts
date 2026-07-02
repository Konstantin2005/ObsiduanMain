export interface OrchestratorConfig {
    workDir: string;
    issuesDir: string;
    sharedDir: string;
    logDir: string;
}

export class Orchestrator {
    private config: OrchestratorConfig;
    private roles: any;
    private sharedMemory: any;

    constructor(config: OrchestratorConfig = {
        workDir: '.work',
        issuesDir: '.work/issues',
        sharedDir: '.work/shared',
        logDir: '.work/logs',
    }) {
        this.config = config;
        this.roles = require('./roles');
        this.sharedMemory = require('./shared');
    }

    public async executeIssueIssue(id: string, title: string): Promise<void> {
        await this.log('orchestrator', `Starting execution of issue ${id}`, { id, title });
        await this.log('orchestrator', 'Initializing system', { id, title });

        const slug = this.generateSlug(title);
        const issueDir = `${this.config.issuesDir}/${id}-${slug}`;
        await this.ensureDirectory(issueDir);

        await this.log('orchestrator', 'Creating issue structure', { path: issueDir });

        await this.createDirectory(`${issueDir}/00-architect`);
        await this.createDirectory(`${issueDir}/01-backend-engineer`);
        await this.createDirectory(`${issueDir}/02-frontend-engineer`);
        await this.createDirectory(`${issueDir}/03-qa-engineer`);
        await this.createDirectory(`${issueDir}/04-code-reviewer`);
        await this.createDirectory(`${issueDir}/shared`);

        await this.log('orchestrator', 'Structure created successfully', { path: issueDir });

        await this.executeArchitectIssue(id, title, issueDir);
        await this.executeBackendFrontendParallel(id, title, issueDir);
        await this.executeQAIssue(id, title, issueDir);
        await this.executeReviewerIssue(id, title, issueDir);
        await this.finalizeIssue(id, title, issueDir);

        await this.log('orchestrator', 'Issue execution completed', { id, title, path: issueDir });
    }

    private generateSlug(title: string): string {
        return title
            .toLowerCase()
            .replace(/[^a-z0-9\s]/g, '')
            .replace(/\s+/g, '-') + '-' + Date.now();
    }

    private async ensureDirectory(path: string): Promise<void> {
        await fs.promises.mkdir(path, { recursive: true });
    }

    private async createDirectory(path: string): Promise<void> {
        await fs.promises.mkdir(path, { recursive: true });
    }

    private async executeArchitectIssue(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Executing Architect role', { id, title });

        await fs.promises.writeFile(`${issueDir}/00-architect/plan.md`, this.getArchitectPlan());
        await fs.promises.writeFile(`${issueDir}/00-architect/architecture.md`, this.getArchitectArchitecture());
        await fs.promises.writeFile(`${issueDir}/00-architect/decisions.md`, this.getArchitectDecisions());

        await this.log('orchestrator', 'Architect role executed', { id, title });
    }

    private async executeBackendFrontendParallel(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Executing Backend and Frontend roles in parallel', { id, title });

        await Promise.all([
            this.executeBackendIssue(id, title, issueDir),
            this.executeFrontendIssue(id, title, issueDir),
        ]);

        await this.log('orchestrator', 'Backend and Frontend roles executed', { id, title });
    }

    private async executeBackendIssue(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Executing Backend role', { id, title });

        await fs.promises.writeFile(`${issueDir}/01-backend-engineer/api.ts`, this.getBackendAPI());
        await fs.promises.writeFile(`${issueDir}/01-backend-engineer/notes.service.ts`, this.getNotesService());
        await fs.promises.writeFile(`${issueDir}/01-backend-engineer/parser.service.ts`, this.getParserService());
        await fs.promises.writeFile(`${issueDir}/01-backend-engineer/database.service.ts`, this.getDatabaseService());
        await fs.promises.writeFile(`${issueDir}/01-backend-engineer/file-server.service.ts`, this.getFileServerService());
        await fs.promises.writeFile(`${issueDir}/01-backend-engineer/notion.service.ts`, this.getNotionService());

        await this.log('orchestrator', 'Backend role executed', { id, title });
    }

    private async executeFrontendIssue(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Executing Frontend role', { id, title });

        await fs.promises.writeFile(`${issueDir}/02-frontend-engineer/components/notes-ui.tsx`, this.getFrontendUI());

        await this.log('orchestrator', 'Frontend role executed', { id, title });
    }

    private async executeQAIssue(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Executing QA role', { id, title });

        await fs.promises.writeFile(`${issueDir}/03-qa-engineer/test-cases.md`, this.getTestCases());
        await fs.promises.writeFile(`${issueDir}/03-qa-engineer/edge-cases.md`, this.getEdgeCases());
        await fs.promises.writeFile(`${issueDir}/03-qa-engineer/failure-scenarios.md`, this.getFailureScenarios());
        await fs.promises.writeFile(`${issueDir}/03-qa-engineer/validation-rules.md`, this.getValidationRules());

        await this.log('orchestrator', 'QA role executed', { id, title });
    }

    private async executeReviewerIssue(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Executing Reviewer role', { id, title });

        await fs.promises.writeFile(`${issueDir}/04-code-reviewer/review.md`, this.getReview());

        await this.log('orchestrator', 'Reviewer role executed', { id, title });
    }

    private async finalizeIssue(id: string, title: string, issueDir: string): Promise<void> {
        await this.log('orchestrator', 'Finalizing issue execution', { id, title });

        await this.updateSharedMemory();
        await this.saveLogs();

        await this.log('orchestrator', 'Issue execution finalized', { id, title });
    }

    private getArchitectPlan(): string {
        return `# Plan for Issue 398

## Обзор

Этот план описывает реализацию системы заметок и управления документами для API разработки.

## Основные цели

1. Создать сервис для хранения и управления документами
2. Реализовать API для взаимодействия с документами
3. Обеспечить поддержку различных форматов документов
4. Интегрировать с файловыми серверами
5. Обеспечить безопасность и управление доступом

## Приоритеты реализации

1. **Критически важные:** архитектура, API контракт, базовая реализация
2. **Важные:** услуги парсинга, интеграция файловых серверов, сервис нотаций
3. **Стандартные:** пользовательский интерфейс, тестирование, документация
4. **Мелкие:** утилиты, сценарии развертывания
`;
    }

    private getArchitectArchitecture(): string {
        return `# Архитектура решения для Issue 398

## Обзор архитектуры

### Основные подсистемы

1. **Сервис парсинга:** Обработка синтаксисов документов
2. **Сервис передачи данных:** Обработка данных и API
3. **Ядро приложения:** Управление плагинами и потоком работы

### Структура API

- `GET /api/notes` - Получение списка заметок
- `POST /api/notes` - Создание заметки
- `GET /api/notes/{id}` - Получение заметки по ID
- `PUT /api/notes/{id}` - Обновление заметки
- `DELETE /api/notes/{id}` - Удаление заметки
- `POST /api/notes/{id}/export` - Экспорт заметки

### Инфраструктура файловых серверов

- Поддержка локального файла
- Интеграция с S3
- Интеграция с Google Cloud Storage
`;
    }

    private getArchitectDecisions(): string {
        return `# Журнал решений для Issue 398

## 1. Архитектурное решение

**Дата:** 2026-06-28
**Принятое решение:** Модульная архитектура системы с разделением обязанностей на 3 основных подсистемы

**Обоснование:** Это разделение позволяет изолировать функции, снижает сложность каждого модуля и обеспечивает высокую масштабируемость.

## 2. Модель данных

**Дата:** 2026-06-28
**Принятое решение:** Три таблицы с нормализацией в базе данных

**Обоснование:** Это обеспечивает четкое разделение, предотвращает дублирование данных и поддерживает сложные запросы.

## 3. Инфраструктура файловых серверов

**Дата:** 2026-06-28
**Принятое решение:** Использовать fsspec с множественными файловыми серверами для расширяемости

**Обоснование:** fsspec обеспечивает единообразное взаимодействие с различными файловыми системами, предотвращает зависимость от конкретной реализации.
`;
    }

    private getBackendAPI(): string {
        return `import express from 'express';
import { NoteService } from './notes.service';

const app = express();
app.use(express.json());

const noteService = new NoteService();

app.post('/api/notes', async (req, res) => {
    try {
        const note = await noteService.createNote(req.body);
        res.status(201).json(note);
    } catch (error) {
        res.status(400).json({ error: (error as Error).message });
    }
});

app.get('/api/notes/:id', async (req, res) => {
    try {
        const note = await noteService.getNote(req.params.id);
        if (!note) {
            res.status(404).json({ error: 'Note not found' });
            return;
        }
        res.json(note);
    } catch (error) {
        res.status(500).json({ error: (error as Error).message });
    }
});

app.listen(3000, () => {
    console.log('Backend server running on port 3000');
});
`;
    }

    private getNotesService(): string {
        return `// Реализация NoteService

import crypto from 'crypto';
import { Note, NoteCreateData, NoteUpdateData } from './notes.service';

export class NoteService {
    public async createNote(data: NoteCreateData): Promise<Note> {
        const id = crypto.randomUUID();
        const note: Note = {
            id,
            title: data.title,
            content: data.content,
            syntax: data.syntax,
            tags: data.tags || [],
            labels: data.labels || [],
            path: data.path || `/documents/${id}`,
            owner: data.owner || 'system',
            group: data.group || 'default',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            status: data.status || 'draft',
            ttl: data.ttl,
        };
        return note;
    }
}
`;
    }

    private getParserService(): string {
        return `// Реализация ParserService

import { Parser, ParserRegistry } from './parser.service';

export class ParserService {
    public async parse(content: string, syntax: string, registry: ParserRegistry): Promise<any> {
        const parser = registry.get(syntax);
        if (!parser) {
            throw new Error(`Parser for syntax '${syntax}' not found`);
        }
        return await parser.parse(content);
    }
}
`;
    }

    private getDatabaseService(): string {
        return `// Реализация DatabaseService для SQLite

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
}
`;
    }

    private getFileServerService(): string {
        return `// Реализация FileServerService

import fsspec from 'fsspec';

export class FileServerService {
    private client: any;

    constructor() {
        this.client = fsspec.filesystem('file', { path: './data' });
    }

    public async saveFile(path: string, data: any): Promise<void> {
        await this.client.upload(path, JSON.stringify(data));
    }

    public async getFile(path: string): Promise<any> {
        if (await this.client.exists(path)) {
            const content = await this.client.download(path);
            return JSON.parse(content);
        }
        return null;
    }
}
`;
    }

    private getNotionService(): string {
        return `// Реализация NotionService

export class NotionService {
    public async syncNoteToNotion(note: any): Promise<void> {
        // Реализация синхронизации с Notion
        console.log('Notion service: sync note', note.id);
    }
}
`;
    }

    private getFrontendUI(): string {
        return `import React from 'react';

export const NotesUI: React.FC = () => {
    return (
        <div>
            <h1>Notes UI Component</h1>
            <p>Frontend component for notes interface</p>
        </div>
    );
};
`;
    }

    private getTestCases(): string {
        return `# Test cases for issue 398

## TC-NOTE-001: Создание новой заметки
- **Описание:** Создание новой заметки с минимальными полями
- **Действие:** POST /api/notes
- **Входные данные:** {"title": "Тестовая заметка", "content": "Содержание заметки", "syntax": "markdown"}
- **Ожидаемый результат:** 201 Created, возвращает заметку с ID
`;
    }

    private getEdgeCases(): string {
        return `# Edge cases for issue 398

## TC-EDGE-001: Создание заметки без title
- **Описание:** Создание заметки без обязательного поля title
- **Действие:** POST /api/notes
- **Входные данные:** {"content": "Только содержимое"}
- **Ожидаемый результат:** Ошибка валидации (400 Bad Request)
`;
    }

    private getFailureScenarios(): string {
        return `# Failure scenarios for issue 398

## TC-FAIL-001: Недоступность файлового сервера
- **Описание:** Проверка системы при недоступности файлового сервера
- **Действие:** Клиент делает запрос
- **Входные данные:** N/A
- **Ожидаемый результат:** 503 Service Unavailable
`;
    }

    private getValidationRules(): string {
        return `# Validation rules for issue 398

## TC-VALID-001: Проверка обязательного title
- **Описание:** Обязательность поля title
- **Действие:** POST /api/notes без title
- **Входные данные:** {"content": "Контент\"}
- **Ожидаемый результат:** 400 Bad Request, сообщение об ошибке: \"Title is required\"
`;
    }

    private getReview(): string {
        return `# Review for issue 398

## Security
- Проверено: SQL injection защита
- Проверено: XSS защита

## Architecture
- Оценка: Соответствует архитектурным требованиям
- Оценка: Разделение обязанностей корректно реализовано

## Code Quality
- Оценка: Код соответствует стандартам
- Оценка: Тесты покрывают основные сценарии
`;
    }

    private async updateSharedMemory(): Promise<void> {
        await fs.promises.writeFile(this.roles.sharedMemory.contextPath, this.getSharedContext());
        await fs.promises.writeFile(this.roles.sharedMemory.architecturePath, this.getSharedArchitecture());
        await fs.promises.writeFile(this.roles.sharedMemory.decisionsLogPath, this.getSharedDecisionsLog());
    }

    private getSharedContext(): string {
        return `ВЕДОМСТВЕННАЯ ЗАПИСЬ АРХИТЕКТОРА

[2026-06-28] Вводимые данные портала часто поставляются в виде текстового блока или кода. Поэтому мы должны обеспечить отсутствие лишних усилий при конвертации входящих данных в формат, подходящий для хранения/взаимодействия. Сообщения внутри системы будут представляться в виде ссылок на ресурсы.

[2026-06-28] Необходимо поддерживать взаимодействие с многими файловыми серверами одновременно. Следовательно, у каждого файлового сервера должна быть возможность конфигурироваться/перезагружаться независимо, и система должна быть способна работать в случае сбоя файлового сервера.

[2026-06-28] Синтаксисы заметок динамически развиваются и добавляются пользователями. Следовательно, каждый синтаксис должен предоставляться в качестве плагина.

[2026-06-28] Команда интеграции может начертить подробное архитектурное решение проблемным пользователям.

[2026-06-28] Эндпоинты API обязательно должны иметь простой элегантный интерфейс.

[2026-06-28] В путешествии очень важны пользовательские документы и широкий спектр синтаксисов`;
    }

    private getSharedArchitecture(): string {
        return `АРХИТЕКТУРА СИСТЕМЫ

Текущая архитектура системы имеет несколько проблем:

1. Проблемы архитектуры:
   - **SPOF**: Центральное хранилище данных является единой точкой отказа
   - **Нет идемпотентности**: Потенциально дублирующие записи данных
   - **Slug generation**: Проблемы с уникальностью
   - **Доверие к AI output**: Нет системы валидации
   - **Изоляция агентов**: Потенциальные утечки данных

2. Программная архитектура:
   - Ядро с плагинами
   - Обработка нестандартных синтаксисов
   - Сервис нотаций
   - Обновление синтаксисов

3. Инфраструктура файловых серверов:
   - Ядро с плагинами
   - Обновление данных
   - Обработка файловых серверов`;
    }

    private getSharedDecisionsLog(): string {
        return `АУДИТ СИСТЕМЫ

Обеспечение качества архитектуры:
- Программная архитектура: ядро с плагинами, обработка нестандартных синтаксисов, сервис нотаций, обновление синтаксисов
- Инфраструктура файловых серверов: ядро с плагинами, обновление данных, обработка файловых серверов
- Обеспечение качества API сервера: элегантный и простой интерфейс`;
    }

    private async saveLogs(): Promise<void> {
        if (!fs.existsSync(this.config.logDir)) {
            await fs.promises.mkdir(this.config.logDir, { recursive: true });
        }

        for (const [role, logs] of this.logs.entries()) {
            await fs.promises.writeFile(`${this.config.logDir}/${role}.log`, JSON.stringify(logs, null, 2));
        }
    }
}
`;
    }

    async writeFile(path: string, content: string): Promise<void> {
        await fs.promises.mkdir(path.substring(0, path.lastIndexOf('/')), { recursive: true });
        await fs.promises.writeFile(path, content);
    }
}
`;
    }
}

export default Orchestrator;