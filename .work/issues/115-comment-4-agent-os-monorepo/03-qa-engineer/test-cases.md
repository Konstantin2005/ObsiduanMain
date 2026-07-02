# QA: Loop Safety & Isolation

| TC | Name | Expected | Status |
|----|------|----------|--------|
| 1 | orchestration/ excluded from index | .opencodeignore contains orchestration/ | ✅ |
| 2 | No cross-import between runtime modules | Bridge is only integration point | ✅ |
| 3 | No watcher loop | orchestration/ is read-only, no fs.watch | ✅ |
| 4 | No re-index storm | Runtime data dirs excluded from index | ✅ |
| 5 | No recursive file trigger | bridge/lifecycle.js doesn't write to indexed dirs | ✅ |
| 6 | telemetry + task-queue data excluded | data/, logs/, *.jsonl in .opencodeignore | ✅ |
