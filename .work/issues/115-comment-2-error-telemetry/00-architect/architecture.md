# Architecture: Error Telemetry

## Компоненты

### 1. ErrorCollector (buffer queue)
- Принимает ошибки от всех компонентов
- Буферизирует до 50 записей
- Flush каждые 5 секунд
- Async, non-blocking

### 2. Transport (git writer)
- Пишет JSONL файлы
- git add → commit → push
- Retry 3 раза если push fails
- Fallback на локальный файл

### 3. try/catch wrappers
- Каждый агент обёрнут в try/catch
- Pipeline имеет onError hook
- TemplateEngine имеет error handler

### 4. error-telemetry repo
- /logs/YYYY-MM-DD/agent-errors.jsonl
- /logs/YYYY-MM-DD/pipeline-failures.jsonl
- /logs/YYYY-MM-DD/system-warnings.jsonl

## Log Entry Format
```json
{
  "timestamp": "2026-06-26T15:00:00.000Z",
  "source": "agent.architect",
  "error_type": "ValidationError",
  "message": "Invalid plan format",
  "stack": "...",
  "context": { "issueId": 115 },
  "severity": "error"
}
```
