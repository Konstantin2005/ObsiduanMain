# Validation Rules

## Content Validation
1. All Excalidraw files must be valid UTF-8
2. Line 7 must contain ⚠ (U+26A0), not corrupted characters
3. Russian text in Text Elements section must be readable
4. No mojibake patterns (Р+quote, U+0098, etc.) should remain
5. Drawing data (compressed section) must remain unchanged

## Process Validation
1. Clean files (no corruption) must remain unchanged
2. Files with only ⚠ corruption should only fix the ⚠
3. Files with text corruption should fix both ⚠ and text
4. No files should be created or deleted
5. Only `.md` files in `Calendula/Excalidraw/` should be processed

## Code Validation
1. Fix script must handle encoding errors gracefully
2. Fix script must verify output is valid UTF-8 before writing
3. Fix script must support dry-run mode
4. Fix script must log all changes
