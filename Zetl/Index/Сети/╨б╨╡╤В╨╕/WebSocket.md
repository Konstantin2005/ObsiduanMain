
WebSocket — протокол для двунаправленного обмена данными между клиентом и сервером поверх одного TCP‑соединения. Часто используется для realtime‑обновлений.

---

## Как работает

1. Клиент делает HTTP‑запрос с заголовком `Upgrade: websocket`.
2. Сервер подтверждает апгрейд.
3. Дальше идёт обмен фреймами WebSocket поверх TCP.

Важно:
- WebSocket обычно живет долго, поэтому критичны таймауты и keepalive.
- Для балансировки часто нужна sticky-сессия, чтобы клиент не «прыгал» между backend.

---

## Где используется

- Чаты и уведомления.
- Биржевые/игровые realtime‑данные.
- Дашборды и live‑метрики.

---

## Пример заголовков (упрощённо)

Клиент:
```
GET /ws HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: ...
Sec-WebSocket-Version: 13
```

Сервер:
```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: ...
```

---

## On-call диагностика WebSocket

Проверить upgrade на edge:
```bash
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  https://example.com/ws
```

Что смотреть:
- есть ли `101 Switching Protocols`;
- не режет ли proxy заголовки `Upgrade/Connection`;
- нет ли idle-timeout на балансировщике или Nginx.

---

## Типовые ошибки

- Проксирование без `proxy_http_version 1.1`.
- Не переданы `Upgrade`/`Connection` заголовки.
- Слишком маленькие timeouts для long-lived соединений.
- Нет sticky-политики и stateful-сессии рвутся.

---

## Собес фокус

- Чем WebSocket отличается от обычного HTTP polling.
- Когда WebSocket лучше SSE, а когда нет.
- Почему для WebSocket важны timeout/sticky/keepalive настройки.

---

## Мини-лаба (15-30 минут)

1. Подними простой WS-сервер и проксируй его через Nginx.
2. Проверь успешный `101` handshake.
3. Умышленно убери `Upgrade` заголовки и зафиксируй симптом.
4. Верни настройки и добавь адекватный read timeout.

---

## Связанные темы

- [[HTTP]]
- [[TCP]]
- [[OSI]]

---

## Материал

- [Видео: WebSocket](https://youtu.be/19d4AXt3dSI?si=pK94AmJ9f7Hh18wC)
