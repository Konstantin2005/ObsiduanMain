# Failure Scenarios & Recovery

## Scenario 1: Ollama service unavailable
**Symptom**: AnalyzerAgent._call_llm returns None
**Handling**: Returns empty list, logs error
**Recovery**: Auto-retry on next call

## Scenario 2: SQLite file corrupted
**Symptom**: database.connect() fails
**Handling**: Exception propagates to caller
**Recovery**: User restores from backup or recreates DB

## Scenario 3: Invalid JSON from LLM
**Symptom**: ResponseParser cannot parse response
**Handling**: Returns empty list, logs warning
**Recovery**: Retry with lower temperature

## Scenario 4: Duplicate task detection miss
**Symptom**: DedupChecker has 60% Jaccard threshold
**Handling**: Slight variations may slip through
**Recovery**: Manual dedup in Nirvana

## Scenario 5: Feedback learner with 0 feedback
**Symptom**: Learner.learn_from_feedback has empty DB
**Handling**: Returns immediately (guard: len < 5)
**Recovery**: Collects more data over time

## Scenario 6: Memory search with no embeddings
**Symptom**: SearchEngine.find_similar finds nothing
**Handling**: Returns empty list
**Recovery**: Index new entries first

## Scenario 7: Nirvana Bridge unreachable
**Symptom**: NirvanaBridge.create_task fails
**Handling**: Returns False, task stays in DB
**Recovery**: Automatic retry on next cycle
