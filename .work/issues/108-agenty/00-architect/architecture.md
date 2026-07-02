# Architecture

## Принцип
Filesystem-based AI engineering team simulation

## Flow
```
Issue → Architect (план, архитектура)
     → Backend + Frontend (параллельно)
     → QA (тесты)
     → Code Reviewer (ревью)
     → PR → Merge
```

## Изоляция
- Каждая роль — отдельная папка
- Коммуникация через shared/
