# Plan: Fix Excalidraw Encoding Corruption

## Task Breakdown

### Phase 1: Analysis ✓ (Done)
- Identify corrupted files in `Calendula/Excalidraw/`
- Determine the exact corruption pattern
- Verify the fix approach with test files

### Phase 2: Fix Implementation
1. **Byte-level fix**: Replace corrupted `⚠` byte sequence (D0 B2 D1 99 C2 A0) with original (E2 9A A0)
2. **Text-level fix**: For files with Russian text corruption:
   - Read file as UTF-8 (corrupted text)
   - Encode as CP1251 to recover original UTF-8 bytes
   - Decode as UTF-8 to get correct characters
   - Handle edge cases (non-CP1251-encodable characters)

### Phase 3: Verification
1. Verify all corrupted byte patterns are fixed
2. Verify Russian text is readable
3. Verify Excalidraw files still render correctly
4. Verify no data loss in compressed drawing data

### Phase 4: QA & Review
1. Create test cases
2. Document edge cases
3. Code review
