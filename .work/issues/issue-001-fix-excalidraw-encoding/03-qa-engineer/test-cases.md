# Test Cases: Excalidraw Encoding Fix

## Test Case 1: Verify ⚠ character in line 7
**Steps:**
1. Open any fixed Excalidraw file
2. Go to line 7
3. Check the warning sign before "Switch to EXCALIDRAW VIEW"

**Expected:** `⚠` (U+26A0), not `вљ ` (corrupted)

**Verification command:**
```python
python -c "
with open(path, 'rb') as f:
    raw = f.read()
print(raw.count(bytes([0xE2,0x9A,0xA0])))  # Should be 2
print(raw.count(bytes([0xD0,0xB2,0xD1,0x99,0xC2,0xA0])))  # Should be 0
"
```

## Test Case 2: Verify Russian text in Text Elements
**Steps:**
1. Open План.md
2. Check line with "Контролировать только то что могу контролировать"
3. Check line with "1 Году"

**Expected:** Readable Russian text, no mojibake characters

## Test Case 3: Verify clean files unchanged
**Steps:**
1. Open GTD.md
2. Check Russian text: "Задача", "Что это", "Мусор", "Заметка"

**Expected:** Clean Russian text unchanged

## Test Case 4: Verify file is valid UTF-8
**Steps:**
1. Try to decode each fixed file as UTF-8

**Expected:** All files decode successfully without errors

## Test Case 5: Verify drawing data integrity
**Steps:**
1. Check compressed drawing data section (between ``` markers)
2. Verify it's still ASCII-only

**Expected:** Drawing data unchanged, pure ASCII
