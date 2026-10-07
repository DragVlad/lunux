# 08. Docker Compose

## О чём этот раздел

Запускать контейнеры по одному через `docker run` неудобно: длинные команды, легко ошибиться, сложно воспроизвести. Docker Compose решает эту проблему: описывает всё приложение в одном YAML-файле и управляет им одной командой.

| Тема | Что даёт |
|------|----------|
| **Зачем Compose** | Проблема ручного запуска |
| **docker-compose.yml** | Описание сервисов |
| **Команды** | Управление стеком |
| **Переменные** | `.env` и подстановки |
| **Зависимости** | `depends_on`, healthcheck |
| **Практика** | Полный стек |

> **Ключевая мысль:** Docker Compose — это декларативное описание многоконтейнерного приложения. Вы описываете, что хотите, а Compose делает это.

---

## 01. Зачем нужен Compose

### Проблема

Запуск приложения из нескольких контейнеров вручную:

```bash
docker network create app-net

docker run -d --name db --network app-net \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

docker run -d --name cache --network app-net \
  -v cache-data:/data \
  redis:7

docker run -d --name app --network app-net \
  -e DATABASE_URL=postgres://postgres:secret@db:5432/mydb \
  -e REDIS_URL=redis://cache:6379 \
  -p 8080:8080 \
  myapp

docker run -d --name nginx --network app-net \
  -p 80:80 \
  -v /mnt/config/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx
```

**Проблемы:**

- Длинные команды
- Легко ошибиться
- Сложно воспроизвести
- Нет версионирования
- Нет порядка запуска

### Решение

Один файл `docker-compose.yml`:

```yaml
services:
  db:
    image: postgres:16
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - pgdata:/var/lib/postgresql/data

  cache:
    image: redis:7
    volumes:
      - cache-data:/data

  app:
    build: .
    environment:
      - DATABASE_URL=postgres://postgres:secret@db:5432/mydb
      - REDIS_URL=redis://cache:6379
    ports:
      - "8080:8080"
    depends_on:
      - db
      - cache

  nginx:
    image: nginx:1.25
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app

volumes:
  pgdata:
  cache-data:
```

**Что происходит:** всё приложение описано в одном файле. Запуск — одной командой.

---

## 02. Структура docker-compose.yml

### Основные секции

| Секция | Что описывает |
|--------|---------------|
| `services` | Контейнеры приложения |
| `volumes` | Именованные тома |
| `networks` | Сети |
| `configs` | Конфигурации (Swarm) |
| `secrets` | Секреты (Swarm) |

### Минимальный пример

```yaml
services:
  web:
    image: nginx:1.25
    ports:
      - "80:80"
```

**Что происходит:** описывается один сервис `web` на базе `nginx:1.25` с пробросом порта 80.

### Сервис: основные параметры

| Параметр | Что делает |
|----------|------------|
| `image` | Образ |
| `build` | Сборка из Dockerfile |
| `ports` | Проброс портов |
| `volumes` | Тома и bind mounts |
| `environment` | Переменные окружения |
| `env_file` | Файл с переменными |
| `depends_on` | Зависимости |
| `networks` | Сети |
| `restart` | Рестарт-политика |
| `command` | Команда запуска |
| `entrypoint` | Точка входа |
| `healthcheck` | Проверка здоровья |

### Пример: сервис с build

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - VERSION=1.0
    ports:
      - "8080:8080"
```

**Что происходит:** сервис `app` собирается из `Dockerfile` в текущей директории.

### Пример: сервис с volumes

```yaml
services:
  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
```

**Что происходит:**

- `pgdata` — именованный том
- `./init.sql` — bind mount (read-only)

### Пример: сервис с environment

```yaml
services:
  app:
    image: myapp
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
      - REDIS_URL=redis://cache:6379
      - LOG_LEVEL=info
