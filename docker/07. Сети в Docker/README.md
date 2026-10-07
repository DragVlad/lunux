# 07. Сети в Docker

## О чём этот раздел

Контейнеры должны общаться: друг с другом, с хостом, с внешним миром. Для этого в Docker есть сетевые драйверы. Разберём, как устроена сеть в Docker, какие драйверы бывают и когда что использовать.

| Тема | Что даёт |
|------|----------|
| **Сетевые драйверы** | bridge, host, none, overlay, macvlan |
| **Встроенный DNS** | Как контейнеры находят друг друга |
| **Проброс портов** | Как открыть контейнер наружу |
| **Изоляция** | Как разделить контейнеры |

> **Ключевая мысль:** каждый контейнер получает свой network namespace. Docker управляет тем, как эти namespace'ы соединяются.

---

## 01. Сетевые драйверы

### Список драйверов

```bash
docker network ls
```

**Что происходит:** вывод показывает стандартные сети:

```
NETWORK ID     NAME      DRIVER    SCOPE
abc123def456   bridge    bridge    local
def456abc123   host      host      local
123abc456def   none      null      local
```

| Драйвер | Что делает |
|---------|------------|
| **bridge** | Изолированная сеть на хосте (по умолчанию) |
| **host** | Контейнер использует сеть хоста |
| **none** | Нет сети |
| **overlay** | Сеть между хостами (Swarm) |
| **macvlan** | Контейнер получает MAC-адрес |

### bridge

**bridge** — это драйвер по умолчанию. Docker создаёт виртуальный мост `docker0` на хосте, к которому подключаются контейнеры.

```bash
docker run -d --name app1 nginx
docker run -d --name app2 nginx
```

**Что происходит:** оба контейнера подключены к сети `bridge`. Они могут общаться по IP, но не по имени.

**Проблема:** в стандартной bridge-сети нет DNS. Контейнеры не могут обращаться друг к другу по имени.

### Пользовательская bridge-сеть

```bash
docker network create mynet
```

**Что происходит:** создаётся пользовательская bridge-сеть с встроенным DNS.

```bash
docker run -d --name app1 --network mynet nginx
docker run -d --name app2 --network mynet nginx
```

**Что происходит:** теперь `app1` может обращаться к `app2` по имени `app2`.

**Проверка:**

```bash
docker exec app1 ping -c 2 app2
```

**Что происходит:** `app1` пингует `app2` по имени. DNS резолвит имя в IP.

> **Правило:** для общения контейнеров по имени используйте пользовательскую bridge-сеть.

### host

```bash
docker run -d --network host nginx
```

**Что происходит:** контейнер использует сеть хоста напрямую. Нет изоляции. Контейнер слушает порты хоста.

**Плюсы:**

- Нет накладных расходов на NAT
- Максимальная производительность

**Минусы:**

- Нет изоляции
- Конфликты портов
- Работает только на Linux

### none

```bash
docker run -d --network none nginx
```

**Что происходит:** контейнер не имеет сети. Только loopback.

**Зачем это нужно:**

- Полная изоляция
- Безопасность
- Тесты

### overlay

```bash
docker network create --driver overlay myoverlay
```

**Что происходит:** создаётся overlay-сеть для общения между хостами в Swarm.

**Когда использовать:** в Docker Swarm для мультихостовых приложений.

### macvlan

```bash
docker network create --driver macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  mymacvlan
```

**Что происходит:** контейнер получает собственный MAC-адрес и выглядит как физическое устройство в сети.

**Когда использовать:** когда контейнер должен быть виден в физической сети.

---

## 02. Встроенный DNS

### Как работает

В пользовательской bridge-сети Docker запускает встроенный DNS-сервер. Он резолвит имена контейнеров в их IP-адреса.

```bash
docker network create mynet
docker run -d --name db --network mynet postgres:16
docker run -d --name app --network mynet myapp
```

**Что происходит:** `app` может обращаться к `db` по имени `db`.

**Проверка:**

```bash
docker exec app ping -c 2 db
```

**Что происходит:** `app` пингует `db` по имени.

### Сетевые алиасы

```bash
docker run -d --name db --network mynet --network-alias database postgres:16
```

**Что происходит:** контейнер доступен по именам `db` и `database`.

**Зачем это нужно:** если приложение ожидает имя `database`, а контейнер называется `db`.

### DNS в Docker Compose

