# Decisions Log

| Дата | Решение | Обоснование | Автор |
|---|---|---|---|
| 2026-06-26 | In-memory Map вместо БД | Тестовая задача, не нужна персистентность | Architect |
| 2026-06-26 | Fake JWT (base64) вместо real JWT | Простота, mock, не production | Architect |
| 2026-06-26 | localStorage вместо sessionStorage | Данные сохраняются между вкладками | Frontend |
| 2026-06-26 | Express за Flask | Node.js стандарт в проекте | Backend |
| 2026-06-26 | Plain text password в mock | Не production — хеш не нужен | Backend |
