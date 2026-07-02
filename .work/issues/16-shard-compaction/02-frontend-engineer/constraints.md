# Constraints — Shard Compaction

## Safety guarantees
| Guarantee | Mechanism |
|-----------|-----------|
| No data loss | graph.compact → validate → atomic rename |
| Recovery after crash | journal replay + recoverManifest |
| No partial writes | all-or-nothing via temp dir |
| .bin compression safe | transparent deflate/inflate, manifest has original checksum |
| JSON dedup safe | exact byte match, never loose unique data |

## Compression eligibility
| Condition | Action |
|-----------|--------|
| .bin file + size > 4KB + compression ratio < 50% | compress (store .bin) |
| .bin file + size > 4KB + compression ratio >= 50% | keep raw |
| .bin file + size <= 4KB | keep raw |
| .json file | never compress (already compressible) |
| .jsonl file | never compress (append-only) |

## Dedup eligibility (JSON only)
| Condition | Action |
|-----------|--------|
| current/*.json identical to previous/*.json | skip copy (dedup) |
| current/*.json differs from previous | copy as-is |
| No previous/ dir | copy all |

## Recovery priority
1. graph.current/manifest.json (fast path)
2. graph.previous/manifest.json (fallback)
3. Rebuild by scanning files (repair)
4. Return failure (manual intervention)
