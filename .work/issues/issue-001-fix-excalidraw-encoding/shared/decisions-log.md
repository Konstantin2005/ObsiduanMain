# Decisions Log

## 2026-07-16

| Decision | Reasoning | Alternatives |
|----------|-----------|--------------|
| Byte-level fix for ⚠ | Exact pattern match, simple, reliable | Manual editing (too many files) |
| CP1251 roundtrip for Russian text | Reverses the known corruption mechanism | Third-party tools (not targeted) |
| Non-CP1251 chars via Latin-1 fallback | Handles edge cases (U+0098) | Skipping chars (data loss) |
| Python implementation | Best Unicode support | PowerShell (less reliable) |
| ⚠ fix before text fix | U+26A0 can't be CP1251-encoded | Would cause errors in roundtrip |
