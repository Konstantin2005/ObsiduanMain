# Notes: System Audit

## Методология
- Staff Engineer level analysis
- SRE reliability-first mindset
- Security Engineer — assume attack
- Distributed Systems Architect lens

## Ключевые находки
1. **AI Orchestration:** JSON parsing без schema validation, нет retry при OpenAI failure
2. **GitHub Pipeline:** нет idempotency при rerun, branch collision risk
3. **Filesystem:** path traversal возможен через slug, partial writes
4. **Multi-agent:** agent isolation только convention-based, нет enforcement
5. **Observability:** logs пишутся но не агрегируются, нет traceability
