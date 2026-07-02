export interface LogEntry {
    timestamp: string;
    action: string;
    data: any;
    reasoning?: string;
}

export interface Role {
    name: string;
    logFile: string;
}

export interface ArchitectRole extends Role {
    name: 'architect';
    planPath: string;
    architecturePath: string;
    decisionsPath: string;
}

export interface BackendRole extends Role {
    name: 'backend';
    apiPath: string;
    notesPath: string;
    parserPath: string;
    databasePath: string;
    fileServerPath: string;
    notionPath: string;
}

export interface FrontendRole extends Role {
    name: 'frontend';
    componentsPath: string;
    uiPath: string;
}

export interface QARole extends Role {
    name: 'qa';
    testsPath: string;
    edgeCasesPath: string;
    failuresPath: string;
    validationPath: string;
}

export interface ReviewerRole extends Role {
    name: 'reviewer';
    reviewPath: string;
}

export interface SharedMemory {
    contextPath: string;
    architecturePath: string;
    decisionsLogPath: string;
}

export const Roles = {
    architect: {
        name: 'architect',
        logFile: 'architect.log',
        planPath: '.work/issues/398-implement-issue-398/00-architect/plan.md',
        architecturePath: '.work/issues/398-implement-issue-398/00-architect/architecture.md',
        decisionsPath: '.work/issues/398-implement-issue-398/00-architect/decisions.md',
    },
    backend: {
        name: 'backend',
        logFile: 'backend.log',
        apiPath: '.work/issues/398-implement-issue-398/01-backend-engineer/api.ts',
        notesPath: '.work/issues/398-implement-issue-398/01-backend-engineer/notes.service.ts',
        parserPath: '.work/issues/398-implement-issue-398/01-backend-engineer/parser.service.ts',
        databasePath: '.work/issues/398-implement-issue-398/01-backend-engineer/database.service.ts',
        fileServerPath: '.work/issues/398-implement-issue-398/01-backend-engineer/file-server.service.ts',
        notionPath: '.work/issues/398-implement-issue-398/01-backend-engineer/notion.service.ts',
    },
    frontend: {
        name: 'frontend',
        logFile: 'frontend.log',
        componentsPath: '.work/issues/398-implement-issue-398/02-frontend-engineer/components',
        uiPath: '.work/issues/398-implement-issue-398/02-frontend-engineer/ui-components',
    },
    qa: {
        name: 'qa',
        logFile: 'qa.log',
        testsPath: '.work/issues/398-implement-issue-398/03-qa-engineer/test-cases.md',
        edgeCasesPath: '.work/issues/398-implement-issue-398/03-qa-engineer/edge-cases.md',
        failuresPath: '.work/issues/398-implement-issue-398/03-qa-engineer/failure-scenarios.md',
        validationPath: '.work/issues/398-implement-issue-398/03-qa-engineer/validation-rules.md',
    },
    reviewer: {
        name: 'reviewer',
        logFile: 'reviewer.log',
        reviewPath: '.work/issues/398-implement-issue-398/04-code-reviewer/review.md',
    },
};

export const SharedMemory = {
    contextPath: '.work/issues/398-implement-issue-398/shared/context.md',
    architecturePath: '.work/issues/398-implement-issue-398/shared/architecture.md',
    decisionsLogPath: '.work/issues/398-implement-issue-398/shared/decisions-log.md',
};

export const RolesDistribution = {
    architect: async () => {},
    backend: async () => {},
    frontend: async () => {},
    qa: async () => {},
    reviewer: async () => {},
};