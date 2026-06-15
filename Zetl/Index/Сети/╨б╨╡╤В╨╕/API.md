
API (Application Programming Interface) — это контракт взаимодействия между программами или сервисами. В контексте сетей чаще всего подразумевают web‑API поверх HTTP/HTTPS.

---

## Виды API (популярные)

- **REST** — ресурсы, HTTP‑методы, статус‑коды.
- **RPC** — вызов методов (например, gRPC).
- **GraphQL** — запросы данных по схеме.
- **WebSocket API** — двунаправленное общение в реальном времени.

---

## Базовые элементы web‑API

- **Endpoint** — URL ресурса.
- **Method** — `GET/POST/PUT/PATCH/DELETE`.
- **Headers** — авторизация, тип контента.
- **Body** — полезные данные (часто JSON).
- **Status code** — результат (2xx/4xx/5xx).

Пример:
```bash
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"name":"alex"}'
```

## Практический baseline API

- Версионирование (`/v1`, `/v2`) и явная политика обратной совместимости.
- Единый формат ошибок (код, сообщение, correlation id).
- Идемпотентность для операций создания/повтора (idempotency key).
- Таймауты и retry-политика на клиенте и gateway.
- Явная схема authN/authZ (JWT/OAuth2/API key + scope).

Пример ответа ошибки:
```json
{
  "code": "USER_ALREADY_EXISTS",
  "message": "User with this email already exists",
  "request_id": "6a72f6e1-6f0d-4e21-9e07-bc3f3c1c4c44"
}
```

---

## Где это в OSI

- **API** как интерфейс — L7 (Application).
- **HTTPS/TLS** — L6 (Presentation).
- **TCP** — L4 (Transport).

---

## On-call диагностика API

Быстрые проверки:
```bash
curl -sv https://api.example.com/health
curl -s -o /dev/null -w '%{http_code} %{time_total}\n' https://api.example.com/v1/users
```

Если есть 5xx/timeout:
1. Проверить gateway/reverse proxy.
2. Проверить upstream соединения и saturation backend.
3. Проверить DNS/TLS только если ошибка до API-логики.

---

## Собес фокус

- Разница API-контракта и внутренней реализации сервиса.
- Когда выбирать REST, gRPC, GraphQL.
- Как обеспечивать backward compatibility при изменении контракта.
- Как и где внедрять idempotency для безопасных повторов.

---

## Мини-лаба (15-30 минут)

1. Подними простой API (`GET /health`, `POST /users`).
2. Добавь единый формат ошибок и `request_id`.
3. Добавь idempotency key для `POST /users`.
4. Проверь поведение API при повторе одного и того же запроса.

---

## Связанные темы

- [[HTTP]]
- [[HTTPS и TLS]]
- [[WebSocket]]
- [[OSI]]

---

## Материал

- [Видео: API](https://youtu.be/fXa_2rllZTI?si=cMjEMFA3qxsnCraG)
- [Видео: API (суть)](https://youtu.be/KhuZdeuF6kw?si=sZ4AezXOrjbsUroz)
