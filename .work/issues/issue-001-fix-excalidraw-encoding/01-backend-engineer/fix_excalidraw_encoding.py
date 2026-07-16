#!/usr/bin/env python3
"""
Fix encoding corruption in Excalidraw .md files.

The files suffered CP1251 double-encoding mojibake:
1. Original UTF-8 bytes were incorrectly read as CP1251 (Windows Cyrillic)
2. The resulting wrong characters were saved as UTF-8

Fix approach:
- Byte-level replacement for known corrupted byte patterns (⚠ symbol)
- Targeted CP1251 roundtrip for the Text Elements section only
- Leaves clean Russian text and ASCII-only sections unchanged
"""

import os
import sys
import re

# ─── Configuration ───────────────────────────────────────────────────────────

EXCALIDRAW_DIR = r'C:\obsidian\Main\Calendula\Excalidraw'

# Known corrupted byte patterns → correct replacements
# ⚠ (U+26A0): E2 9A A0 → corrupted to D0 B2 (в) D1 99 (љ) C2 A0 (NBSP)
CORRUPTION_MAP = {
    bytes([0xD0, 0xB2, 0xD1, 0x99, 0xC2, 0xA0]): bytes([0xE2, 0x9A, 0xA0]),
}


# ─── Core Encoding Fix ──────────────────────────────────────────────────────

def encode_char_as_cp1251_or_latin1(char):
    """Try to encode a character as CP1251, falling back to Latin-1 mapping."""
    code = ord(char)
    
    # ASCII - same in all encodings
    if code < 0x80:
        return bytes([code])
    
    # Try CP1251 first
    try:
        return char.encode('cp1251')
    except UnicodeEncodeError:
        pass
    
    # For U+0080-U+00FF, Latin-1 gives direct byte mapping
    if 0x80 <= code <= 0xFF:
        return bytes([code])
    
    # CP1251 high-range characters (bytes 0x80-0x9F)
    cp1251_mapping = {
        0x201A: 0x82, 0x0453: 0x83, 0x201E: 0x84, 0x2026: 0x85,
        0x2020: 0x86, 0x2021: 0x87, 0x20AC: 0x88, 0x2030: 0x89,
        0x0409: 0x8A, 0x2039: 0x8B, 0x040A: 0x8C, 0x040C: 0x8D,
        0x040B: 0x8E, 0x040F: 0x8F, 0x0452: 0x90, 0x2018: 0x91,
        0x2019: 0x92, 0x201C: 0x93, 0x201D: 0x94, 0x2022: 0x95,
        0x2013: 0x96, 0x2014: 0x97, 0x2122: 0x99, 0x0459: 0x9A,
        0x203A: 0x9B, 0x045A: 0x9C, 0x045C: 0x9D, 0x045B: 0x9E,
        0x045F: 0x9F, 0x00A0: 0xA0, 0x0402: 0x80, 0x0403: 0x81,
        0x2116: 0x84, 0x0401: 0xA8, 0x0451: 0xB8,
    }
    
    if code in cp1251_mapping:
        return bytes([cp1251_mapping[code]])
    
    # Character not in CP1251 - cannot process
    return None


def fix_corrupted_text(text):
    """Apply CP1251 roundtrip to fix corrupted text.
    
    Takes text that may contain CP1251 mojibake and attempts to fix it.
    If the text has too many characters that can't be CP1251-encoded (>30%),
    it's likely clean text and is returned unchanged.
    """
    # Only process text with non-ASCII characters
    if all(ord(c) < 128 for c in text):
        return text
    
    # Attempt CP1251 roundtrip
    byte_list = []
    skipped = 0
    
    for c in text:
        result = encode_char_as_cp1251_or_latin1(c)
        if result is not None:
            byte_list.extend(result)
        else:
            skipped += 1
            # Keep unchanged
            byte_list.extend(c.encode('utf-8'))
    
    # If too many characters were skipped (>30%), text is likely clean
    if skipped > 0 and skipped > len(text) * 0.3:
        return text
    
    try:
        fixed = bytes(byte_list).decode('utf-8')
        return fixed
    except UnicodeDecodeError:
        return text


