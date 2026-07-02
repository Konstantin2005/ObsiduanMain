# Decisions Log

| # | Решение | Почему | Автор | Trade-off |
|---|---|---|---|---|
| 1 | Version Vector вместо Event Sourcing | Баланс сложности и демонстрации conflict resolution | Architect | Нет полной event истории |
| 2 | Polling вместо WebSocket | Простота имплементации для mock | Architect | Задержка sync до 3s |
| 3 | In-memory storage | Требование задачи | Backend | Данные не персистентны |
| 4 | Optimistic UI | Лучший UX для offline-mode | Frontend | Rollback complexity |
| 5 | localStorage для offline queue | Простота, persistence между сессиями | Frontend | XSS риск, размер 5MB |
| 6 | 3 retries для sync | Баланс между надёжностью и UX | Backend | Возможна loss данных |
| 7 | Last-write-wins per field | Простота merge стратегии | Backend | Не подходит для complex merge |
