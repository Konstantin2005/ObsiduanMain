# Шаг 3: Разработка

## Backend
- Создан mock API: POST /api/login, GET /api/me
- Реализована валидация credentials
- Генерация mock токена (base64(username:timestamp))
- Обработка ошибок (401, 400)

## Frontend
- Создан LoginForm.vue (username, password, submit)
- Создан Dashboard.vue (приветствие, logout)
- Создан App.vue (маршрутизация по наличию токена)
- sessionStorage для хранения токена
- Обработка ошибок входа

## Результат
Функционал авторизации реализован. Передано QA.
