
HTTP — протокол уровня приложений (L7), используемый для обмена данными между клиентом и сервером. Работает поверх TCP.

---

## Ключевые идеи

- Запрос → ответ.
- Методы: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`.
- Статус‑коды: 2xx (успех), 3xx (редирект), 4xx (ошибка клиента), 5xx (ошибка сервера).
- Заголовки управляют кэшем, авторизацией, типом контента и т. д.

---

## Методы HTTP

### Безопасные (safe) и идемпотентные

- **Безопасный** — не должен менять состояние сервера (например, чтение).
- **Идемпотентный** — повторный запрос даёт тот же результат, что и один.

### Основные методы

- **GET** — получить ресурс.  
  Безопасный, идемпотентный.

- **POST** — создать ресурс или выполнить действие.  
  Обычно не идемпотентный.

- **PUT** — создать/заменить ресурс целиком.  
  Идемпотентный.

- **PATCH** — частично изменить ресурс.  
  Обычно не идемпотентный.

- **DELETE** — удалить ресурс.  
  Идемпотентный (повтор не меняет результата).

- **HEAD** — как GET, но без тела ответа.  
  Полезно для проверки заголовков, размера, кеша. Идемпотентный.

- **OPTIONS** — узнать, какие методы и параметры поддерживаются.  
  Идемпотентный.

---

## Примеры

```bash
# GET
curl -i https://example.com/users/1

# POST
curl -i -X POST -H "Content-Type: application/json" \\
  -d '{"name":"Ann"}' https://example.com/users

# PUT
curl -i -X PUT -H "Content-Type: application/json" \\
  -d '{"name":"Ann","role":"admin"}' https://example.com/users/1

# PATCH
curl -i -X PATCH -H "Content-Type: application/json" \\
  -d '{"role":"admin"}' https://example.com/users/1

# DELETE
curl -i -X DELETE https://example.com/users/1

# HEAD
curl -I https://example.com/file.zip

# OPTIONS
curl -i -X OPTIONS https://example.com/users
```

---

## Коды ответов HTTP

### Классы

- **1xx** — информационные.
- **2xx** — успешные.
- **3xx** — перенаправления.
- **4xx** — ошибки клиента.
- **5xx** — ошибки сервера.

### Часто встречающиеся коды

- **200 OK** — успешный запрос.
- **201 Created** — ресурс создан (обычно после POST/PUT).
- **202 Accepted** — запрос принят, обработка асинхронна.
- **204 No Content** — успех без тела ответа.

- **301 Moved Permanently** — постоянный редирект.
- **302 Found** — временный редирект.
- **304 Not Modified** — кэш актуален.

- **400 Bad Request** — неверный запрос.
- **401 Unauthorized** — требуется аутентификация.
- **403 Forbidden** — доступ запрещён.
- **404 Not Found** — ресурс не найден.
- **405 Method Not Allowed** — метод не поддерживается.
- **409 Conflict** — конфликт состояния.
- **429 Too Many Requests** — слишком много запросов.

- **500 Internal Server Error** — внутренняя ошибка сервера.
- **502 Bad Gateway** — ошибка прокси/шлюза.
- **503 Service Unavailable** — сервис недоступен.
- **504 Gateway Timeout** — таймаут шлюза.

---

## Версии

- **HTTP/1.1** — последовательные запросы, keep‑alive.
- **HTTP/2** — мультиплексирование, заголовки HPACK.
- **HTTP/3** — поверх QUIC (UDP), снижает задержки.

## On-call диагностика HTTP
Базовые проверки:
```bash
curl -sv https://example.com/health
curl -I https://example.com
curl -s -o /dev/null -w '%{http_code} %{time_total}\\n' https://example.com/api
```

Что смотреть:
- код ответа и стабильность по времени;
- корректность заголовков `Content-Type`, `Cache-Control`, `Location`;
- повторяемость ошибки (случайная/постоянная).

## Практические guardrails API
- Для `POST` с риском дубликатов использовать idempotency-key.
- Для rate-limited API возвращать `429` + `Retry-After`.
- Для временной недоступности upstream возвращать `503`, а не `500`.
- Явно различать клиентские ошибки (`4xx`) и серверные (`5xx`).

## Типовые ошибки
- Возврат `200` при бизнес-ошибке вместо корректного `4xx/5xx`.
- Отсутствие timeout/retry политики на стороне клиента.
- Смешивание синхронных и асинхронных контрактов без `202 Accepted`.
- Неправильный кеш-контроль для изменяемых ресурсов.

## Мини-лаба (15-30 минут)
1. Подними тестовый API с endpoint `/health` и `/api/resource`.
2. Прогони `GET/POST/PUT/PATCH/DELETE` через `curl -i`.
3. Зафиксируй корректные статус-коды и idempotency-поведение.
4. Добавь `429` и `503` сценарии и проверь клиентскую обработку.

---

## Быстрые примеры

```bash
curl -i https://example.com
curl -X POST -H "Content-Type: application/json" -d '{"ok":true}' https://example.com/api
```

---

## Связанные темы

- [[HTTPS и TLS]]
- [[OSI]]
- [[API]]
- [[Как проходит HTTP запрос]]
- [[Как работает браузер]]

---

## Материал

- [Документация: HTTP методы (MDN)](https://developer.mozilla.org/ru/docs/Web/HTTP/Methods)
- [Документация: HTTP статусы (MDN)](https://developer.mozilla.org/ru/docs/Web/HTTP/Status)
