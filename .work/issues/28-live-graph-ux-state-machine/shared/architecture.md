# System Architecture: Live Graph UX State Machine

## Overview
Architecture for formalized state management of the Live Graph panel.

## Core Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                        State Definitions                             │
│  ┌──────────────────────────────────────────────────────────┐      │
│  │  IDLE ↔ LOADING ↔ RUNNING ↔ PAUSED ↔ ERROR ↔ RECOVERING  │      │
│  │                         PREVIEW                           │      │
│  └──────────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        State Machine Engine                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐     │
│  │ FSM Engine   │  │ Event Queue  │  │ Guard/Hook            │     │
│  │              │  │ (ordered)    │  │ Manager               │     │
│  └──────────────┘  └──────────────┘  └───────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         UI Mapping Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐     │
│  │ State → UI   │  │ Action       │  │ Visual               │     │
│  │ Renderer     │  │ Controller   │  │ Indicators            │     │
│  └──────────────┘  └──────────────┘  └───────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

## State Transition Map
```
IDLE ──(start)──→ LOADING ──(loaded)──→ RUNNING
RUNNING ──(pause)──→ PAUSED ──(resume)──→ RUNNING
RUNNING ──(error)──→ ERROR ──(recover)──→ RECOVERING ──(recovered)──→ RUNNING
RUNNING ──(preview)──→ PREVIEW ──(exit)──→ RUNNING
Any ──(stop)──→ IDLE
```
