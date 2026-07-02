# Архитектура авторизации

## Flow
```
Frontend (LoginForm) 
  → POST /api/login { username, password }
  → Backend (mock validation)
  → { token, user }
  → sessionStorage
  → Dashboard
```

## API
| Endpoint | Method | Body | Response |
|---|---|---|---|
| /api/login | POST | { username, password } | { token, user } |
| /api/me | GET | Authorization header | { user } |

## Структура данных
```
User { name: string, role: string }
Token: mock-token-<timestamp>
Credentials: admin / admin123
```