```

**Что происходит:** переменные окружения передаются в контейнер.

---

## 03. Команды

### Основные команды

| Команда | Что делает |
|---------|------------|
| `docker compose up` | Запустить все сервисы |
| `docker compose up -d` | Запустить в фоне |
| `docker compose down` | Остановить и удалить |
| `docker compose ps` | Список сервисов |
| `docker compose logs` | Логи |
| `docker compose logs -f` | Логи в реальном времени |
| `docker compose build` | Собрать образы |
| `docker compose pull` | Скачать образы |
| `docker compose restart` | Перезапустить |
| `docker compose stop` | Остановить |
| `docker compose start` | Запустить |
| `docker compose exec` | Выполнить команду |
| `docker compose run` | Запустить одноразовый контейнер |

### Запуск

```bash
docker compose up
```

**Что происходит:**

- Собирает образы (если нужно)
- Создаёт сети
- Создаёт тома
- Запускает контейнеры
- Подключается к логам

```bash
docker compose up -d
```

**Что происходит:** то же самое, но в фоне.

```bash
docker compose up --build
```

**Что происходит:** пересобирает образы перед запуском.

```bash
docker compose up -d --scale app=3
```

**Что происходит:** запускает 3 экземпляра сервиса `app`.

### Остановка

```bash
docker compose stop
```

**Что происходит:** останавливает контейнеры, но не удаляет их.

```bash
docker compose down
```

**Что происходит:** останавливает и удаляет контейнеры, сети. Тома **не** удаляются.

```bash
docker compose down -v
```

**Что происходит:** удаляет и тома тоже.

> **Важно:** `down -v` удаляет тома. Данные будут потеряны.

### Логи

```bash
docker compose logs
```

**Что происходит:** вывод показывает логи всех сервисов.

```bash
docker compose logs -f app
```

**Что происходит:** логи сервиса `app` в реальном времени.

```bash
docker compose logs --tail 100 db
```

**Что происходит:** последние 100 строк логов `db`.

### Выполнение команд

```bash
docker compose exec app bash
```

**Что происходит:** запускает `bash` в запущенном контейнере `app`.

```bash
docker compose exec db psql -U postgres
```

**Что происходит:** запускает `psql` в контейнере `db`.

### Одноразовый контейнер

```bash
docker compose run --rm app python manage.py migrate
```

**Что происходит:** запускает команду в новом контейнере `app`, затем удаляет его.

**Отличие от `exec`:** `exec` работает в запущенном контейнере, `run` создаёт новый.

### Просмотр состояния

```bash
docker compose ps
```

**Что происходит:** вывод показывает:

```
NAME                IMAGE          STATUS                   PORTS
project-app-1       project-app    Up 5 minutes (healthy)   8080/tcp
project-db-1        postgres:16    Up 5 minutes (healthy)   5432/tcp
project-nginx-1     nginx:1.25     Up 5 minutes             0.0.0.0:80->80/tcp
```

---

## 04. Переменные и .env

### .env файл

```bash
# .env
POSTGRES_PASSWORD=secret
POSTGRES_DB=mydb
APP_PORT=8080
```

**Что происходит:** Compose автоматически читает `.env` из текущей директории.

### Подстановка в docker-compose.yml

```yaml
services:
  db:
    image: postgres:16
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}

  app:
    ports:
      - "${APP_PORT}:8080"
```

**Что происходит:** значения подставляются из `.env`.

### Значения по умолчанию

```yaml
services:
  app:
    ports:
      - "${APP_PORT:-8080}:8080"
```

**Что происходит:** если `APP_PORT` не задан — используется `8080`.

### Обязательные переменные

```yaml
services:
  app:
    environment:
      - DATABASE_URL=${DATABASE_URL:?DATABASE_URL is required}
```

**Что происходит:** если `DATABASE_URL` не задан — Compose выдаст ошибку.

### env_file

```yaml
services:
  app:
    env_file:
      - .env
      - .env.local
```

**Что происходит:** переменные загружаются из файлов.

### Пример: полный .env

```bash
# .env
POSTGRES_USER=appuser
POSTGRES_PASSWORD=secret
POSTGRES_DB=mydb
APP_PORT=8080
APP_ENV=production
LOG_LEVEL=info
```

```yaml
services:
  db:
    image: postgres:16
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}

  app:
    build: .
    environment:
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      - APP_ENV=${APP_ENV}
      - LOG_LEVEL=${LOG_LEVEL}
    ports:
      - "${APP_PORT}:8080"
```

> **Важно:** не коммитьте `.env` в git. Добавьте в `.gitignore`. Используйте `.env.example` как шаблон.

---

## 05. Зависимости

### depends_on

```yaml
services:
  app:
    build: .
    depends_on:
      - db
      - cache

  db:
    image: postgres:16

  cache:
    image: redis:7
```

**Что происходит:** Compose запускает `db` и `cache` перед `app`.

**Проблема:** `depends_on` ждёт только **запуска** контейнера, а не готовности сервиса. `app` может запуститься, когда `db` ещё не готова принимать соединения.

### depends_on с condition

```yaml
services:
  app:
    build: .
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started

  db:
    image: postgres:16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 3s
      retries: 5

  cache:
    image: redis:7
```

**Что происходит:**

- `app` ждёт, пока `db` станет `healthy`
- `app` ждёт, пока `cache` просто запустится

### Условия

| Условие | Что означает |
|---------|--------------|
| `service_started` | Контейнер запущен |
| `service_healthy` | Healthcheck проходит |
| `service_completed_successfully` | Контейнер завершился с кодом 0 |

### Пример: миграции перед запуском

```yaml
services:
  migrate:
    build: .
    command: python manage.py migrate
    depends_on:
      db:
        condition: service_healthy
    restart: "no"

  app:
    build: .
    depends_on:
      migrate:
        condition: service_completed_successfully
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

**Что происходит:**

1. `db` запускается и проходит healthcheck
2. `migrate` выполняет миграции и завершается
3. `app` запускается

