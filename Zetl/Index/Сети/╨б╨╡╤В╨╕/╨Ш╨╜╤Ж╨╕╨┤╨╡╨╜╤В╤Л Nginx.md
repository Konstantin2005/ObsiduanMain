Инциденты Nginx: сценарий -> диагностика -> fix.

---

## 502 Bad Gateway

### Диагностика
```bash
nginx -t
tail -n 200 /var/log/nginx/error.log
ss -lntp | rg ':8080|:8000|:9000'
curl -v http://127.0.0.1:8080/health
```

### Частая причина
- upstream не слушает порт;
- неверный `proxy_pass`;
- таймаут до upstream.

### Fix
- поднять upstream;
- исправить host/port в `proxy_pass`;
- при медленном backend увеличить таймауты:
```nginx
proxy_connect_timeout 5s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

---

## 504 Gateway Timeout

### Диагностика
```bash
tail -n 200 /var/log/nginx/error.log
curl -w 'time_total=%{time_total}\n' -o /dev/null -s http://127.0.0.1:8080/
```

### Fix
- ускорить backend;
- настроить кэш/очереди;
- повысить `proxy_read_timeout` при обоснованной необходимости.

---

## TLS/сертификатные ошибки

### Диагностика
```bash
openssl s_client -connect example.com:443 -servername example.com
nginx -T | rg -n 'ssl_certificate|ssl_certificate_key|server_name'
```

### Fix
- обновить сертификат/цепочку;
- проверить соответствие `server_name` и SNI;
- убедиться, что Nginx перезагружен:
```bash
systemctl reload nginx
```

---

## Rate limiting режет легитимный трафик

### Диагностика
```bash
nginx -T | rg -n 'limit_req|limit_conn'
tail -n 200 /var/log/nginx/error.log
```

### Fix
- ослабить лимиты;
- исключить health-check IP;
- разделить лимиты по критичным location.

---

## Связанные темы

- [[Nginx]]
- [[HTTP]]
- 
- [[TCP]]
