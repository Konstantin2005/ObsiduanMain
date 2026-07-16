# Context

**Issue**: Encoding corruption in Excalidraw boards
**Status**: DONE
**Created**: 2026-07-16
**Completed**: 2026-07-16

## Problem
Excalidraw `.md` files in `Calendula/Excalidraw/` had CP1251 double-encoding mojibake:
1. The `⚠` (U+26A0) character in line 7 was corrupted to `вљ ` 
2. Russian text in the "Text Elements" section was corrupted

## Root Cause
UTF-8 bytes were incorrectly read as CP1251 (Windows Cyrillic), producing wrong characters, which were then saved as UTF-8.

## Fix Applied
- ⚠ fixed via byte-level replacement (18 files)
- Russian text fixed via targeted CP1251 roundtrip (18 files)
- 21 clean files verified unchanged
- Fix script: `01-backend-engineer/fix_excalidraw_encoding.py`

## Remaining Known Issues
- Filename `Deltaав.md` may have encoding corruption in the filename itself (content is fixed)
- 2 script files in `Scripts/Downloaded/` don't use standard Excalidraw format
