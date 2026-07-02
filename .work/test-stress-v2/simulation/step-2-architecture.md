# Step 2: Architect

## 3 Architecture Alternatives
| Model | Вердикт | Причина |
|---|---|---|
| Event-Driven | ❌ | Total order dependency, плохо для offline |
| CRDT-Based | ✅ | Математическая гарантия consistency |
| Lock-Based | ❌ | UX disaster для real-time collab |

## CRDT Deep Dive
- LWW-Register для content
- OR-Set для block membership
- Fractional index для position
- HLC для временных меток

## Trade-offs
- CRDT complexity vs гарантии → CRDT wins
- Tombstone memory vs deletion → GC решает
- HLC vs Lamport → HLC даёт physical context

## Результат
Архитектура утверждена. Backend + Frontend стартуют.
