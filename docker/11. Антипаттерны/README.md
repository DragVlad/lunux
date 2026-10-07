# 11. Антипаттерны

## О чём этот раздел

Мы разобрали, как правильно работать с Docker. Теперь разберём, **как делать не надо**. Антипаттерны — это типичные ошибки, которые приводят к проблемам: большие образы, медленная сборка, уязвимости, сложная отладка.

| Тема | Что даёт |
|------|----------|
| **Антипаттерны Dockerfile** | Как не писать Dockerfile |
| **Антипаттерны запуска** | Как не запускать контейнеры |
| **Антипаттерны данных** | Как не работать с данными |
| **Антипаттерны сети** | Как не настраивать сеть |
| **Антипаттерны Compose** | Как не писать Compose |
| **Антипаттерны безопасности** | Как не защищать |

> **Ключевая мысль:** антипаттерн — это не «ошибка», а решение, которое работает сейчас, но создаёт проблемы потом.

---

## 01. Антипаттерны Dockerfile

### 1.1. Использование `latest`

**Плохо:**

```dockerfile
FROM python:latest
```

**Проблема:** `latest` может указывать на что угодно. Завтра образ будет другим. Сборка перестанет быть воспроизводимой.

**Хорошо:**

```dockerfile
FROM python:3.12.1-slim
```

**Что происходит:** версия фиксирована. Сборка воспроизводима.

### 1.2. Большой базовый образ

**Плохо:**

```dockerfile
FROM ubuntu:22.04
```

**Проблема:** 77 МБ, много пакетов, много уязвимостей.

**Хорошо:**

```dockerfile
FROM python:3.12.1-slim
# или
FROM alpine:3.20
# или
FROM gcr.io/distroless/python3
```

**Что происходит:** меньше размер, меньше уязвимостей.

### 1.3. Много `RUN` вместо одного

**Плохо:**

```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN rm -rf /var/lib/apt/lists/*
```

**Проблема:** 4 слоя. `rm` не уменьшает размер — файлы остаются в предыдущих слоях.

