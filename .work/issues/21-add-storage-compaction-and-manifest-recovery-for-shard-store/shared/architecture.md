# Shared Architecture: DEV: Add storage compaction and manifest recovery for shard store

## System Context
Shard storage must support compaction and manifest repair so the repository does not accumulate stale generated data.

## Key Components
1. Compaction Engine — identifies and merges stale shards
2. Manifest Recovery — repairs damaged/corrupt manifest files
3. Diagnostics Reporter — logs cleanup and repair actions
4. Safety Checker — validates state before and after operations

## Data Flow
Storage → Compaction Trigger → Compaction Engine → Manifest Update → Diagnostics

## Constraints
- Must be safe and repeatable
- Must be observable via diagnostics
- Must handle large-scale data
