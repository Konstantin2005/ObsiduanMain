# Architecture (Final)

## Fix Pipeline

```
Scan Excalidraw .md files (39 total)
    ↓
Identify corrupted files (18 with ⚠ corruption, 18 with text corruption)
    ↓
For each file:
    1. Read as bytes
    2. Byte-level fix: D0 B2 D1 99 C2 A0 → E2 9A A0 (⚠ fix)
    3. Decode as UTF-8
    4. Parse into lines, identify "## Text Elements" section
    5. For each text line in that section:
       - If contains non-ASCII chars:
         - Try CP1251 roundtrip (encode each char as CP1251, decode as UTF-8)
         - If >30% chars can't be CP1251-encoded → text is clean, keep unchanged
         - Otherwise → apply fixed text
    6. Reconstruct file, validate UTF-8, write
    ↓
Verify all files (0 corrupted patterns, readible Russian text)
```

## Results
- ✅ 18 files fixed (⚠ + Russian text)
- ✅ 21 files unchanged
- ✅ 0 errors
- ✅ All files valid UTF-8
- ✅ No drawing data affected