**Хорошо:**

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git && \
    rm -rf /var/lib/apt/lists/*
```

**Что происходит:** 1 слой. `rm` реально уменьшает размер.

### 1.4. `COPY . .` до установки зависимостей

**Плохо:**

```dockerfile
COPY . .
RUN pip install -r requirements.txt
```

**Проблема:** любое изменение кода инвалидирует кэш зависимостей. Пересборка занимает минуты.

**Хорошо:**

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

**Что происходит:** зависимости пересобираются только при изменении `requirements.txt`.

### 1.5. Секреты в Dockerfile

**Плохо:**

```dockerfile
ENV DATABASE_PASSWORD=secret
ARG API_KEY=abc123
```

**Проблема:** секреты видны в `docker history`, `docker inspect`, в слоях образа.

**Хорошо:**

```dockerfile
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=api_key \
    API_KEY=$(cat /run/secrets/api_key) && \
    curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

```bash
docker build --secret id=api_key,src=./api_key.txt .
```

**Что происходит:** секрет доступен только во время сборки, не сохраняется в образе.

### 1.6. Запуск от root

**Плохо:**

```dockerfile
FROM python:3.12-slim
COPY . .
CMD ["python", "app.py"]
```

**Проблема:** контейнер запускается от root. Если злоумышленник получит доступ — он root.

**Хорошо:**

```dockerfile
FROM python:3.12-slim
RUN useradd -m -u 1000 appuser
WORKDIR /app
COPY --chown=appuser:appuser . .
USER appuser
CMD ["python", "app.py"]
```

**Что происходит:** контейнер запускается от `appuser`.

### 1.7. `apt-get upgrade`

**Плохо:**

```dockerfile
RUN apt-get update && apt-get upgrade -y
```

**Проблема:** `upgrade` может сломать образ. Непредсказуемость. Большой размер.

**Хорошо:**

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

**Что происходит:** устанавливаются только нужные пакеты.

### 1.8. Shell form для CMD/ENTRYPOINT

**Плохо:**

```dockerfile
CMD python app.py
```

**Проблема:** запускается через `/bin/sh -c`. `SIGTERM` не доходит до Python. Контейнер убивается через 10 секунд.

**Хорошо:**

```dockerfile
CMD ["python", "app.py"]
```

**Что происходит:** Python — PID 1. `SIGTERM` доходит до него.

### 1.9. Игнорирование `.dockerignore`

**Плохо:**

Нет `.dockerignore`. В контекст сборки попадают `.git`, `node_modules`, `.env`.

**Проблема:** медленная сборка, большой образ, утечка секретов.

**Хорошо:**

```
# .dockerignore
.git
node_modules
*.log
.env
__pycache__
*.pyc
.pytest_cache
```

**Что происходит:** лишние файлы не попадают в контекст.

### 1.10. `ADD` вместо `COPY`

**Плохо:**

```dockerfile
ADD . /app
```

**Проблема:** `ADD` распаковывает tar и поддерживает URL. Непредсказуемость.

**Хорошо:**

```dockerfile
COPY . /app
```

**Что происходит:** только копирование.

---

## 02. Антипаттерны запуска

### 2.1. `--privileged`

**Плохо:**

```bash
docker run --privileged myapp
```

**Проблема:** контейнер получает все capabilities, доступ ко всем устройствам. Это дыра в безопасности.

**Хорошо:**

```bash
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp
```

**Что происходит:** только нужные capabilities.

### 2.2. Проброс Docker socket

**Плохо:**

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock myapp
```

**Проблема:** контейнер получает полный доступ к Docker. Это равно root на хосте.

**Хорошо:**

```bash
# Используйте Docker API с ограничениями
# или Docker socket proxy
docker run -v /var/run/docker.sock:/var/run/docker.sock:ro tecnativa/docker-socket-proxy
```

**Что происходит:** доступ ограничен.

### 2.3. Нет лимитов ресурсов

**Плохо:**

```bash
docker run -d myapp
```

**Проблема:** контейнер может съесть всю память, CPU, процессы. Хост зависнет.

**Хорошо:**

```bash
docker run -d \
  --memory 512m \
  --memory-swap 512m \
  --cpus 1.5 \
  --pids-limit 100 \
  myapp
```

**Что происходит:** ресурсы ограничены.

### 2.4. `latest` в production

**Плохо:**

```bash
docker run -d myapp:latest
```

**Проблема:** непредсказуемость. Завтра образ будет другим.

**Хорошо:**

```bash
docker run -d myapp:1.0.0
# или
docker run -d myapp@sha256:abc123...
```

**Что происходит:** версия фиксирована.

### 2.5. Нет `--restart`

**Плохо:**

```bash
docker run -d myapp
```

**Проблема:** если контейнер упадёт — он не перезапустится. Приложение недоступно.

**Хорошо:**

```bash
docker run -d --restart unless-stopped myapp
```

**Что происходит:** контейнер перезапускается автоматически.

### 2.6. Нет healthcheck

**Плохо:**

```dockerfile
FROM python:3.12-slim
COPY . .
CMD ["python", "app.py"]
```

**Проблема:** контейнер может быть `Running`, но приложение внутри не работает.

**Хорошо:**

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1
```

**Что происходит:** Docker проверяет здоровье.

### 2.7. Проброс портов на `0.0.0.0`

**Плохо:**

```bash
docker run -d -p 5432:5432 postgres:16
```

**Проблема:** база данных доступна извне. Если пароль слабый — взломают.

**Хорошо:**

```bash
docker run -d -p 127.0.0.1:5432:5432 postgres:16
# или
docker run -d postgres:16  # только внутри сети Docker
```

**Что происходит:** база данных недоступна извне.

### 2.8. Игнорирование кодов выхода

**Плохо:**

```bash
docker run -d myapp
# не проверяем, запустился ли
```

**Проблема:** контейнер может упасть, а вы не заметите.

**Хорошо:**

```bash
docker run -d --name app myapp
sleep 2
docker ps | grep app || echo "Container failed"
docker logs app
```

**Что происходит:** проверка статуса.

---

## 03. Антипаттерны данных

### 3.1. Хранение данных в контейнере

**Плохо:**

```dockerfile
FROM postgres:16
# данные внутри контейнера
```

**Проблема:** при удалении контейнера данные теряются.

**Хорошо:**

```bash
docker run -d -v pgdata:/var/lib/postgresql/data postgres:16
```

**Что происходит:** данные в томе.

### 3.2. Bind mount для production

**Плохо:**

```bash
docker run -d -v /home/user/data:/data myapp
```

**Проблема:** зависимость от хоста. Права. Не портативно.

**Хорошо:**

```bash
docker volume create app-data
docker run -d -v app-data:/data myapp
```

**Что происходит:** Docker управляет томом.

### 3.3. Нет бэкапов томов

**Плохо:**

```bash
docker volume create pgdata
# нет бэкапов
```

**Проблема:** если том повреждён — данные потеряны.

**Хорошо:**

```bash
# Бэкап
docker run --rm \
  -v pgdata:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/pgdata-$(date +%Y%m%d).tar.gz -C /data .

# Восстановление
docker run --rm \
  -v pgdata:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/pgdata-20240101.tar.gz"
```

**Что происходит:** регулярные бэкапы.

### 3.4. Игнорирование прав

**Плохо:**

```bash
docker run -v /data:/data myapp
```

**Проблема:** если контейнер запускается от UID 1000, а файлы принадлежат root — нет доступа.

**Хорошо:**

```bash
docker run --user 1000:1000 -v /data:/data myapp
# или
chown -R 1000:1000 /data
```

**Что происходит:** права совпадают.

---

## 04. Антипаттерны сети

### 4.1. Использование стандартной bridge-сети

**Плохо:**

```bash
docker run -d --name app1 nginx
docker run -d --name app2 nginx
# app1 не может обратиться к app2 по имени
```

**Проблема:** в стандартной bridge-сети нет DNS.

**Хорошо:**

```bash
docker network create mynet
docker run -d --name app1 --network mynet nginx
docker run -d --name app2 --network mynet nginx
# app1 может обратиться к app2 по имени
```

**Что происходит:** встроенный DNS.

### 4.2. Все в одной сети

**Плохо:**

```bash
docker network create app-net
docker run -d --network app-net nginx
docker run -d --network app-net app
docker run -d --network app-net db
docker run -d --network app-net cache
```

**Проблема:** все контейнеры видят друг друга. Нет изоляции.

**Хорошо:**

```bash
docker network create frontend
docker network create backend

docker run -d --network frontend nginx
docker run -d --network frontend --network backend app
docker run -d --network backend db
docker run -d --network backend cache
```

**Что происходит:** изоляция слоёв.

### 4.3. `--network host`

**Плохо:**

```bash
docker run -d --network host nginx
```

**Проблема:** нет изоляции. Конфликты портов. Работает только на Linux.

**Хорошо:**

```bash
docker run -d -p 80:80 nginx
```

**Что происходит:** изоляция + проброс портов.

### 4.4. Нет TLS

**Плохо:**

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://app:8080;
    }
}
```

**Проблема:** трафик не шифрован.

**Хорошо:**

```nginx
server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://app:8080;
    }
}
```

**Что происходит:** трафик шифрован.

---

## 05. Антипаттерны Docker Compose

### 5.1. Секреты в `docker-compose.yml`

**Плохо:**

```yaml
services:
  app:
    environment:
      - DATABASE_PASSWORD=secret
      - API_KEY=abc123
```

**Проблема:** секреты в git.

**Хорошо:**

```yaml
services:
  app:
    environment:
      - DATABASE_PASSWORD=${DATABASE_PASSWORD}
    secrets:
      - api_key

secrets:
  api_key:
    file: ./secrets/api_key.txt
```

```bash
# .env (не коммитить)
DATABASE_PASSWORD=secret
```

**Что происходит:** секреты вне git.

### 5.2. Нет `.env.example`

**Плохо:**

Только `.env` в git.

**Проблема:** новые разработчики не знают, какие переменные нужны.

**Хорошо:**

```
# .env.example
POSTGRES_USER=appuser
POSTGRES_PASSWORD=changeme
POSTGRES_DB=mydb
LOG_LEVEL=info
```

```bash
cp .env.example .env
# редактируем .env
```

**Что происходит:** шаблон в git, реальные значения — локально.

### 5.3. `depends_on` без `condition`

**Плохо:**

```yaml
services:
  app:
    depends_on:
      - db

  db:
    image: postgres:16
```

**Проблема:** `app` запускается, когда `db` ещё не готова. Ошибка подключения.

**Хорошо:**

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 3s
      retries: 5
```

**Что происходит:** `app` ждёт, пока `db` станет `healthy`.

### 5.4. Нет `restart`

**Плохо:**

```yaml
services:
  app:
    image: myapp
```

**Проблема:** контейнер не перезапускается при падении.

**Хорошо:**

```yaml
services:
  app:
    image: myapp
    restart: unless-stopped
```

**Что происходит:** автоматический перезапуск.

### 5.5. Нет лимитов

**Плохо:**

```yaml
services:
  app:
    image: myapp
```

**Проблема:** контейнер может съесть все ресурсы.

**Хорошо:**

```yaml
services:
  app:
    image: myapp
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.5'
    pids_limit: 100
```

**Что происходит:** ресурсы ограничены.

### 5.6. `build` в production

**Плохо:**

```yaml
services:
  app:
    build: .
```

**Проблема:** сборка на production-хосте. Медленно, небезопасно.

**Хорошо:**

```yaml
services:
  app:
    image: myregistry/myapp:1.0.0
```

**Что происходит:** образ собран в CI, на production только скачивается.

### 5.7. Игнорирование `version`

**Плохо:**

```yaml
version: '3.8'
services:
  ...
```

**Проблема:** `version` устарел в Compose V2. Docker Compose игнорирует его.

**Хорошо:**

```yaml
services:
  ...
```

**Что происходит:** современный синтаксис.

---

## 06. Антипаттерны безопасности

### 6.1. `--privileged`

Уже разбирали. Никогда.

### 6.2. Root в контейнере

**Плохо:**

```dockerfile
FROM python:3.12-slim
COPY . .
CMD ["python", "app.py"]
```

**Проблема:** root в контейнере.

**Хорошо:**

```dockerfile
USER appuser
```

**Что происходит:** непривилегированный пользователь.

### 6.3. Все capabilities

**Плохо:**

```bash
docker run --cap-add=ALL myapp
```

**Проблема:** контейнер получает все capabilities.

**Хорошо:**

```bash
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp
```

**Что происходит:** только нужные.

### 6.4. Нет read-only

**Плохо:**

```bash
docker run -d myapp
```

**Проблема:** если злоумышленник получит доступ — он может изменить файлы.

**Хорошо:**

```bash
docker run -d --read-only --tmpfs /tmp myapp
```

**Что происходит:** ФС только для чтения.

### 6.5. Нет сканирования уязвимостей

**Плохо:**

```bash
docker build -t myapp .
docker push myapp
```

**Проблема:** образ может содержать уязвимости.

**Хорошо:**

```bash
docker build -t myapp .
trivy image myapp
docker push myapp
```

**Что происходит:** сканирование перед публикацией.

### 6.6. Нет обновлений

**Плохо:**

```dockerfile
FROM python:3.12.1-slim
# образ не обновляется
```

**Проблема:** новые CVE не исправляются.

**Хорошо:**

```bash
# Регулярная пересборка
docker build --no-cache -t myapp .
trivy image myapp
```

**Что происходит:** регулярное обновление.

### 6.7. Docker socket

Уже разбирали.

---

## 07. Антипаттерны производительности

### 7.1. Большой образ

**Плохо:**

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y build-essential python3 pip
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

**Проблема:** образ ~1 ГБ.

**Хорошо:**

```dockerfile
FROM python:3.12.1-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.12.1-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

**Что происходит:** образ ~150 МБ.

### 7.2. Медленная сборка

**Плохо:**

```dockerfile
COPY . .
RUN pip install -r requirements.txt
```

**Проблема:** любое изменение кода инвалидирует кэш.

**Хорошо:**

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

**Что происходит:** кэш используется.

### 7.3. Нет `.dockerignore`

**Плохо:**

Нет `.dockerignore`. В контекст попадают `node_modules`, `.git`.

**Проблема:** медленная передача контекста.

**Хорошо:**

```
# .dockerignore
.git
node_modules
*.log
.env
```

**Что происходит:** контекст меньше.

### 7.4. Много слоёв

**Плохо:**

```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y vim
```

**Проблема:** 4 слоя.

**Хорошо:**

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git vim && \
    rm -rf /var/lib/apt/lists/*
```

**Что происходит:** 1 слой.

### 7.5. Нет multi-stage

**Плохо:**

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY . .
RUN go build -o myapp .
CMD ["./myapp"]
```

**Проблема:** образ содержит весь Go-тулчейн.

**Хорошо:**

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

FROM scratch
COPY --from=builder /app/myapp /
CMD ["/myapp"]
```

**Что происходит:** образ ~10 МБ.

---

## 08. Антипаттерны отладки

### 8.1. Нет логов

**Плохо:**

```python
import logging
logging.basicConfig(filename='/var/log/app.log')
```

**Проблема:** логи внутри контейнера. Docker их не видит.

**Хорошо:**

```python
import logging
import sys
logging.basicConfig(stream=sys.stdout)
```

**Что происходит:** логи в stdout.

### 8.2. Нет healthcheck

**Плохо:**

```dockerfile
FROM python:3.12-slim
CMD ["python", "app.py"]
```

**Проблема:** контейнер `Running`, но приложение не работает.

**Хорошо:**

```dockerfile
HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1
```

**Что происходит:** статус здоровья.

### 8.3. Игнорирование `docker inspect`

**Плохо:**

```bash
docker run -d myapp
# не работает
# не знаем почему
```

**Проблема:** нет информации.

**Хорошо:**

```bash
docker run -d --name app myapp
docker ps -a
docker logs app
docker inspect app
docker exec -it app sh
```

**Что происходит:** диагностика.

### 8.4. Нет `--name`

**Плохо:**

```bash
docker run -d myapp
docker run -d myapp
docker run -d myapp
# какие-то happy_tesla, sad_einstein
```

**Проблема:** непонятные имена.

**Хорошо:**

```bash
docker run -d --name app-1 myapp
docker run -d --name app-2 myapp
docker run -d --name app-3 myapp
```

**Что происходит:** осмысленные имена.

### 8.5. Нет `--rm` для одноразовых

**Плохо:**

```bash
docker run -it ubuntu bash
# выходим
# контейнер остаётся
```

**Проблема:** мусор.

**Хорошо:**

```bash
docker run --rm -it ubuntu bash
```

**Что происходит:** контейнер удаляется после выхода.

---

## 09. Антипаттерны организации

### 9.1. Один контейнер — много сервисов

**Плохо:**

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y nginx postgresql redis
COPY start.sh /
CMD ["/start.sh"]
```

**Проблема:** монолит. Сложно масштабировать, обновлять, отлаживать.

**Хорошо:**

```yaml
services:
  nginx:
    image: nginx:1.25
  db:
    image: postgres:16
  cache:
    image: redis:7
```

**Что происходит:** один контейнер — одна задача.

### 9.2. Нет версионирования

**Плохо:**

```bash
docker build -t myapp .
docker push myapp:latest
```

**Проблема:** нет версий. Нельзя откатиться.

**Хорошо:**

```bash
docker build -t myapp:1.0.0 .
docker tag myapp:1.0.0 myapp:latest
docker push myapp:1.0.0
docker push myapp:latest
```

**Что происходит:** версионирование.

### 9.3. Нет CI/CD

**Плохо:**

```bash
# сборка вручную на production
ssh prod
docker build -t myapp .
docker run -d myapp
```

**Проблема:** непредсказуемость, ошибки.

**Хорошо:**

```yaml
# .github/workflows/build.yml
name: Build
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t myapp:${{ github.ref_name }} .
      - run: docker push myapp:${{ github.ref_name }}
```

**Что происходит:** автоматическая сборка.

### 9.4. Нет документации

**Плохо:**

Нет README, нет комментариев.

**Проблема:** новые разработчики не понимают.

**Хорошо:**

```markdown
# My App

## Запуск

```bash
docker compose up -d
```

## Переменные

| Переменная | Описание |
|------------|----------|
| `DATABASE_URL` | URL базы данных |
| `LOG_LEVEL` | Уровень логирования |
```

**Что происходит:** документация.

---

## 10. Чек-лист антипаттернов

### Dockerfile

- [ ] Не `latest`
- [ ] Не большой базовый образ
- [ ] Не много `RUN`
- [ ] `COPY` зависимостей до кода
- [ ] Нет секретов
- [ ] Не root
- [ ] Нет `apt-get upgrade`
- [ ] Exec form для CMD
- [ ] Есть `.dockerignore`
- [ ] `COPY` вместо `ADD`

### Запуск

- [ ] Не `--privileged`
- [ ] Нет Docker socket
- [ ] Есть лимиты
- [ ] Не `latest`
- [ ] Есть `--restart`
- [ ] Есть healthcheck
- [ ] Не `0.0.0.0` без необходимости

### Данные

- [ ] Не в контейнере
- [ ] Тома для production
- [ ] Есть бэкапы
- [ ] Права совпадают

### Сеть

- [ ] Пользовательская сеть
- [ ] Изоляция сетей
- [ ] Не `--network host`
- [ ] TLS

### Compose

- [ ] Нет секретов в YAML
- [ ] Есть `.env.example`
- [ ] `depends_on` с `condition`
- [ ] Есть `restart`
- [ ] Есть лимиты
- [ ] `image` в production

### Безопасность

- [ ] Не root
- [ ] Не все capabilities
- [ ] Read-only
- [ ] Сканирование уязвимостей
- [ ] Обновления

### Производительность

- [ ] Multi-stage build
- [ ] `.dockerignore`
- [ ] Кэш слоёв
- [ ] Минимальный образ

### Отладка

- [ ] Логи в stdout
- [ ] Healthcheck
- [ ] Осмысленные имена
- [ ] `--rm` для одноразовых

### Организация

- [ ] Один контейнер — одна задача
- [ ] Версионирование
- [ ] CI/CD
- [ ] Документация

---

## Итог раздела

| Тема | Что даёт |
|------|----------|
| **Dockerfile** | Как не писать |
| **Запуск** | Как не запускать |
| **Данные** | Как не работать |
| **Сеть** | Как не настраивать |
| **Compose** | Как не писать |
| **Безопасность** | Как не защищать |
| **Производительность** | Как не тормозить |
| **Отладка** | Как не теряться |
| **Организация** | Как не запутаться |

> **Главный вывод:** антипаттерн — это решение, которое работает сейчас, но создаёт проблемы потом. Избегайте их, и ваши контейнеры будут безопасными, быстрыми и предсказуемыми.

**Ключевые правила:**

1. **Фиксируйте версии** — не `latest`
2. **Минимальные образы** — alpine, slim, distroless
3. **Multi-stage build** — меньше размер
4. **Не root** — `USER appuser`
5. **Не все capabilities** — `--cap-drop=ALL`
6. **Read-only** — `--read-only`
7. **Лимиты** — `--memory`, `--cpus`
8. **Тома** — для данных
9. **Изоляция сетей** — разные сети
10. **Секреты** — не в образе
11. **Сканирование** — trivy, docker scout
12. **Логи** — в stdout
13. **Healthcheck** — для проверки
14. **CI/CD** — автоматизация
15. **Документация** — README