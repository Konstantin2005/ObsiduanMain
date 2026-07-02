# System Architecture: Performance Benchmark Harness and Regression Gate

## Overview
Architecture for unified performance benchmarking and regression detection.

## Core Components

```
┌────────────────────────────────────────────────────────────────────┐
│                        Benchmark Harness                            │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │ Scenario     │  │ Runner       │  │ Dataset               │    │
│  │ Definitions  │  │ (orchestrator)│  │ Manager               │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                        Metric Collectors                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │ Render   │ │ Update   │ │ Memory   │ │ Worker   │ │ Interact│ │
│  │ Time     │ │ Time     │ │ Footprint│ │ Load     │ │ Latency │ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └─────────┘ │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                     Baseline & Reporting                            │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │ Baseline     │  │ Report       │  │ Statistical           │    │
│  │ Storage      │  │ Generator    │  │ Comparator            │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                        Regression Gate                              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │ Threshold    │  │ Gate Checker │  │ Override              │    │
│  │ Config       │  │              │  │ Manager               │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow
1. Scenarios configured with dataset, iterations, warmup
2. Runner executes scenarios, collectors gather metrics
3. Results stored as baselines with historical tracking
4. Comparator checks current vs baseline with statistical methods
5. Gate blocks if regression exceeds configured thresholds
