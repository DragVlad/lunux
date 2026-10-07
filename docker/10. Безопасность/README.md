# 10. Безопасность

## О чём этот раздел

Контейнеры — это не «песочница». Это изолированные процессы, но ядро общее с хостом. Если контейнер скомпрометирован — злоумышленник может попытаться выйти на хост. Разберём, как защитить контейнеры и хост.

| Тема | Что даёт |
|------|----------|
| **Модель угроз** | Чего боимся |
| **Изоляция** | Namespaces, cgroups, capabilities |
| **Пользователи** | Не запускать от root |
| **Файловая система** | Read-only, tmpfs |
| **Секреты** | Как не утекают |
| **Образы** | Минимальные и проверенные |
| **Runtime** | seccomp, AppArmor, SELinux |

> **Ключевая мысль:** безопасность контейнера — это слои. Чем больше слоёв — тем сложнее атаковать. Но ни один слой не даёт 100% гарантии.

---

## 01. Модель угроз

### Чего боимся

| Угроза | Что может произойти |
|--------|---------------------|
| **Побег из контейнера** | Злоумышленник получает доступ к хосту |
| **Привилегированный контейнер** | Контейнер с `--privileged` = root на хосте |
| **Утечка секретов** | Пароли, токены, ключи |
| **Уязвимости в образе** | Старые пакеты, CVE |
| **Компрометация образа** | Подмена образа в реестре |
| **DoS** | Контейнер съедает все ресурсы |
| **Атака на ядро** | Эксплойт в ядре Linux |

### Что нужно защищать

| Ресурс | Почему |
|--------|--------|
| **Хост** | Главная цель |
| **Другие контейнеры** | Изоляция |
| **Данные** | Тома, секреты |
| **Сеть** | Трафик |
| **Образы** | Целостность |

### Принцип наименьших привилегий

> **Правило:** контейнер должен иметь ровно те права, которые ему нужны. Ни больше.

Это относится ко всему:

- Пользователь (не root)
- Capabilities (не все)
- Файловая система (read-only где можно)
- Сеть (только нужные порты)
- Ресурсы (лимиты)

---

## 02. Изоляция

### Namespaces

Мы разбирали namespaces в разделе 01. Каждый контейнер получает свои:

- PID — не видит процессы хоста
- Network — свой сетевой стек
- Mount — своя файловая система
- UTS — своё имя хоста
- IPC — своё межпроцессное взаимодействие
- User — свои UID/GID
- Cgroup — своя иерархия

**Что это даёт:** контейнер не видит хостовые процессы, сеть, файлы.

### Cgroups

Cgroups ограничивают ресурсы:

```bash
docker run -d \
  --memory 512m \
  --memory-swap 512m \
  --cpus 1.5 \
  --pids-limit 100 \
  nginx
```

**Что происходит:**

| Флаг | Что ограничивает |
|------|------------------|
| `--memory 512m` | Память — 512 МБ |
| `--memory-swap 512m` | Swap — 512 МБ (без swap) |
| `--cpus 1.5` | CPU — 1.5 ядра |
| `--pids-limit 100` | Максимум 100 процессов |

**Зачем это нужно:**

- Защита от DoS
- Предсказуемость
- Справедливое распределение

> **Важно:** `--memory-swap` должен быть равен `--memory`, чтобы отключить swap. Иначе контейнер может выгружать память на диск.

### Capabilities

По умолчанию Docker даёт контейнеру ограниченный набор capabilities. Но их можно уменьшить.

```bash
docker run -d --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx
```

**Что происходит:**

- `--cap-drop=ALL` — убираем все capabilities
- `--cap-add=NET_BIND_SERVICE` — добавляем только нужную

**Список capabilities по умолчанию:**

```
CAP_CHOWN
CAP_DAC_OVERRIDE
CAP_FSETID
CAP_FOWNER
CAP_MKNOD
CAP_NET_RAW
CAP_SETGID
CAP_SETUID
CAP_SETFCAP
CAP_SETPCAP
CAP_NET_BIND_SERVICE
CAP_SYS_CHROOT
CAP_KILL
CAP_AUDIT_WRITE
```

