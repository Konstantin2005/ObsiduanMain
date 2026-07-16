# Architecture: Encoding Fix System

## Overview

A Python-based fix script that repairs double-encoding mojibake corruption in Excalidraw files.

## Corruption Pattern

```
Original UTF-8 bytes (e.g., D0 93 for Г)
    ↓
Read as CP1251 → produces wrong characters (e.g., Р + quotation marks)
    ↓
Saved as UTF-8 → creates double-encoded mojibake (e.g., D0 A0 E2 80 9C for Р")
```

## Fix Strategy

### Level 1: Byte Pattern Replacement
Direct byte-level fix for known corrupted sequences:
- `D0 B2 D1 99 C2 A0` (вљ ) → `E2 9A A0` (⚠)

### Level 2: CP1251 Roundtrip
For Russian text corruption:
1. Read corrupted text as UTF-8
2. Encode each character as CP1251 → recovers original bytes
3. Decode bytes as UTF-8 → restores original text
4. Handle non-CP1251 characters (U+0098, etc.) via Latin-1 fallback

### File Handling
- Preserve UTF-8 BOM if present
- Preserve file structure (frontmatter, text elements, drawing data)
- Only modify the Text Elements section and line 7
- Drawing data (compressed block) is ASCII-only and unaffected

## Success Criteria
1. ⚠ character correctly displayed in all Excalidraw files
2. Russian text readable in Text Elements section
3. All files remain valid UTF-8
4. No data loss in drawing data
