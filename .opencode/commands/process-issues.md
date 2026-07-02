# Process Open Issues

Processes open GitHub issues through the multi-agent pipeline.

## Usage

```
/process-issues [limit=N] [start=N]
```

- `limit=N` — maximum number of issues to process (default: all open issues)
- `start=N` — start from issue number N (useful for resuming)

## Pipeline

### Step 1: List Open Issues
```bash
gh issue list --state open --json number,title,body --limit {limit}
```

### Step 2: For each open issue

#### 2a. Generate Slug
Derive a URL-safe slug from the issue title:
- Lowercase the title
- Replace non-alphanumeric characters with hyphens
- Collapse consecutive hyphens
- Trim leading/trailing hyphens

#### 2b. Create Directory Structure
```
.work/issues/{ID}-{SLUG}/
├── 00-architect/
├── 01-backend-engineer/
├── 02-frontend-engineer/
├── 03-qa-engineer/
├── 04-code-reviewer/
├── shared/
│   ├── context.md
│   ├── architecture.md
│   └── decisions-log.md
└── logs/
    ├── orchestrator.log
    ├── architect.log
    ├── backend.log
    ├── frontend.log
    ├── qa.log
    └── reviewer.log
```

#### 2c. Read Issue Body
```bash
gh issue view {ID} --json title,body,labels,assignees
```

#### 2d. Create shared/context.md
Write issue title, body, labels, and assignee info into `shared/context.md`.

#### 2e. Initiate orchestrator.log
Write a timestamped entry: `[DATE TIME UTC] Starting pipeline for issue #{ID}: {TITLE}`

#### 2f. Run the Orchestrator Agent
Load the orchestrator agent to process the issue through the full pipeline:
1. Architect creates plan.md, architecture.md, decisions.md
2. Backend Engineer + Frontend Engineer run in parallel
3. QA Engineer creates test cases and edge cases
4. Code Reviewer performs review and security audit

### Step 3: Create Tracking Issues

For each pipeline step, create a tracking issue on GitHub:

```
gh issue create \
  --title "[{STEP}] #{ID}: {TITLE}" \
  --label "tracking,orchestrator" \
  --body "Tracking issue for **{STEP}** step of issue #{ID}: {TITLE}.\\n\\nParent issue: #{ID}\\nWork directory: .work/issues/{ID}-{SLUG}/"
```

Create tracking issues for:
- Architect
- Backend Engineer
- Frontend Engineer
- QA Engineer
- Code Reviewer

### Step 4: Post Summary Comment

When all pipeline steps are complete, post a summary on the original issue:

```bash
gh issue comment {ID} --body "# Pipeline Complete 🚀\\n\\n## Summary\\n- **Issue:** #{ID}: {TITLE}\\n- **Work Directory:** .work/issues/{ID}-{SLUG}/\\n- **Tracking Issues:**\\n  - Architect: #{ARCH_ID}\\n  - Backend Engineer: #{BACKEND_ID}\\n  - Frontend Engineer: #{FRONTEND_ID}\\n  - QA Engineer: #{QA_ID}\\n  - Code Reviewer: #{REVIEWER_ID}\\n\\n## Logs\\nAll logs available in .work/issues/{ID}-{SLUG}/logs/\\n\\n## Status\\n✅ Pipeline execution complete."
```

## State Management

- After processing, update `shared/context.md` with status `DONE`
- Append completion entry to `orchestrator.log`
- Update `.shared/decisions-log.md` with final decisions
