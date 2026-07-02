# System Architecture: Graph Storage Integrity, Compaction and Recovery Framework

## Overview
Architecture for reliable graph storage with compaction and crash recovery.

## Core Components

```
┌────────────────────────────────────────────────────────────────────┐
│                        Atomic Write Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │ WAL Writer   │  │ Manifest     │  │ Checksum              │    │
│  │ (Sequential)  │  │ Manager      │  │ Verifier              │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                       Compaction Engine                             │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │ Trigger      │  │ Entry        │  │ Atomic Shard          │    │
│  │ Conditions   │  │ Filter       │  │ Swap                  │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                       Recovery Framework                            │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │ WAL Replay   │  │ Shard        │  │ Consistency           │    │
│  │ (Crash)      │  │ Repair       │  │ Checker               │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow
1. Writes go to WAL first (sequential append)
2. On commit, manifest atomically updated
3. Compaction triggered by thresholds during idle time
4. On startup, WAL replayed for uncommitted operations
5. Consistency checker runs periodically