def fix_text_elements_section(file_lines):
    """Fix encoding in the Text Elements section of an Excalidraw file.
    
    The Text Elements section is between '## Text Elements' and '## Drawing'
    (or the next ## heading or end of file).
    """
    result_lines = []
    in_text_elements = False
    fixes = 0
    
    for line in file_lines:
        stripped = line.strip()
        
        # Detect section boundaries
        if stripped == '## Text Elements':
            in_text_elements = True
            result_lines.append(line)
            continue
        
        if in_text_elements and stripped.startswith('## '):
            in_text_elements = False
            result_lines.append(line)
            continue
        
        if in_text_elements:
            # Only process non-empty lines in Text Elements section
            if stripped:
                fixed = fix_corrupted_text(line)
                if fixed != line:
                    fixes += 1
                result_lines.append(fixed)
            else:
                result_lines.append(line)
        else:
            result_lines.append(line)
    
    return result_lines, fixes


# ─── File Processing ────────────────────────────────────────────────────────

def fix_byte_patterns(raw_bytes):
    """Apply byte-level fix for known corruption patterns.
    
    Returns (fixed_bytes, replacement_count).
    """
    fixed = raw_bytes
    total = 0
    for corrupted, original in CORRUPTION_MAP.items():
        count = fixed.count(corrupted)
        if count > 0:
            fixed = fixed.replace(corrupted, original)
            total += count
    return fixed, total


def fix_file(filepath, dry_run=False):
    """Fix encoding in a single Excalidraw file."""
    result = {
        'path': filepath,
        'status': 'unknown',
        'byte_fixes': 0,
        'text_fixes': 0,
        'errors': [],
    }
    
    try:
        with open(filepath, 'rb') as f:
            raw = f.read()
    except Exception as e:
        result['status'] = 'error'
        result['errors'].append(f"Cannot read: {e}")
        return result
    
    # Step 1: Fix byte-level corruption (⚠ symbol)
    fixed_raw, byte_fixes = fix_byte_patterns(raw)
    result['byte_fixes'] = byte_fixes
    
    # Check if this is an Excalidraw file
    if b'excalidraw' not in fixed_raw[:500]:
        result['status'] = 'skipped'
        return result
    
    # Step 2: Fix text in Text Elements section
    try:
        text = fixed_raw.decode('utf-8')
    except UnicodeDecodeError as e:
        result['status'] = 'error'
        result['errors'].append(f"Cannot decode as UTF-8: {e}")
        return result
    
    lines = text.split('\n')
    fixed_lines, text_fixes = fix_text_elements_section(lines)
    result['text_fixes'] = text_fixes
    
    fixed_text = '\n'.join(fixed_lines)
    output_bytes = fixed_text.encode('utf-8')
    
    # Preserve BOM if present
    if raw[:3] == b'\xef\xbb\xbf' and output_bytes[:3] != b'\xef\xbb\xbf':
        output_bytes = b'\xef\xbb\xbf' + output_bytes
    
    # Determine what changed
    if byte_fixes > 0 or text_fixes > 0:
        if not dry_run:
            try:
                # Verify output is valid UTF-8
                output_bytes.decode('utf-8')
                with open(filepath, 'wb') as f:
                    f.write(output_bytes)
                
                if byte_fixes > 0 and text_fixes > 0:
                    result['status'] = 'fixed_both'
                elif byte_fixes > 0:
                    result['status'] = 'fixed_byte'
                else:
                    result['status'] = 'fixed_text'
            except Exception as e:
                result['status'] = 'error'
                result['errors'].append(f"Write failed: {e}")
        else:
            if byte_fixes > 0 and text_fixes > 0:
                result['status'] = 'would_fix_both'
            elif byte_fixes > 0:
                result['status'] = 'would_fix_byte'
            else:
                result['status'] = 'would_fix_text'
    else:
        result['status'] = 'clean'
    
    return result