**Опасные capabilities:**

| Capability | Что даёт |
|------------|----------|
| `CAP_SYS_ADMIN` | Почти root |
| `CAP_SYS_PTRACE` | Отладка процессов |
| `CAP_NET_ADMIN` | Управление сетью |
| `CAP_SYS_MODULE` | Загрузка модулей ядра |
| `CAP_DAC_READ_SEARCH` | Чтение любых файлов |

> **Правило:** `--cap-drop=ALL` и добавляйте только необходимые.

### Привилегированный режим

```bash
docker run --privileged nginx
```

**Что делает:** контейнер получает все capabilities, доступ ко всем устройствам, отключены seccomp и AppArmor.

**Что происходит:** контейнер практически равен root на хосте.

> **Правило:** никогда не используйте `--privileged` в production. Это дыра в безопасности.

### User namespace

```bash
docker run --userns=host nginx
```

**Что делает:** отключает user namespace remapping.

**По умолчанию:** Docker использует user namespace remapping, если настроен. Это значит, что root в контейнере = непривилегированный пользователь на хосте.

**Настройка:**

```json
// /etc/docker/daemon.json
{
  "userns-remap": "default"
}
```

**Что происходит:** Docker создаёт пользователя `dockremap`, и root в контейнере мапится на него на хосте.

---

## 03. Пользователи

### Не запускать от root

**Проблема:** по умолчанию контейнер запускается от root. Если злоумышленник получит доступ — он root внутри контейнера.

**Решение:** создать непривилегированного пользователя и запускать от него.

### В Dockerfile

```dockerfile
FROM python:3.12-slim

# Создаём пользователя
RUN useradd -m -u 1000 appuser

WORKDIR /app
COPY --chown=appuser:appuser . .

# Устанавливаем пользователя
USER appuser

CMD ["python", "app.py"]
```

**Что происходит:** контейнер запускается от `appuser` (UID 1000).

### При запуске

```bash
docker run -d --user 1000:1000 nginx
```

**Что происходит:** контейнер запускается от UID 1000, GID 1000.

### Проверка

```bash
docker run --rm alpine id
```

**Что происходит:** вывод показывает:

```
uid=0(root) gid=0(root) groups=0(root)
```

```bash
docker run --rm --user 1000:1000 alpine id
```

**Что происходит:** вывод показывает:

```
uid=1000 gid=1000 groups=1000
```

### Проблемы с правами

**Проблема:** если контейнер запускается от непривилегированного пользователя, он не может писать в директории, принадлежащие root.

**Решение:** использовать `--chown` в Dockerfile.

```dockerfile
COPY --chown=appuser:appuser . /app
RUN chown -R appuser:appuser /app
```

### Read-only root filesystem

```bash
docker run -d --read-only nginx
```

**Что делает:** корневая файловая система монтируется только для чтения.

**Что происходит:** контейнер не может писать в `/`. Если приложению нужно писать — используйте тома или tmpfs.

```bash
docker run -d \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/cache/nginx \
  --tmpfs /var/run \
  nginx
```

**Что происходит:** `/` только для чтения, но `/tmp`, `/var/cache/nginx`, `/var/run` — в памяти.

**Зачем это нужно:** если злоумышленник получит доступ — он не сможет изменить файлы.

### Проверка

```bash
docker run --rm --read-only alpine sh -c "echo test > /test.txt"
```

**Что происходит:** вывод показывает ошибку:

```
sh: can't create /test.txt: Read-only file system
```

---

## 04. Секреты

### Проблема

**Плохо:**

```dockerfile
ENV DATABASE_PASSWORD=secret
```

**Что происходит:** пароль виден в `docker inspect`, в истории слоёв, в `docker history`.

```bash
docker history myapp
```

**Что происходит:** вывод показывает:

```
IMAGE          CREATED BY                                      SIZE
abc123def456   ENV DATABASE_PASSWORD=secret                    0B
```

**Проблема:** пароль в открытом виде.

### Решение 1: переменные при запуске

```bash
docker run -d -e DATABASE_PASSWORD=secret myapp
```

