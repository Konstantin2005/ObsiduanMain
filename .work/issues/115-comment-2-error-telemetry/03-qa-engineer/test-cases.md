# Test Cases — Error Telemetry

| TC | Name | Input | Expected | Status |
|----|------|-------|----------|--------|
| 1 | ErrorCollector buffer | capture 3 errors | buffer.length === 3 | ✅ |
| 2 | Auto-flush on maxSize | capture 51 errors | flush called, buffer empty | ✅ |
| 3 | Transport JSONL format | write batch | file contains JSONL lines | ✅ |
| 4 | ErrorLogger.wrap | wrap async fn | error captured, not swallowed | ✅ |
| 5 | ErrorLogger.handler | EventEmitter error | error captured via handler | ✅ |
| 6 | Fallback on git fail | transport throws | fallback.write called | ✅ |
| 7 | Severity levels | error / warning / critical | stored in entry.severity | ✅ |