def scan_directory():
    """Scan for Excalidraw files and their encoding status."""
    results = []
    
    for root, dirs, files in os.walk(EXCALIDRAW_DIR):
        for fname in files:
            if not fname.endswith('.md'):
                continue
            path = os.path.join(root, fname)
            
            with open(path, 'rb') as f:
                raw = f.read()
            
            if b'excalidraw' not in raw[:500]:
                continue
            
            corr_pattern = bytes([0xD0, 0xB2, 0xD1, 0x99, 0xC2, 0xA0])
            orig_pattern = bytes([0xE2, 0x9A, 0xA0])
            corr_count = raw.count(corr_pattern)
            orig_count = raw.count(orig_pattern)
            
            relpath = os.path.relpath(path, EXCALIDRAW_DIR)
            
            results.append({
                'relpath': relpath,
                'corrupted_patterns': corr_count,
                'original_patterns': orig_count,
                'needs_byte_fix': corr_count > 0,
            })
    
    return results


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Fix Excalidraw encoding corruption')
    parser.add_argument('--dry-run', action='store_true',
                        help='Scan without making changes')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed output')
    args = parser.parse_args()
    
    print(f"Excalidraw directory: {EXCALIDRAW_DIR}")
    print(f"Mode: {'DRY RUN (no changes)' if args.dry_run else 'LIVE FIX'}")
    print()
    
    # Scan
    print("=" * 60)
    print("SCANNING FILES")
    print("=" * 60)
    
    scan_results = scan_directory()
    
    needs_byte_fix = [r for r in scan_results if r['needs_byte_fix']]
    clean_byte = [r for r in scan_results if not r['needs_byte_fix']]
    
    print(f"\nTotal Excalidraw files: {len(scan_results)}")
    print(f"Need ⚠ fix: {len(needs_byte_fix)}")
    print(f"⚠ already correct: {len(clean_byte)}")
    
    if args.verbose:
        for r in scan_results:
            status = "⚠ CORRUPTED" if r['needs_byte_fix'] else "⚠ OK"
            corr_info = f" [{r['corrupted_patterns']} corrupted]" if r['corrupted_patterns'] > 0 else ""
            print(f"  {status}{corr_info}: {r['relpath']}")
    
    # Fix
    print()
    print("=" * 60)
    print("FIXING FILES")
    print("=" * 60)
    
    fixed_count = 0
    error_count = 0
    clean_count = 0
    detail_counts = {'fixed_both': 0, 'fixed_byte': 0, 'fixed_text': 0}
    
    for r in scan_results:
        path = os.path.join(EXCALIDRAW_DIR, r['relpath'])
        result = fix_file(path, dry_run=args.dry_run)
        
        if args.verbose:
            msg = f"  {result['status']}: {r['relpath']}"
            if result.get('errors'):
                msg += f" - {'; '.join(result['errors'])}"
            print(msg)
        
        if result['status'] in ('fixed_both', 'fixed_byte', 'fixed_text',
                                  'would_fix_both', 'would_fix_byte', 'would_fix_text'):
            fixed_count += 1
            for key in detail_counts:
                if key in result['status']:
                    detail_counts[key] += 1
        elif result['status'] == 'error':
            error_count += 1
        elif result['status'] == 'clean':
            clean_count += 1
    
    # Summary
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Fixed: {fixed_count}")
    for key, count in detail_counts.items():
        if count > 0:
            print(f"  - {key}: {count}")
    print(f"Errors: {error_count}")
    print(f"Already clean: {clean_count}")
    
    if args.dry_run:
        print(f"\nRun without --dry-run to apply changes.")
    
    return 0


if __name__ == '__main__':
    main()
