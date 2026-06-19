Nginx — веб-сервер, reverse proxy и балансировщик нагрузки.

Коротко: в сетевом контексте Nginx чаще всего стоит на входе и маршрутизирует HTTP/HTTPS-трафик к backend-сервисам.

---

## Где используется

- TLS termination (завершение TLS на периметре).
- Reverse proxy к приложению (`proxy_pass`).
- Балансировка между несколькими upstream.
- Ограничение трафика (`limit_req`, `limit_conn`).
- Кэширование ответов.

---

## Минимальная схема

`client -> Nginx (443) -> upstream app (например, 8080)`

---

## Базовые команды

```bash
nginx -t
systemctl status nginx
journalctl -u nginx -n 200 --no-pager
tail -n 200 /var/log/nginx/error.log
tail -n 200 /var/log/nginx/access.log
```

---

## Связанные темы

- [[HTTP]]
- [[HTTPS и TLS]]
- [[TCP]]
- [[DNS]]
- [[Инциденты Nginx]]
