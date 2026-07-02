# QA: Loop & Isolation Verification

| TC | Name | Expected | Status |
|----|------|----------|--------|
| 1 | agent-core не импортирует reference | Zero imports from ai-dev-orchestration | ✅ |
| 2 | reference не импортирует runtime | No runtime deps | ✅ |
| 3 | watcher loop отсутствует | No fs.watch on output dirs | ✅ |
| 4 | re-index storm исключён | .opencodeignore excludes reference | ✅ |
| 5 | file feedback loop исключён | No write → watch → rewrite | ✅ |
