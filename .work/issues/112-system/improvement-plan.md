# Improvement Plan

## P0 — Critical (must fix before production)

### P0-1: Input Sanitization
**Problem:** Issue title/body не санитизируются → path traversal, XSS, prompt injection
**Fix:** Добавить sanitization step в workflow
**Complexity:** Low
**Impact:** High

### P0-2: JSON Schema Validation
**Problem:** AI output не валидируется → hallucinated paths, invalid files
**Fix:** validate-output.js должен запускаться перед записью
**Complexity:** Low
**Impact:** High

### P0-3: Path Whitelist
**Problem:** AI может записать файл в любую папку
**Fix:** Проверять что path начинается с `.work/issues/<id>-<slug>/`
**Complexity:** Low
**Impact:** High

### P0-4: Idempotency
**Problem:** Rerun создаёт duplicate files, branch collision
**Fix:** Проверять существование branch/PR перед созданием
**Complexity:** Low
**Impact:** High

### P0-5: Prompt Injection Guard
**Problem:** Issue body может переопределить system prompt
**Fix:** Разделить system prompt и user input, sanitize input
**Complexity:** Medium
**Impact:** Critical

## P1 — Important

### P1-1: OpenAI Retry
3 retries с exponential backoff при API failure

### P1-2: GitHub API Retry
3 retries при gh pr create failure

### P1-3: Branch Collision
Force push при существующей ветке (с осторожностью)

### P1-4: Slug Uniqueness
Append hash при коллизии slug

### P1-5: Size Limits
Max 10KB для issue body, max 200 chars для title

## P2 — Nice to Have

### P2-1: Log Aggregation
Collect logs from all runs in single file

### P2-2: Cost Tracking
Log OpenAI token usage per run

### P2-3: Dry-Run Mode
Preview AI output without writing files

### P2-4: Rollback
Ability to revert PR if AI output is bad

### P2-5: Agent Isolation
File permission checks per role directory
