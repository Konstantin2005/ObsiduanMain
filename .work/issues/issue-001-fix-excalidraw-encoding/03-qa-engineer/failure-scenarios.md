# Failure Scenarios

## Scenario 1: Script encounters non-UTF-8 file
If a file is not valid UTF-8, the fix script will:
- Skip the text-level fix
- Still apply byte-level fix if possible
- Log the error

**Mitigation:** All Excalidraw files should be UTF-8. If not, manual conversion may be needed first.

## Scenario 2: False positive on clean Russian text
If clean Russian text is mistakenly identified as corrupted:
- The CP1251 roundtrip test has a 30% skip threshold
- Clean text should pass through unchanged (verified in testing)

**Mitigation:** Always run in `--dry-run` mode first. Manual verification of sample files.

## Scenario 3: Drawing data corruption
If the compressed drawing data is affected:
- The script does NOT modify the compressed data section
- The compressed data should remain intact

**Mitigation:** Verify drawing data by trying to load files in Excalidraw after fix.

## Scenario 4: Script crashes mid-operation
If the script crashes:
- Files already written will be in a partially-fixed state
- The script should be run again on the remaining files

**Mitigation:** Use `--dry-run` first, then re-run if needed. The fix is idempotent.

## Scenario 5: File permissions prevent writing
If a file can't be written:
- The script logs the error and continues to other files
- Permission fix must be done manually

## Scenario 6: Disk space issues
If disk space is low during write operations:
- Files are read, fixed in memory, and written back in-place
- Minimal disk space needed beyond original file size

## Scenario 7: Character irreversible corruption
For characters like U+0098 that can't be CP1251-encoded:
- They are kept unchanged in the output
- These are typically minor (a few characters per file)