**Что происходит:** пароль передаётся при запуске, не хранится в образе.

**Проблема:** пароль виден в `docker inspect`, в истории команд, в логах.

### Решение 2: env_file

```bash
# .env
DATABASE_PASSWORD=secret
```

```bash
docker run -d --env-file .env myapp
```

**Что происходит:** пароль читается из файла.

**Проблема:** файл нужно где-то хранить, он может попасть в git.

### Решение 3: Docker secrets (Swarm)

```bash
echo "secret" | docker secret create db_password -
```

```yaml
services:
  app:
    image: myapp
    secrets:
      - db_password

secrets:
  db_password:
    external: true
```

**Что происходит:** секрет монтируется в `/run/secrets/db_password`.

```python
with open('/run/secrets/db_password') as f:
    password = f.read().strip()
```

**Что происходит:** приложение читает секрет из файла.

### Решение 4: BuildKit secrets

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.12-slim

RUN --mount=type=secret,id=pip_token \
    PIP_TOKEN=$(cat /run/secrets/pip_token) && \
    pip install --extra-index-url https://token:$PIP_TOKEN@example.com/simple mypackage
```

```bash
docker build --secret id=pip_token,src=./token.txt -t myapp .
```

**Что происходит:** секрет доступен только во время сборки, не сохраняется в образе.

### Решение 5: tmpfs

```bash
docker run -d --tmpfs /run/secrets:size=1m myapp
```

**Что происходит:** `/run/secrets` в памяти. Данные не попадают на диск.

### Сравнение

| Способ | Безопасность | Удобство |
|--------|--------------|----------|
| `ENV` в Dockerfile | Низкая | Высокое |
| `-e` при запуске | Низкая | Высокое |
| `--env-file` | Средняя | Среднее |
| Docker secrets | Высокая | Среднее |
| BuildKit secrets | Высокая | Среднее |
| tmpfs | Высокая | Низкое |

> **Правило:** никогда не храните секреты в образе. Используйте Docker secrets или внешние хранилища (Vault, AWS Secrets Manager).

---

## 05. Образы

### Минимальные образы

**Проблема:** большой образ = много пакетов = много уязвимостей.

**Решение:** использовать минимальные базовые образы.

| Образ | Размер | Что внутри |
|-------|--------|------------|
| `ubuntu:22.04` | 77 МБ | Полная система |
| `debian:12-slim` | 74 МБ | Минимум |
| `alpine:3.20` | 7 МБ | Минимум |
| `distroless` | 2-20 МБ | Только приложение |
| `scratch` | 0 МБ | Пустой |

### Distroless

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/myapp /
CMD ["/myapp"]
```

**Что происходит:** финальный образ содержит только бинарник. Нет shell, нет пакетов, нет уязвимостей.

**Плюсы:**

- Минимальный размер
- Минимум уязвимостей
- Нет shell (сложнее атаковать)

**Минусы:**

- Нельзя войти в контейнер (`docker exec`)
- Сложнее отладка

### Scratch

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

FROM scratch
COPY --from=builder /app/myapp /
CMD ["/myapp"]
```

**Что происходит:** образ содержит только бинарник. Размер — несколько мегабайт.

### Фиксация версий

**Плохо:**

```dockerfile
FROM python:latest
RUN pip install flask
```

**Что происходит:** версии не фиксированы. Завтра образ будет другим.

**Хорошо:**

```dockerfile
FROM python:3.12.1-slim
RUN pip install flask==3.0.0
```

**Что происходит:** версии фиксированы. Образ воспроизводим.

### Digest

```dockerfile
FROM python@sha256:abc123def456...
```

**Что происходит:** используется конкретный образ по digest. Даже если тег `3.12.1-slim` перезаписан — digest указывает на тот же образ.

### Сканирование уязвимостей

```bash
docker scout cves myapp:1.0.0
```

**Что происходит:** вывод показывает уязвимости:

```
✓ No vulnerable packages detected
```

или

```
✗ 5 vulnerabilities found
  - CVE-2024-1234 (critical) in libc
  - CVE-2024-5678 (high) in openssl
