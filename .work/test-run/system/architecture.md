# Architecture — Mock Auth System

## Auth Flow
```
Register → POST /register { username, password }
              → 201 { message }
              → 409 { error: "User exists" }

Login → POST /login { username, password }
          → 200 { token: "fake-jwt-<user>-<ts>" }
          → 401 { error: "Invalid credentials" }

Verify → GET /me { Authorization: Bearer <token> }
           → 200 { username, role }
           → 401 { error: "Unauthorized" }
```

## Data Flow
```
Frontend → HTTP → Backend (in-memory Map) → Response
```

## API Endpoints
| Method | Path | Body | Response |
|---|---|---|---|
| POST | /register | { username, password } | 201 / 409 |
| POST | /login | { username, password } | 200 + token / 401 |
| GET | /me | Authorization header | 200 + user / 401 |
