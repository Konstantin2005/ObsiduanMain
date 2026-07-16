# Edge Cases: Excalidraw Encoding Fix

## Edge Case 1: Files with no Text Elements section
Some Excalidraw files may be empty or have no text elements. The fix should handle these gracefully.

**Status:** Handled - the fix only processes the section between `## Text Elements` and `## Drawing`.

## Edge Case 2: Files with mixed encoding (correct + corrupted text)
Files like `Доска задачи.md` had correct ⚠ but might have had corrupted text.

**Status:** Handled - the targeted CP1251 roundtrip only affects text that shows the mojibake pattern. Clean text is detected via the 30% skip threshold.

## Edge Case 3: Non-Excalidraw .md files
There are .md files in the Excalidraw directory that are not Excalidraw drawings (e.g., Scripts).

**Status:** Handled - files are filtered by checking for `excalidraw` in the first 500 bytes.

## Edge Case 4: Files without BOM (UTF-8 without signature)
Some files might not have the UTF-8 BOM.

**Status:** Handled - BOM is preserved if present. The fix works with or without BOM.

## Edge Case 5: Characters outside CP1251 range
The corrupted text contains characters like U+0098 that can't be CP1251-encoded.

**Status:** Handled - these characters are skipped during CP1251 roundtrip and kept as-is.

## Edge Case 6: Filename encoding corruption
The file `Deltaав.md` has what appears to be filename encoding corruption.

**Status:** Not handled - filenames are not modified by this fix. Only file CONTENTS are fixed.

## Edge Case 7: Compressed drawing data with border corruption
The drawing data between ``` markers is ASCII-only and should be unaffected.

**Status:** Verified - the compressed data section was not modified.
