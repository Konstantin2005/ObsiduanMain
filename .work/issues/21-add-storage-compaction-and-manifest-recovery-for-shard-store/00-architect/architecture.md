# Architecture: Storage Compaction and Manifest Recovery

## Component Diagram
```
+------------------+     +-------------------+     +------------------+
| Compaction       |     | Manifest          |     | Diagnostics      |
| Engine           |---->| Recovery          |---->| Reporter         |
| - Scan Shards    |     | - Checksum Verify |     | - Action Log     |
| - Identify Stale |     | - Auto-Repair     |     | - State Summary  |
| - CoW Merge      |     | - Validate        |     | - Error Report   |
+------------------+     +-------------------+     +------------------+
         |                        |
         v                        v
+--------------------------------------------------+
|              Safety Checker                       |
|  - Pre-condition validation                      |
|  - Post-condition validation                     |
|  - Dry-run mode                                  |
+--------------------------------------------------+
```

## API Contract
```rust
pub struct CompactionConfig { trigger: Trigger, mode: CompactionMode }
pub enum Trigger { TimeBased(Duration), SizeBased(u64), Manual }
pub enum CompactionMode { Live, DryRun }

pub trait CompactionEngine {
    fn run(&self, config: &CompactionConfig) -> Result<CompactionReport>;
    fn validate(&self) -> Result<ValidationReport>;
}

pub trait ManifestRecovery {
    fn verify(&self) -> Result<ManifestStatus>;
    fn repair(&self) -> Result<RepairReport>;
}
```