```yaml
services:
  app:
    build: .
    depends_on:
      - db

  db:
    image: postgres:16
```

**Что происходит:** в Docker Compose все сервисы автоматически подключаются к одной сети. `app` может обращаться к `db` по имени `db`.

**Пример подключения:**

```python
# app.py
import psycopg2

conn = psycopg2.connect(
    host="db",  # имя сервиса
    database="mydb",
    user="user",
    password="pass"
)
```

**Что происходит:** приложение подключается к `db` по имени. DNS резолвит имя в IP контейнера.

---

## 03. Проброс портов

### Синтаксис

```bash
docker run -d -p 8080:80 nginx
```

**Что происходит:** порт 8080 на хосте пробрасывается на порт 80 в контейнере.

```
Хост:8080 → Контейнер:80
```

### Форматы

| Формат | Что делает |
|--------|------------|
| `-p 8080:80` | Порт 8080 на всех интерфейсах хоста → порт 80 |
| `-p 127.0.0.1:8080:80` | Только localhost → порт 80 |
| `-p 8080:80/udp` | UDP вместо TCP |
| `-p 80` | Случайный порт на хосте → порт 80 |
| `-P` | Все порты из EXPOSE → случайные порты |

### Пример

```bash
docker run -d --name web -p 8080:80 nginx
docker port web
```

**Что происходит:** вывод показывает:

```
80/tcp -> 0.0.0.0:8080
```

**Проверка:**

```bash
curl http://localhost:8080
```

**Что происходит:** вывод показывает HTML-страницу nginx.

### Проброс нескольких портов

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  nginx
```

**Что происходит:** пробрасываются порты 80 и 443.

### Проброс диапазона

```bash
docker run -d -p 8000-8010:8000-8010 myapp
```

**Что происходит:** пробрасывается диапазон портов.

### Проброс только на localhost

```bash
docker run -d -p 127.0.0.1:8080:80 nginx
```

**Что происходит:** порт доступен только с localhost. Это безопаснее.

> **Правило:** в production не пробрасывайте порты на `0.0.0.0`, если не нужно. Используйте `127.0.0.1` или reverse proxy.

---

## 04. Изоляция сетей

### Разделение контейнеров

```bash
docker network create frontend
docker network create backend

docker run -d --name web --network frontend nginx
docker run -d --name app --network frontend --network backend myapp
docker run -d --name db --network backend postgres:16
```

**Что происходит:**

- `web` и `app` в сети `frontend`
- `app` и `db` в сети `backend`
- `web` не может общаться с `db` напрямую

**Проверка:**

```bash
docker exec web ping -c 2 app   # работает
docker exec web ping -c 2 db    # не работает
```

**Что происходит:** `web` видит `app`, но не видит `db`. Это изоляция.

### Зачем это нужно

| Сценарий | Что даёт |
|----------|----------|
| **Безопасность** | База данных не доступна извне |
| **Архитектура** | Чёткое разделение слоёв |
| **Отладка** | Проще понять, кто с кем общается |

### Подключение к сети на лету

```bash
docker network connect backend web
```

**Что происходит:** контейнер `web` подключается к сети `backend`.

```bash
docker network disconnect backend web
```

**Что происходит:** контейнер `web` отключается от сети `backend`.

### Просмотр сетей контейнера

```bash
docker inspect web | grep -A 20 '"Networks"'
```

**Что происходит:** вывод показывает сети контейнера:

```json
"Networks": {
  "frontend": {
    "IPAddress": "172.18.0.2",
    "Gateway": "172.18.0.1"
  },
  "backend": {
    "IPAddress": "172.19.0.2",
    "Gateway": "172.19.0.1"
  }
}
```

---

## 05. Практические примеры

### Пример: веб-приложение с БД

```bash
# Создаём сеть
docker network create app-net

# Запускаем БД
docker run -d \
  --name db \
  --network app-net \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

# Запускаем приложение
docker run -d \
  --name app \
  --network app-net \
  -e DATABASE_URL=postgres://postgres:secret@db:5432/mydb \
  -p 8080:8080 \
  myapp

# Запускаем nginx
docker run -d \
  --name nginx \
  --network app-net \
  -p 80:80 \
  -v /mnt/config/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx
