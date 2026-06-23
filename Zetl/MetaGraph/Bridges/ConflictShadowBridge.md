---
type: bridge
tags: [meta, bridge]
---
# ConflictShadowBridge
Конфликт порождает теневые ценности

## Назначение
Связывает [[ConflictGraph]] с [[ShadowValueSystem]].

## Маршруты
    - ConflictGraph → ShadowValueSystem
    - ShadowValueSystem → ConflictGraph

## Связи
    - [[ConflictGraph]]
    - [[ShadowValueSystem]]
    - [[ClusterConflict]]
    - [[ClusterEmotion]]
