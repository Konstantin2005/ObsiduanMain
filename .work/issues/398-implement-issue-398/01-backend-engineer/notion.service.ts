// Сервис интеграции с Notion

import { Notion } from 'notion-sdk';

export interface NotionConfig {
    apiKey: string;
    databaseId: string;
}

export interface NotionPage {
    id: string;
    title: string;
    properties: Record<string, any>;
    created_time: string;
    last_edited_time: string;
}

export class NotionService {
    private notion: Notion;
    private config: NotionConfig;

    constructor(config: NotionConfig) {
        this.notion = new Notion({ auth: config.apiKey });
        this.config = config;
    }

    public async createPage(properties: Record<string, any>): Promise<NotionPage> {
        const page = await this.notion.pages.create({
            parent: { database_id: this.config.databaseId },
            properties: properties,
        });
        return page as NotionPage;
    }

    public async updatePage(pageId: string, properties: Record<string, any>): Promise<NotionPage> {
        const page = await this.notion.pages.update({
            page_id: pageId,
            properties: properties,
        });
        return page as NotionPage;
    }

    public async getPage(pageId: string): Promise<NotionPage> {
        return await this.notion.pages.retrieve({ page_id: pageId }) as NotionPage;
    }

    public async queryPages(filter: any, sort?: any): Promise<NotionPage[]> {
        const response = await this.notion.databases.query({
            database_id: this.config.databaseId,
            filter: filter,
            sort: sort,
        });
        return response.results as NotionPage[];
    }

    public async syncNoteToNotion(note: any): Promise<void> {
        const properties = {
            title: [
                {
                    type: 'title',
                    title: [
                        {
                            type: 'text',
                            text: {
                                content: note.title,
                                link: null,
                            },
                        },
                    ],
                },
            ],
            'Content': [
                {
                    type: 'rich_text',
                    rich_text: [
                        {
                            type: 'text',
                            text: {
                                content: note.content,
                                link: null,
                            },
                        },
                    ],
                },
            ],
            'Syntax': [
                {
                    type: 'select',
                    select: {
                        name: note.syntax,
                    },
                },
            ],
            'Tags': [
                {
                    type: 'multi_select',
                    multi_select: note.tags.map((tag: string) => ({ name: tag })),
                },
            ],
            'Labels': [
                {
                    type: 'multi_select',
                    multi_select: note.labels.map((label: string) => ({ name: label })),
                },
            ],
        };

        if (note.id) {
            await this.updatePage(note.id, properties);
        } else {
            await this.createPage(properties);
        }
    }

    public async healthCheck(): Promise<Record<string, any>> {
        try {
            await this.notion.users.me();
            return { status: 'healthy' };
        } catch (error) {
            return { status: 'unhealthy', error: (error as Error).message };
        }
    }
}

export default NotionService;