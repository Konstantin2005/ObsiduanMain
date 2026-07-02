# System Architecture: Graph Change Detection and Incremental Update System

## Overview
Architecture for detecting changes in graph data and applying incremental updates without full rebuilds.

## Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Change Detection Layer                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ File     │  │ Content  │  │ Metadata │  │ Diff     │    │
│  │ Watcher  │  │ Hasher   │  │ Scanner  │  │ Engine   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Incremental Update Pipeline                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Node     │  │ Edge     │  │ Layout   │  │ Manifest │    │
│  │ Updater  │  │ Updater  │  │ Updater  │  │ Updater  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Storage & Index Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐      │
│  │ Shard    │  │ Index    │  │ Manifest (source of   │      │
│  │ Manager  │  │ Updater  │  │ truth)                │      │
│  └──────────┘  └──────────┘  └──────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow
1. File Watcher detects changes in source markdown files
2. Content Hasher computes new hashes, compares with stored
3. Diff Engine generates a change set (additions, modifications, deletions)
4. Incremental Pipeline processes each change type through specialized updaters
5. Manifest and Index are updated atomically per batch