```

```bash
trivy image myapp:1.0.0
```

**Что происходит:** альтернативный сканер.

### Подпись образов

```bash
docker trust sign myapp:1.0.0
```

**Что происходит:** образ подписывается. При скачивании проверяется подпись.

```bash
export DOCKER_CONTENT_TRUST=1
docker pull myapp:1.0.0
```

**Что происходит:** Docker проверяет подпись. Если подписи нет — скачивание не происходит.

### Best practices для образов

| Практика | Почему |
|----------|--------|
| **Минимальный базовый образ** | Меньше уязвимостей |
| **Фиксировать версии** | Воспроизводимость |
| **Использовать digest** | Неизменяемость |
| **Multi-stage build** | Меньше инструментов |
| **Не запускать от root** | Безопасность |
| **Сканировать уязвимости** | Безопасность |
| **Подписывать** | Целостность |
| **Обновлять регулярно** | Новые CVE |

---

## 06. Runtime-защита

### seccomp

**seccomp** (secure computing mode) — это механизм ядра Linux, который фильтрует системные вызовы.

**Что делает:** запрещает контейнеру опасные syscalls.

**Профиль по умолчанию:** Docker использует профиль seccomp, который запрещает ~44 syscalls из ~300.

```bash
docker run --security-opt seccomp=default nginx
```

**Что происходит:** используется профиль по умолчанию.

```bash
docker run --security-opt seccomp=unconfined nginx
```

**Что происходит:** seccomp отключён. Не рекомендуется.

**Свой профиль:**

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": ["read", "write", "open", "close"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

```bash
docker run --security-opt seccomp=profile.json nginx
```

**Что происходит:** разрешены только указанные syscalls.

### AppArmor

**AppArmor** — это механизм ядра Linux, который ограничивает доступ программ к ресурсам.

**Что делает:** ограничивает доступ к файлам, сети, capabilities.

```bash
docker run --security-opt apparmor=docker-default nginx
```

**Что происходит:** используется профиль по умолчанию.

```bash
docker run --security-opt apparmor=unconfined nginx
```

**Что происходит:** AppArmor отключён.

**Свой профиль:**

```
#include <tunables/global>

