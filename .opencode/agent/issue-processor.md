---
description: Processes a single GitHub issue through the full multi-agent pipeline. Creates work dir, runs all roles, writes logs, creates tracking issues. Use as subagent from orchestrator.
mode: subagent
permission:
  edit: allow
  bash: allow
  read: allow
  write: allow
---

# Issue Processor Agent

Processes a single GitHub issue through the full multi-agent pipeline.

## Input

- `issue_number` — GitHub issue number (required)
- `work_dir` — path to `.work/issues/{ID}-{SLUG}/` (auto-generated)

## Behavior

### 1. Read Issue from GitHub
```bash
gh issue view {issue_number} --json title,body,labels,assignees,author,createdAt,url
```

### 2. Create Work Directory Structure
Create the following hierarchy under `{work_dir}`:
```
00-architect/
01-backend-engineer/
02-frontend-engineer/
03-qa-engineer/
04-code-reviewer/
shared/
logs/
```

### 3. Initialize shared/context.md
Write initial context with:
- Issue number, title, body, labels
- Assignee information
- Pipeline status: `INITIALIZED`
- Created timestamp
- List of all pipeline steps with their status (pending)

### 4. Run Pipeline Steps

#### 4a. Architect Step
1. Read `shared/context.md` for issue context
2. Create `shared/architecture.md` with system architecture
3. Create `shared/decisions-log.md` with initial decisions
4. Create in `00-architect/`:
   - `plan.md` — detailed implementation plan based on issue
   - `architecture.md` — solution architecture with diagrams in text
   - `decisions.md` — key decisions with rationale
5. Write to `logs/architect.log` with decisions and reasoning
6. Update `shared/context.md` status: `ARCHITECT_DONE`
7. Create GitHub tracking issue for Architect step:
   ```bash
   gh issue create --title "[Architect] #{issue_number}: {title}" --label "tracking,orchestrator" --body "..."
   ```

#### 4b. Backend Engineer Step (parallel with Frontend)
1. Read `shared/context.md` and `00-architect/` deliverables
2. Implement in `01-backend-engineer/`:
   - API endpoints and routes
   - Business logic modules
   - Data models and schemas
   - Mock/seed data if appropriate
3. Write to `logs/backend.log` with all decisions
4. Update `shared/context.md` status: `BACKEND_DONE`
5. Create GitHub tracking issue for Backend step

#### 4c. Frontend Engineer Step (parallel with Backend)
1. Read `shared/context.md` and `00-architect/` deliverables
2. Implement in `02-frontend-engineer/`:
   - UI components and pages
   - State management
   - API integration layer
   - Form handling with validation
   - Loading/empty/error states
3. Write to `logs/frontend.log` with all decisions
4. Update `shared/context.md` status: `FRONTEND_DONE`
5. Create GitHub tracking issue for Frontend step

#### 4d. QA Engineer Step
1. Read all previous deliverables
2. Create in `03-qa-engineer/`:
   - `test-cases.md` — functional test cases covering all features
   - `edge-cases.md` — boundary conditions and edge scenarios
   - `failure-scenarios.md` — what happens when things go wrong
   - `validation.md` — input validation rules and business constraints
3. Write to `logs/qa.log` with reasoning
4. Update `shared/context.md` status: `QA_DONE`
5. Create GitHub tracking issue for QA step

#### 4e. Code Reviewer Step
1. Review all deliverables from all previous steps
2. Create in `04-code-reviewer/`:
   - `review.md` covering:
     - Security vulnerabilities and mitigations
     - Architecture soundness
     - Bug analysis
     - Code quality improvements
     - Production readiness checklist
3. Write to `logs/reviewer.log` with findings
4. Update `shared/context.md` status: `REVIEWER_DONE`
5. Create GitHub tracking issue for Reviewer step

### 5. Finalization

1. Update `shared/context.md` with:
   - Status: `DONE`
   - Completion timestamp
   - Summary of all steps
   - Links to tracking issues
2. Append final entry to `logs/orchestrator.log`:
   - Pipeline duration
   - Files created (summary)
   - Any issues encountered
3. Output the completion summary for the parent orchestrator

## Output

Returns JSON to the calling agent:
```json
{
  "issue_number": 1,
  "status": "DONE",
  "work_dir": ".work/issues/1-example-issue",
  "tracking_issues": {
    "architect": 10,
    "backend": 11,
    "frontend": 12,
    "qa": 13,
    "reviewer": 14
  },
  "files_created": 15,
  "duration_seconds": 120
}
```

## Error Handling

- If `gh` CLI is not authenticated, log error and abort with status `FAILED_AUTH`
- If issue does not exist, log error and abort with status `ISSUE_NOT_FOUND`
- If any step fails, set status to `FAILED_AT_{STEP}` in context.md, log the error, and continue to next step where possible
- Collect all errors in a `logs/error.log` file for post-mortem analysis
