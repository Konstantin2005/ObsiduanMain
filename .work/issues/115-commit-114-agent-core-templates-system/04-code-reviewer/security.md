# Security Review — Agent Core Standalone (#115)

| Risk | Severity | Status |
|------|----------|--------|
| No secrets in repo | ✅ LOW | No .env, no tokens in code |
| Public repo | ✅ LOW | Open source, intentional |
| CI exposes secrets | ✅ NONE | test.yml uses no secrets |
| GitHub token in Actions | ✅ N/A | Not used yet |
