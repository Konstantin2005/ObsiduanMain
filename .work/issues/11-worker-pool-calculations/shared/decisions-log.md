# Decisions Log: Worker Pool Calculations

## ADR-1: Web Workers API
Browser-compatible; structured clone overhead accepted.

## ADR-2: Priority queue with preemption
Critical tasks can preempt lower-priority running tasks.

## ADR-3: Versioned graph snapshots
Workers discard stale results via version checking.

## ADR-4: Pool size = CPU cores - 1
Reserves core for UI thread; min pool = 2.

## ADR-5: Transferable objects for large payloads
Zero-copy transfer of ArrayBuffer/OffscreenCanvas.