---

## 06. Практические примеры

### Пример: полный стек

**docker-compose.yml:**

```yaml
services:
  nginx:
    image: nginx:1.25
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      app:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - frontend

  app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      - REDIS_URL=redis://cache:6379
      - LOG_LEVEL=${LOG_LEVEL:-info}
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    networks:
      - frontend
      - backend

  db:
    image: postgres:16
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - backend

  cache:
    image: redis:7
    volumes:
      - cache-data:/data
    restart: unless-stopped
    networks:
      - backend

volumes:
  db-data:
  cache-data:
  nginx-logs:

networks:
  frontend:
  backend:
```

**Что происходит:**

- `nginx` — reverse proxy, доступен извне
- `app` — приложение, в двух сетях
- `db` — PostgreSQL, только в backend
- `cache` — Redis, только в backend
- `db` и `cache` не доступны извне
- `nginx` не может общаться с `db` напрямую

### Пример: nginx конфигурация

**nginx/default.conf:**

```nginx
upstream app {
    server app:8080;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://app/health;
    }
}
```

**Что происходит:** nginx проксирует запросы на `app:8080`.

### Пример: .env

```bash
POSTGRES_USER=appuser
POSTGRES_PASSWORD=secret
POSTGRES_DB=mydb
LOG_LEVEL=info
```

### Запуск

```bash
docker compose up -d
docker compose ps
```

**Что происходит:** вывод показывает:

```
NAME                IMAGE          STATUS                   PORTS
project-app-1       project-app    Up 30 seconds (healthy)  8080/tcp
project-cache-1     redis:7        Up 30 seconds            6379/tcp
project-db-1        postgres:16    Up 30 seconds (healthy)  5432/tcp
project-nginx-1     nginx:1.25     Up 30 seconds            0.0.0.0:80->80/tcp
```

### Проверка

```bash
curl http://localhost
docker compose logs -f
docker compose exec app bash
docker compose exec db psql -U appuser -d mydb
```

### Пример: масштабирование

```bash
docker compose up -d --scale app=3
```

**Что происходит:** запускаются 3 экземпляра `app`. nginx балансирует нагрузку между ними.

> **Важно:** для масштабирования нельзя пробрасывать порты у масштабируемого сервиса. Проброс должен быть у nginx.

### Пример: обновление

```bash
docker compose build app
docker compose up -d app
```

**Что происходит:** пересобирается образ `app`, контейнер перезапускается с новым образом.

```bash
docker compose pull
docker compose up -d
```

**Что происходит:** скачиваются новые версии образов, контейнеры перезапускаются.

### Пример: отладка

```bash
docker compose ps
docker compose logs app
docker compose exec app sh
docker compose top
docker compose events
```

**Что происходит:** просмотр состояния, логов, вход в контейнер, процессы, события.

---

## 07. Compose vs docker run

### Сравнение

| Задача | docker run | docker compose |
|--------|------------|----------------|
| Запуск одного контейнера | `docker run nginx` | `docker compose up` |
| Запуск стека | Много команд | `docker compose up` |
| Остановка | `docker stop` | `docker compose down` |
| Логи | `docker logs` | `docker compose logs` |
| Вход | `docker exec` | `docker compose exec` |
| Масштабирование | `--scale` | `--scale` |
| Версионирование | Нет | YAML в git |

### Когда что использовать

| Сценарий | Инструмент |
|----------|------------|
| Один контейнер | `docker run` |
| Разработка | Docker Compose |
| Тесты | Docker Compose |
| Production (один хост) | Docker Compose |
| Production (кластер) | Kubernetes / Swarm |
| CI/CD | Docker Compose |

### Преимущества Compose

| Преимущество | Что даёт |
|--------------|----------|
| **Декларативность** | Описываете, что хотите |
| **Версионирование** | YAML в git |
| **Воспроизводимость** | Одинаково у всех |
| **Простота** | Одна команда |
| **Зависимости** | Порядок запуска |
| **Изоляция** | Сети и тома |

---

## Итог раздела

| Тема | Что даёт |
|------|----------|
| **Зачем Compose** | Решение проблемы ручного запуска |
| **docker-compose.yml** | Описание сервисов |
| **Команды** | Управление стеком |
| **Переменные** | `.env` и подстановки |
| **Зависимости** | `depends_on` и healthcheck |
| **Практика** | Полный стек |

> **Главный вывод:** Docker Compose — это декларативное описание многоконтейнерного приложения. Один файл, одна команда, воспроизводимый результат.

**Ключевые правила:**

1. **Используйте `.env`** для переменных
2. **Не коммитьте `.env`** в git
3. **`depends_on` с `condition`** для порядка запуска
4. **Healthcheck** для готовности сервисов
5. **Разделяйте сети** для изоляции
6. **Именованные тома** для данных
7. **`restart: unless-stopped`** для production