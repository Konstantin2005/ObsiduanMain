# Backend Engineer Data Models

## Repository Analysis Data Models

### 1. Analysis Metadata Schema
```typescript
interface RepositoryAnalysis {
    id: string;
    repositoryName: string;
    repositoryPath: string;
    totalFiles: number;
    totalDirectories: number;
    startTime: Date;
    endTime?: Date;
    status: 'pending' | 'in_progress' | 'completed' | 'failed';
    qualityScore?: number;
    metadata: {
        encoding: string;
        language: string;
        lastModified: Date;
        fileNamingPattern: string;
    };
}
```

### 2. File Information Model
```typescript
interface FileInfo {
    id: string;
    path: string;
    fileName: string;
    extension: string;
    size: number;
    relativePath: string;
    depth: number;
    isDirectory: boolean;
    metadata: {
        createdAt: Date;
        modifiedAt: Date;
        encoding: string;
        lineCount?: number;
        wordCount?: number;
        hasHeader?: boolean;
    };
}
```

### 3. Content Analysis Model
```typescript
interface ContentAnalysis {
    fileInfoId: string;
    originalContent: string;
    normalizedContent: string;
    languageDetected: 'cyrillic' | 'latin' | 'mixed';
    categories: string[];
    themes: string[];
    keywords: string[];
    entities: ContentEntity[];
    sentiment?: {
        score: number;
        classification: 'positive' | 'neutral' | 'negative';
    };
}
```

### 4. Category Classification Model
```typescript
interface CategoryClassification {
    primaryCategory: 'technical' | 'philosophical' | 'theoretical' | 'personal' | 'social';
    secondaryCategories: string[];
    confidenceScore: number;
    reasoning: string;
    evidence: {
        filePath: string;
        pattern: string;
        weight: number;
    }[];
}
```

### 5. Directory Structure Model
```typescript
interface DirectoryStructure {
    path: string;
    name: string;
    type: 'file' | 'directory';
    children: DirectoryStructure[];
    depth: number;
    metadata: {
        fileCount?: number;
        directoryCount?: number;
        totalSize?: number;
        averageFileSize?: number;
    };
}
```

### 6. Analysis Report Model
```typescript
interface AnalysisReport {
    id: string;
    analysisId: string;
    reportType: 'structure' | 'content' | 'summary' | 'recommendations';
    title: string;
    content: string;
    format: 'markdown' | 'json' | 'html';
    createdAt: Date;
    metadata: {
        wordCount: number;
        sectionCount: number;
        fileReferences: string[];
        confidenceScore: number;
    };
}
```

### 7. Error Tracking Model
```typescript
interface ProcessingError {
    id: string;
    fileInfoId?: string;
    errorType: 'encoding' | 'parse' | 'validation' | 'io' | 'business';
    message: string;
    stackTrace?: string;
    timestamp: Date;
    severity: 'low' | 'medium' | 'high' | 'critical';
    recoveryAction: string;
}
```

### 8. Performance Metrics Model
```typescript
interface PerformanceMetrics {
    processingTime: {
        total: number;
        perFile: number;
        perDirectory: number;
    };
    resourceUsage: {
        memory: {
            peak: number;
            average: number;
        };
        cpu: {
            usage: number;
            cores: number;
        };
    };
    throughput: {
        filesPerSecond: number;
        directoriesPerSecond: number;
    };
}
```

### 9. API Request/Response Models

**Request Models:**
```typescript
interface RepositoryAnalysisRequest {
    repositoryPath: string;
    options?: {
        recursive?: boolean;
        includeHidden?: boolean;
        extractContent?: boolean;
        categorizeContent?: boolean;
        generateReports?: boolean;
        maxDepth?: number;
    };
}

interface ProcessFileRequest {
    filePath: string;
    content?: string;
}
```

**Response Models:**
```typescript
interface RepositoryAnalysisResponse {
    success: boolean;
    analysis?: RepositoryAnalysis;
    files?: FileInfo[];
    directories?: DirectoryStructure[];
    errors?: ProcessingError[];
    message?: string;
}

interface ContentAnalysisResponse {
    success: boolean;
    contentAnalysis?: ContentAnalysis;
    categoryClassification?: CategoryClassification;
    processingTime: number;
    error?: string;
}
```

### 10. Database Models (SQL)

```sql
-- Main analysis table
CREATE TABLE repository_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_name VARCHAR(255) NOT NULL,
    repository_path VARCHAR(500) NOT NULL,
    total_files INTEGER NOT NULL,
    total_directories INTEGER NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    quality_score DECIMAL(3,2),
    metadata JSONB,
    performance_metrics JSONB
);

-- File information table
CREATE TABLE file_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id UUID REFERENCES repository_analysis(id) ON DELETE CASCADE,
    path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    extension VARCHAR(50) NOT NULL,
    size BIGINT NOT NULL,
    relative_path VARCHAR(500) NOT NULL,
    depth INTEGER NOT NULL,
    is_directory BOOLEAN NOT NULL,
    metadata JSONB,
    UNIQUE(path)
);

-- Content analysis table
CREATE TABLE content_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_info_id UUID REFERENCES file_info(id) ON DELETE CASCADE,
    original_content TEXT,
    normalized_content TEXT,
    language_detected VARCHAR(20),
    categories JSONB,
    themes JSONB,
    keywords JSONB,
    sentiment JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Processing errors table
CREATE TABLE processing_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_info_id UUID REFERENCES file_info(id) ON DELETE CASCADE,
    error_type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    severity VARCHAR(20) NOT NULL,
    recovery_action TEXT
);
```

### 11. Validation Schemas

**File Validation Rules:**
```typescript
const fileValidationSchema = {
    path: { required: true, maxLength: 500 },
    fileName: { required: true, maxLength: 255 },
    extension: { required: true, pattern: /^[a-zA-Z0-9]+$/ },
    size: { required: true, min: 0 },
    isDirectory: { required: true }
};

const contentValidationSchema = {
    originalContent: { required: true, maxLength: 1000000 }, // 1MB limit
    languageDetected: { required: true, enum: ['cyrillic', 'latin', 'mixed'] },
    categories: { required: true, minItems: 1 },
    themes: { required: true, maxItems: 10 }
};
```

### 12. Configuration Models

**Application Configuration:**
```typescript
interface AppConfig {
    analysis: {
        maxFileSize: number;
        maxDepth: number;
        supportedExtensions: string[];
        languageDetection: {
            cyrillicThreshold: number;
            latinThreshold: number;
        };
    };
    processing: {
        parallelWorkers: number;
        timeoutPerFile: number;
        retryAttempts: number;
    };
    storage: {
        databaseUrl: string;
        cacheEnabled: boolean;
    };
}
```

This comprehensive data modeling implementation provides a solid foundation for the repository analysis system, ensuring data consistency, validation, and scalability across the multi-agent pipeline.