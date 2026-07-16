# Architectural Decisions

## AD-1: Byte-level fix for ⚠ character
**Status**: Accepted
**Reasoning**: The ⚠ corruption follows an exact known byte pattern (D0 B2 D1 99 C2 A0 → E2 9A A0). Using direct byte replacement is simple, reliable, and avoids complex text encoding issues for this specific case.

## AD-2: CP1251 roundtrip for Russian text
**Status**: Accepted
**Reasoning**: The Russian text corruption was caused by reading UTF-8 bytes as CP1251 and re-saving as UTF-8. Reversing this (encode as CP1251, decode as UTF-8) correctly restores the original text. This approach was verified with test data (e.g., "Р"РѕРґСѓ" → "Году").

## AD-3: Non-CP1251 character handling
**Status**: Accepted
**Reasoning**: Characters like U+0098 (control char) appear in corrupted text but can't be encoded as CP1251. These represent original byte values 0x80-0x9F. Fix: encode as Latin-1 (single byte), combine with adjacent CP1251-encoded bytes, decode as UTF-8.

## AD-4: Python as implementation language
**Status**: Accepted
**Reasoning**: Python has robust Unicode support, clear string/byte handling, and is available on the system. Better than PowerShell for complex encoding operations.

## AD-5: ⚠ fix before text fix
**Status**: Accepted
**Reasoning**: The ⚠ character (U+26A0) can't be encoded as CP1251, so it would interfere with the CP1251 roundtrip. Fix it first at the byte level, then process the rest.

## Alternatives Considered

1. **Full file conversion without filtering**: Rejected because non-CP1251 characters cause errors.
2. **PowerShell-only solution**: Rejected because PowerShell's encoding handling is less reliable for this case.
3. **Manual editing**: Rejected - too many files (18) to fix manually.
4. **Third-party encoding fix tools**: Rejected - need a targeted solution for this specific corruption pattern.