```

**Что происходит:**

- Все контейнеры в сети `app-net`
- `app` подключается к `db` по имени `db`
- `nginx` проксирует запросы на `app`
- Наружу проброшены порты 80 и 8080

### Пример: nginx как reverse proxy

**default.conf:**

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Что происходит:** nginx проксирует запросы на `app:8080`. DNS резолвит `app` в IP контейнера.

### Пример: Docker Compose с сетями

```yaml
services:
  nginx:
    image: nginx:1.25
    ports:
      - "80:80"
    networks:
      - frontend
    depends_on:
      - app

  app:
    build: .
    networks:
      - frontend
      - backend
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  db-data:
```

**Что происходит:**

- `nginx` и `app` в сети `frontend`
- `app` и `db` в сети `backend`
- `nginx` не может общаться с `db` напрямую
- `db` не доступна извне

### Пример: проверка DNS

```bash
docker network create test-net
docker run -d --name web --network test-net nginx
docker run -it --rm --network test-net alpine sh
```

**Что происходит:** вы попадаете в Alpine-контейнер.

```bash
apk add --no-cache bind-tools
nslookup web
ping -c 2 web
```

**Что происходит:** вывод показывает IP-адрес `web` и успешный ping.

### Пример: изоляция сетей

```bash
# Создаём две сети
docker network create public
docker network create private

# Запускаем контейнеры
docker run -d --name web --network public nginx
docker run -d --name app --network public --network private myapp
docker run -d --name db --network private postgres:16

# Проверяем изоляцию
docker exec web ping -c 2 app   # работает
docker exec web ping -c 2 db    # не работает
docker exec app ping -c 2 db    # работает
```

**Что происходит:**

- `web` видит `app` (обе в `public`)
- `web` не видит `db` (разные сети)
- `app` видит `db` (обе в `private`)

---

## 06. Отладка сетей

### Просмотр сетей

```bash
docker network ls
docker network inspect mynet
```

**Что происходит:** вывод показывает детали сети:

```json
[
  {
    "Name": "mynet",
    "Driver": "bridge",
    "Subnet": "172.18.0.0/16",
    "Gateway": "172.18.0.1",
    "Containers": {
      "abc123...": {
        "Name": "app1",
        "IPv4Address": "172.18.0.2/16"
      }
    }
  }
]
```

### Проверка соединения

```bash
docker exec app1 ping -c 2 app2
docker exec app1 curl http://app2:80
```

**Что происходит:** проверка соединения между контейнерами.

### Просмотр портов

```bash
docker port app1
```

**Что происходит:** вывод показывает проброшенные порты:

```
80/tcp -> 0.0.0.0:8080
```

### Просмотр сетевых настроек контейнера

```bash
docker inspect app1 | grep -A 20 '"NetworkSettings"'
```

**Что происходит:** вывод показывает:

```json
"NetworkSettings": {
  "IPAddress": "172.18.0.2",
  "Gateway": "172.18.0.1",
  "Ports": {
    "80/tcp": [{"HostIp": "0.0.0.0", "HostPort": "8080"}]
  }
}
```

### Инструменты внутри контейнера

```bash
docker exec -it app1 sh
apk add --no-cache curl bind-tools iproute2
ip addr
nslookup app2
curl http://app2
```

**Что происходит:** внутри контейнера можно проверить сеть.

### Если контейнер не видит другой

**Проблема:** `app1` не может пингануть `app2`.

**Причины:**

| Причина | Решение |
|---------|---------|
| Разные сети | Подключить к одной сети |
| Нет DNS | Использовать пользовательскую сеть |
| Опечатка в имени | Проверить `docker network inspect` |
| Контейнер не запущен | `docker ps` |

**Решение:**

```bash
docker network connect mynet app1
docker network connect mynet app2
```

---

## Итог раздела

| Тема | Что даёт |
|------|----------|
| **Драйверы** | bridge, host, none, overlay, macvlan |
| **DNS** | Общение по именам в пользовательских сетях |
| **Проброс портов** | Доступ извне |
| **Изоляция** | Разделение контейнеров |

> **Главный вывод:** для общения контейнеров используйте пользовательскую bridge-сеть. Для изоляции — разделяйте сети. Для доступа извне — пробрасывайте порты.

**Ключевые правила:**

1. **Пользовательская bridge-сеть** — для DNS и общения по именам
2. **Разные сети** — для изоляции
3. **`-p 127.0.0.1:8080:80`** — для безопасности
4. **`host`** — только если нужна максимальная производительность
5. **`none`** — для полной изоляции