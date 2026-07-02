# Implementation Plan: Graph Change Detection and Incremental Update System

## Phase 1: Change Detection Layer
1. Implement File System Watcher service
   - Recursive vault monitoring
   - Debounced change events (300ms)
   - Ignore .git, .obsidian, .trash
2. Build Content Hasher
   - SHA-256 of file content
   - Store hash map in memory + persisted cache
   - Compare on each change event
3. Create Metadata Scanner
   - Track file size, modification time, links
   - Detect renames via hash matching
4. Develop Diff Engine
   - Produce structured ChangeSet: {added, modified, deleted, renamed}
   - Each change has: type, path, oldPath (if rename), hash, content, metadata

## Phase 2: Incremental Update Pipeline
1. Node Incremental Updater
   - Handle CRUD for graph nodes
   - Partial manifest update
2. Edge Incremental Updater
   - Extract links from changed files only
   - Update adjacency index incrementally
3. Layout Incremental Updater
   - Only re-layout affected subgraphs
   - Preserve positions of unchanged nodes
4. Manifest Incremental Updater
   - Atomic shard-level updates
   - Versioned manifest commits

## Phase 3: Consistency & Safety
1. Transactional batches
2. Rollback on partial failure
3. Validation hooks after each batch
4. Full rebuild fallback if incremental fails