profile myapp flags=(attach_disconnected) {
  #include <abstractions/base>
  /app/** r,
  /app/myapp ix,
  /etc/ssl/certs/** r,
  network inet tcp,
  deny /etc/shadow r,
}
```

```bash
docker run --security-opt apparmor=myapp nginx
```

**Что происходит:** используется свой профиль.

### SELinux

**SELinux** — это механизм ядра Linux для мандатного контроля доступа.

**Что делает:** ограничивает доступ на основе меток.

```bash
docker run --security-opt label=type:container_t nginx
```

**Что происходит:** используется тип `container_t`.

### Сравнение

| Механизм | Что ограничивает | Где работает |
|----------|------------------|--------------|
| **seccomp** | Syscalls | Linux |
| **AppArmor** | Доступ к ресурсам | Ubuntu, Debian |
| **SELinux** | Мандатный доступ | RHEL, Fedora |

> **Правило:** не отключайте seccomp, AppArmor, SELinux без необходимости.

### No-new-privileges

```bash
docker run --security-opt no-new-privileges nginx
```

**Что делает:** запрещает процессу получать новые привилегии (например, через setuid).

**Зачем это нужно:** защита от повышения привилегий.

---

## 07. Сеть

### Изоляция сетей

```bash
docker network create frontend
docker network create backend

docker run -d --network frontend --name web nginx
docker run -d --network frontend --network backend --name app myapp
docker run -d --network backend --name db postgres:16
```

**Что происходит:**

- `web` и `app` в сети `frontend`
- `app` и `db` в сети `backend`
- `web` не может общаться с `db` напрямую
- `db` не доступна извне

### Не пробрасывать порты без необходимости

**Плохо:**

```bash
docker run -d -p 5432:5432 postgres:16
```

**Что происходит:** PostgreSQL доступен извне. Если пароль слабый — взломают.

**Хорошо:**

```bash
docker run -d postgres:16
```

**Что происходит:** PostgreSQL доступен только внутри сети Docker.

### Проброс только на localhost

```bash
docker run -d -p 127.0.0.1:5432:5432 postgres:16
```

**Что происходит:** PostgreSQL доступен только с localhost.

### Reverse proxy

```bash
docker run -d -p 80:80 -p 443:443 nginx
```

**Что происходит:** nginx — единственная точка входа. Остальные сервисы не доступны извне.

### TLS

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
}
```

**Что происходит:** трафик шифруется.

### Best practices для сети

| Практика | Почему |
|----------|--------|
| **Изоляция сетей** | Разделение слоёв |
| **Не пробрасывать порты** | Меньше атакуемая поверхность |
| **127.0.0.1** | Только локальный доступ |
| **Reverse proxy** | Единая точка входа |
| **TLS** | Шифрование |
| **Firewall** | Дополнительный слой |

---

## 08. Мониторинг и аудит

### Логи

```bash
docker logs mycontainer
docker events
```

**Что происходит:** логи и события контейнера.

### Аудит

```bash
auditctl -w /var/lib/docker -k docker
```

**Что происходит:** аудит доступа к директории Docker.

### Falco

**Falco** — это инструмент для runtime-мониторинга безопасности.

```bash
docker run -d \
  --name falco \
  --privileged \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /dev:/host/dev \
  -v /proc:/host/proc:ro \
  -v /boot:/host/boot:ro \
  -v /lib/modules:/host/lib/modules:ro \
  -v /usr:/host/usr:ro \
  falcosecurity/falco
```

**Что происходит:** Falco мониторит syscalls и предупреждает о подозрительной активности.

**Пример правила:**

```
- rule: Terminal shell in container
  desc: A shell was spawned in a container
  condition: >
    spawned_process and container and
    proc.name in (bash, sh, zsh)
  output: >
    Shell spawned in container (user=%user.name
    container=%container.name shell=%proc.name)
  priority: WARNING
```

### Trivy

```bash
trivy image myapp:1.0.0
trivy fs .
trivy config .
```

**Что происходит:** сканирование уязвимостей в образах, файлах, конфигурациях.

### Docker Bench

```bash
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /etc:/etc:ro \
  -v /usr/bin/containerd:/usr/bin/containerd:ro \
  -v /usr/bin/runc:/usr/bin/runc:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security
```

**Что происходит:** проверка конфигурации Docker на соответствие best practices.

---

## 09. Практические примеры

### Пример: безопасный Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

# Stage 1: сборка
FROM python:3.12.1-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: запуск
FROM python:3.12.1-slim

# Создаём пользователя
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Копируем зависимости
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .

# Переменные
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Пользователь
USER appuser

# Порт
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

# Команда
CMD ["python", "app.py"]
```

### Пример: безопасный запуск

```bash
docker run -d \
  --name app \
  --user 1000:1000 \
  --read-only \
  --tmpfs /tmp:size=100m \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --security-opt no-new-privileges \
  --security-opt seccomp=default \
  --security-opt apparmor=docker-default \
  --memory 512m \
  --memory-swap 512m \
  --cpus 1.5 \
  --pids-limit 100 \
  --network app-net \
  --restart unless-stopped \
  -p 127.0.0.1:8080:8080 \
  myapp:1.0.0
```

**Что происходит:**

| Флаг | Что делает |
|------|------------|
| `--user 1000:1000` | Не root |
| `--read-only` | ФС только для чтения |
| `--tmpfs /tmp` | `/tmp` в памяти |
| `--cap-drop=ALL` | Убираем все capabilities |
| `--cap-add=NET_BIND_SERVICE` | Добавляем только нужную |
| `--security-opt no-new-privileges` | Запрет повышения привилегий |
| `--security-opt seccomp=default` | Профиль seccomp |
| `--security-opt apparmor=docker-default` | Профиль AppArmor |
| `--memory 512m` | Лимит памяти |
| `--memory-swap 512m` | Без swap |
| `--cpus 1.5` | Лимит CPU |
| `--pids-limit 100` | Лимит процессов |
| `--network app-net` | Изолированная сеть |
| `-p 127.0.0.1:8080:8080` | Только localhost |

### Пример: Docker Compose с безопасностью

```yaml
services:
  app:
    image: myapp:1.0.0
    user: "1000:1000"
    read_only: true
    tmpfs:
      - /tmp:size=100m
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
      - seccomp:default
      - apparmor:docker-default
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.5'
    pids_limit: 100
    networks:
      - app-net
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"]
      interval: 30s
      timeout: 3s
      retries: 3

networks:
  app-net:
```

### Пример: секреты в Docker Compose

```yaml
services:
  app:
    image: myapp:1.0.0
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true
```

**Что происходит:** секреты монтируются в `/run/secrets/`.

```python
# app.py
with open('/run/secrets/db_password') as f:
    password = f.read().strip()
```

### Пример: сканирование уязвимостей в CI

```yaml
name: Security Scan

on:
  push:
    branches: [main]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Upload results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
```

**Что происходит:** при пуше в `main` образ сканируется. Если есть критические уязвимости — сборка падает.

---

## 10. Чек-лист безопасности

### Образы

- [ ] Минимальный базовый образ
- [ ] Фиксированные версии
- [ ] Digest вместо тегов
- [ ] Multi-stage build
- [ ] Не root пользователь
- [ ] Нет секретов в образе
- [ ] Сканирование уязвимостей
- [ ] Подпись образов
- [ ] Регулярное обновление

### Runtime

- [ ] `--user` (не root)
- [ ] `--read-only`
- [ ] `--tmpfs` для временных файлов
- [ ] `--cap-drop=ALL`
- [ ] `--cap-add` только нужные
- [ ] `--security-opt no-new-privileges`
- [ ] `--security-opt seccomp=default`
- [ ] `--security-opt apparmor=docker-default`
- [ ] Лимиты ресурсов (`--memory`, `--cpus`, `--pids-limit`)
- [ ] `--restart unless-stopped`

### Сеть

- [ ] Изоляция сетей
- [ ] Не пробрасывать порты без необходимости
- [ ] `127.0.0.1` для локальных сервисов
- [ ] Reverse proxy
- [ ] TLS
- [ ] Firewall

### Секреты

- [ ] Не в образе
- [ ] Не в `ENV`
- [ ] Не в `docker inspect`
- [ ] Docker secrets или внешнее хранилище
- [ ] tmpfs для секретов
- [ ] Ротация секретов

### Мониторинг

- [ ] Логи
- [ ] Аудит
- [ ] Falco
- [ ] Trivy
- [ ] Docker Bench

### Хост

- [ ] Обновление ядра
- [ ] Обновление Docker
- [ ] User namespace remapping
- [ ] Ограничение доступа к Docker socket
- [ ] Аудит

---

## Итог раздела

| Тема | Что даёт |
|------|----------|
| **Модель угроз** | Понимание, чего боимся |
| **Изоляция** | Namespaces, cgroups, capabilities |
| **Пользователи** | Не root, read-only |
| **Секреты** | Не в образе |
| **Образы** | Минимальные, проверенные |
| **Runtime** | seccomp, AppArmor, SELinux |
| **Сеть** | Изоляция, TLS |
| **Мониторинг** | Логи, аудит, сканирование |

> **Главный вывод:** безопасность контейнера — это слои. Чем больше слоёв — тем сложнее атаковать. Принцип наименьших привилегий — основа.

**Ключевые правила:**

1. **Не запускайте от root** — `USER appuser`
2. **Убирайте capabilities** — `--cap-drop=ALL`
3. **Read-only ФС** — `--read-only`
4. **Лимиты ресурсов** — `--memory`, `--cpus`, `--pids-limit`
5. **Не храните секреты в образе** — Docker secrets
6. **Минимальные образы** — alpine, distroless, scratch
7. **Сканируйте уязвимости** — trivy, docker scout
8. **Изолируйте сети** — разные сети для разных слоёв
9. **Мониторьте** — Falco, аудит
10. **Обновляйте** — ядро, Docker, образы