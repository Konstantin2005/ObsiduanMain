# Step 3: Backend + Frontend

## Backend
- POST /register: валидация, проверка дубликатов, in-memory save
- POST /login: проверка credentials, генерация fake JWT
- GET /me: парсинг токена, возврат user data
- Выбор: Node.js + Express

## Frontend
- App.vue: маршрутизация по auth статусу
- RegisterForm.vue: регистрация с подтверждением пароля
- LoginForm.vue: логин, сохранение token в localStorage
- Dashboard.vue: отображение user info, logout

## Результат
Функционал реализован. Передано QA.
