// Сервис файлового сервера для интеграции с множественными файловыми системами

import fs from 'fs';
import path from 'path';
import fsspec from 'fsspec';

export interface FileServerConfig {
    type: string;
    endpoint: string;
    bucket: string;
    region?: string;
    accessKey?: string;
    secretKey?: string;
    rootPath?: string;
}

export class FileServerService {
    private configs: FileServerConfig[];
    private clients: Map<string, fsspec.FileSystem> = new Map();

    constructor() {
        this.configs = this.loadFileServerConfigs();
        this.initializeClients();
    }

    public async saveFile(path: string, data: any): Promise<void> {
        const normalizedPath = this.normalizePath(path);
        const fileSystem = this.getFileSystemForPath(normalizedPath);
        
        if (fileSystem === null) {
            throw new Error(`No file system available for path: ${path}`);
        }
        
        await fileSystem.upload(normalizedPath, JSON.stringify(data));
    }

    public async getFile(path: string): Promise<any> {
        const normalizedPath = this.normalizePath(path);
        const fileSystem = this.getFileSystemForPath(normalizedPath);
        
        if (fileSystem === null) {
            throw new Error(`No file system available for path: ${path}`);
        }
        
        if (!await fileSystem.exists(normalizedPath)) {
            return null;
        }
        
        const content = await fileSystem.download(normalizedPath);
        return JSON.parse(content);
    }

    public async removeNoteFiles(noteId: string): Promise<void> {
        const patterns = [
            `/documents/${noteId}/*`,
            `/documents/${noteId}`,
        ];
        
        for (const pattern of patterns) {
            await this.removeFilesByPattern(pattern);
        }
    }

    public async getFileServerStats(): Promise<Record<string, any>> {
        const stats: Record<string, any> = {};
        
        for (const [name, client] of this.clients.entries()) {
            try {
                stats[name] = await client.stats();
            } catch (error) {
                stats[name] = { error: (error as Error).message };
            }
        }
        
        return stats;
    }

    public async healthCheck(): Promise<Record<string, any>> {
        const health: Record<string, any> = {};
        
        for (const [name, client] of this.clients.entries()) {
            try {
                health[name] = await client.healthCheck();
            } catch (error) {
                health[name] = { status: 'unhealthy', error: (error as Error).message };
            }
        }
        
        return health;
    }

    private loadFileServerConfigs(): FileServerConfig[] {
        const configs: FileServerConfig[] = [];
        
        if (process.env.LOCAL_STORAGE_PATH) {
            configs.push({
                type: 'local',
                endpoint: 'local',
                bucket: 'documents',
                rootPath: process.env.LOCAL_STORAGE_PATH,
            });
        }
        
        if (process.env.S3_ENDPOINT) {
            configs.push({
                type: 's3',
                endpoint: process.env.S3_ENDPOINT,
                bucket: process.env.S3_BUCKET || 'notes',
                region: process.env.S3_REGION,
                accessKey: process.env.S3_ACCESS_KEY,
                secretKey: process.env.S3_SECRET_KEY,
            });
        }
        
        if (process.env.GCS_BUCKET) {
            configs.push({
                type: 'gcs',
                endpoint: 'https://storage.googleapis.com',
                bucket: process.env.GCS_BUCKET,
                region: process.env.GCS_REGION,
            });
        }
        
        if (configs.length === 0) {
            configs.push({
                type: 'local',
                endpoint: 'local',
                bucket: 'notes',
                rootPath: './data',
            });
        }
        
        return configs;
    }

    private initializeClients(): void {
        for (const config of this.configs) {
            const client = this.createFileSystemClient(config);
            if (client) {
                this.clients.set(config.type, client);
            }
        }
    }

    private createFileSystemClient(config: FileServerConfig): fsspec.FileSystem | null {
        switch (config.type) {
            case 'local':
                return fsspec.filesystem('file', { path: config.rootPath || './data' });
            case 's3':
                return fsspec.filesystem('s3', {
                    key: config.accessKey,
                    secret: config.secretKey,
                    client_kwargs: {
                        region_name: config.region,
                    },
                });
            case 'gcs':
                return fsspec.filesystem('gcs', {
                    project: config.region,
                });
            default:
                return null;
        }
    }

    private getFileSystemForPath(filePath: string): fsspec.FileSystem | null {
        for (const [name, client] of this.clients.entries()) {
            if (client.exists && client.exists(filePath)) {
                return client;
            }
        }
        return null;
    }

    private normalizePath(filePath: string): string {
        if (filePath.startsWith('/')) {
            return filePath.substring(1);
        }
        return filePath;
    }

    private async removeFilesByPattern(pattern: string): Promise<void> {
        for (const [name, client] of this.clients.entries()) {
            if (client.exists && await client.exists(pattern)) {
                await client.rm(pattern, recursive: true);
            }
        }
    }
}

export default FileServerService;