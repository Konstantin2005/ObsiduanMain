// Сервис парсинга для синтаксисов

import { Note } from './notes.service';

export interface Parser {
    parse(content: string): Promise<Record<string, any>>;
    transform(parsed: Record<string, any>): Promise<Partial<Note>>;
}

export interface ParserRegistry {
    register(name: string, parser: Parser): void;
    get(name: string): Parser | null;
    list(): string[];
}

export class TemplateParser implements Parser {
    public async parse(content: string): Promise<Record<string, any>> {
        const lines = content.split('\n');
        const result: Record<string, any> = {};
        
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed.startsWith('# ')) {
                result.title = trimmed.substring(2);
            } else if (trimmed.startsWith('## ')) {
                result.subtitle = trimmed.substring(3);
            } else if (trimmed.startsWith('- ') && !result.title) {
                result.content = trimmed.substring(2);
            }
        }
        
        return result;
    }

    public async transform(parsed: Record<string, any>): Promise<Partial<Note>> {
        return {
            title: parsed.title || 'Untitled',
            content: parsed.content || '',
            syntax: 'template',
            tags: [],
            labels: [],
        };
    }
}

export class MarkdownParser implements Parser {
    public async parse(content: string): Promise<Record<string, any>> {
        return {
            title: this.extractTitle(content),
            content: content,
            metadata: this.extractMetadata(content),
        };
    }

    public async transform(parsed: Record<string, any>): Promise<Partial<Note>> {
        return {
            title: parsed.title || 'Untitled',
            content: parsed.content,
            syntax: 'markdown',
            tags: parsed.metadata?.tags || [],
            labels: parsed.metadata?.labels || [],
        };
    }

    private extractTitle(content: string): string {
        const lines = content.split('\n');
        for (const line of lines) {
            if (line.startsWith('# ')) {
                return line.substring(2).trim();
            }
        }
        return 'Untitled';
    }

    private extractMetadata(content: string): any {
        const metadata: Record<string, any> = {};
        const lines = content.split('\n');
        
        for (const line of lines) {
            if (line.startsWith('---')) {
                continue;
            }
            if (line.includes(':')) {
                const [key, ...values] = line.split(':');
                metadata[key.trim()] = values.join(':').trim();
            }
        }
        
        return metadata;
    }
}

export class PlainTextParser implements Parser {
    public async parse(content: string): Promise<Record<string, any>> {
        return {
            title: 'Untitled',
            content: content,
        };
    }

    public async transform(parsed: Record<string, any>): Promise<Partial<Note>> {
        return {
            title: parsed.title || 'Untitled',
            content: parsed.content || '',
            syntax: 'plain_text',
            tags: [],
            labels: [],
        };
    }
}

export class ParserEngine {
    private parsers: Map<string, Parser> = new Map();
    private registry: ParserRegistry;

    constructor(registry: ParserRegistry) {
        this.registry = registry;
        this.initializeDefaultParsers();
    }

    public async parse(content: string, syntax: string): Promise<Record<string, any>> {
        const parser = this.registry.get(syntax);
        if (!parser) {
            throw new Error(`Parser for syntax '${syntax}' not found`);
        }
        return await parser.parse(content);
    }

    public async transform(content: string, syntax: string): Promise<Partial<Note>> {
        const parsed = await this.parse(content, syntax);
        const parser = this.registry.get(syntax);
        if (!parser) {
            throw new Error(`Parser for syntax '${syntax}' not found`);
        }
        return await parser.transform(parsed);
    }

    private initializeDefaultParsers(): void {
        this.registry.register('template', new TemplateParser());
        this.registry.register('markdown', new MarkdownParser());
        this.registry.register('plain_text', new PlainTextParser());
    }
}

export default ParserEngine;