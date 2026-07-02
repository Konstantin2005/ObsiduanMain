# Test Cases — Shard Compaction

## TC-1: Basic compaction (current only)
- Setup: graph.current with all files, no graph.previous
- Run: compactStore(outRoot, { force: true })
- Expected: ok=true, compactedFiles > 0, freedBytes >= 0

## TC-2: Compaction with previous (dedup JSON)
- Setup: graph.current + graph.previous with identical strings.json
- Run: compactStore(outRoot)
- Expected: strings.json deduped, freedBytes includes previous strings.json size

## TC-3: Compression of large .bin files
- Setup: .bin file > 10KB with repetitive data
- Run: compactStore(outRoot, { force: true })
- Expected: file compressed, ratio < 50%, freedBytes > 0

## TC-4: Small .bin not compressed
- Setup: .bin file = 512B
- Run: compactStore(outRoot, { force: true })
- Expected: copied raw, not in compactedFiles

## TC-5: Uncompressible .bin
- Setup: .bin file with random data, compression ratio >= 50%
- Run: compactStore(outRoot, { force: true })
- Expected: copied raw, not compressed

## TC-6: Dry run
- Setup: graph.current with files
- Run: compactStore(outRoot, { dryRun: true })
- Expected: ok=true, files in compactedFiles, graph.current untouched

## TC-7: recoverManifest — current healthy
- Setup: valid graph.current with correct manifest
- Run: recoverManifest(outRoot)
- Expected: ok=true, recoveredFrom="graph.current"

## TC-8: recoverManifest — current corrupt, previous healthy
- Setup: corrupt current manifest, valid previous
- Run: recoverManifest(outRoot)
- Expected: ok=true, recoveredFrom="graph.previous"

## TC-9: recoverManifest — both corrupt, repair by scan
- Setup: both manifests corrupt, files exist
- Run: recoverManifest(outRoot)
- Expected: ok=true, recoveredFrom="repair", manifest rebuilt

## TC-10: recoverManifest — nothing exists
- Setup: empty store directory
- Run: recoverManifest(outRoot)
- Expected: ok=false, no files found

## Edge Cases

| # | Scenario | Input | Expected |
|---|----------|-------|----------|
| EC-1 | Empty current dir | No files in current | ok=true, zero freedBytes |
| EC-2 | Compaction aborted mid-write | Kill during copy | graph.current intact, compact dir deleted |
| EC-3 | Journal file missing | No graph.journal.jsonl | recoverManifest still works via file scan |
| EC-4 | All JSON identical to previous | Dedup all | All JSON files deduped, previous removed |
| EC-5 | Only current dir, no previous | No graph.previous | No dedup, no crash |
| EC-6 | Corrupt .bin in current | Read error on one file | Error reported, compaction aborted |

## Failure Scenarios

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| FS-1 | validateStore fails after compact | compact dir deleted, current untouched |
| FS-2 | rename fails (permission) | Error returned, no data loss |
| FS-3 | Disk full during compression | Compression fails, falls back to copy |
| FS-4 | Concurrent compact + writeStore | Lock should prevent, else race handled |
