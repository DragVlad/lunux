# 09. Реестры и образы

## О чём этот раздел

Образы нужно где-то хранить и откуда-то скачивать. Для этого существуют **реестры (registries)**. Разберём, как работают реестры, как публиковать свои образы и как управлять версиями.

| Тема | Что даёт |
|------|----------|
| **Реестры** | Где хранятся образы |
| **Docker Hub** | Публичный реестр |
| **Приватные реестры** | Свой реестр |
| **Публикация** | Как выложить образ |
| **Теги** | Управление версиями |
| **Digest** | Неизменяемые ссылки |

> **Ключевая мысль:** образ — это артефакт. Его нужно хранить, версионировать и распространять. Реестр — это место для этого.

---

## 01. Что такое реестр

### Определение

**Реестр (registry)** — это сервер, который хранит образы и предоставляет к ним доступ по HTTP API.

**Что хранит реестр:**

- Слои образов (blobs)
- Манифесты (описание образа)
- Теги (метки версий)

### Как это работает

```
docker pull nginx:1.25
       │
       ▼
┌─────────────────┐
│  Docker CLI     │
└────────┬────────┘
         │ HTTP API
         ▼
┌─────────────────┐
│  Registry       │
│  (Docker Hub)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Слои + манифест│
└─────────────────┘
```

**Что происходит:**

1. CLI отправляет запрос в реестр
2. Реестр возвращает манифест
3. CLI скачивает слои, которых нет локально
4. CLI собирает образ из слоёв

### Основные реестры

| Реестр | Описание |
|--------|----------|
| **Docker Hub** | Публичный, по умолчанию |
| **GitHub Container Registry** | `ghcr.io` |
| **Google Artifact Registry** | `gcr.io` |
| **AWS ECR** | `*.dkr.ecr.*.amazonaws.com` |
| **Azure ACR** | `*.azurecr.io` |
| **GitLab Registry** | `registry.gitlab.com` |
| **Приватный** | Свой реестр |

### Формат имени образа

```
[registry/][namespace/]repository[:tag][@digest]
```

| Часть | Пример | Что означает |
|-------|--------|--------------|
| `registry` | `ghcr.io` | Адрес реестра |
| `namespace` | `myuser` | Пользователь или организация |
| `repository` | `myapp` | Имя образа |
| `tag` | `1.0.0` | Версия |
| `digest` | `sha256:abc...` | Хеш |

**Примеры:**

```
nginx:1.25
ubuntu:22.04
ghcr.io/myuser/myapp:1.0.0
123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

> **Важно:** если реестр не указан — используется Docker Hub. Если тег не указан — используется `latest`.

---

## 02. Docker Hub

### Что это

**Docker Hub** — это публичный реестр по умолчанию. Здесь хранятся официальные образы (`nginx`, `ubuntu`, `postgres`) и образы сообщества.

### Поиск образов

```bash
docker search nginx
```

**Что происходит:** вывод показывает образы:

```
NAME                DESCRIPTION                     STARS   OFFICIAL
nginx               Official build of Nginx.        19000   [OK]
jwilder/nginx-proxy Automated Nginx proxy         2000
```

| Колонка | Что означает |
|---------|--------------|
| `NAME` | Имя образа |
| `DESCRIPTION` | Описание |
| `STARS` | Количество звёзд |
| `OFFICIAL` | Официальный образ |

### Скачивание

```bash
docker pull nginx:1.25
```

**Что происходит:** Docker скачивает образ `nginx:1.25` из Docker Hub.

```bash
docker pull nginx
```

**Что происходит:** скачивается `nginx:latest`.

### Официальные образы

| Образ | Что это |
|-------|---------|
| `nginx` | Веб-сервер |
| `ubuntu` | Ubuntu |
| `alpine` | Alpine Linux |
| `postgres` | PostgreSQL |
| `redis` | Redis |
| `python` | Python |
| `node` | Node.js |
| `golang` | Go |

> **Правило:** используйте официальные образы, если они есть. Они поддерживаются и обновляются.

### Лимиты Docker Hub

| Тип аккаунта | Лимит pull |
|--------------|------------|
| Анонимный | 100 за 6 часов |
| Бесплатный | 200 за 6 часов |
| Pro | Без лимита |

**Что происходит:** если превысить лимит — Docker вернёт ошибку `toomanyrequests`.

**Решение:**

- Авторизоваться: `docker login`
- Использовать другой реестр
- Использовать кэш

---

## 03. Авторизация

### docker login

```bash
docker login
```

**Что происходит:** Docker запрашивает логин и пароль. Учётные данные сохраняются в `~/.docker/config.json`.

```bash
docker login -u myuser
```

**Что происходит:** запрашивается только пароль.

```bash
docker login ghcr.io
```

**Что происходит:** авторизация в GitHub Container Registry.

### Токены

**Проблема:** использовать пароль небезопасно.

**Решение:** использовать токены доступа.

| Реестр | Где создать токен |
|--------|-------------------|
| Docker Hub | Account Settings → Security → New Access Token |
| GitHub | Settings → Developer settings → Personal access tokens |
| GitLab | Settings → Access Tokens |
| AWS ECR | `aws ecr get-login-password` |

```bash
echo $TOKEN | docker login -u myuser --password-stdin
```

**Что происходит:** токен передаётся через stdin, не попадает в историю команд.

### Выход

```bash
docker logout
docker logout ghcr.io
```

**Что происходит:** учётные данные удаляются.

### Где хранятся учётные данные

```bash
cat ~/.docker/config.json
```

**Что происходит:** вывод показывает:

```json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "base64-encoded-credentials"
    }
  }
}
```

> **Важно:** не коммитьте `~/.docker/config.json` в git.

---

## 04. Публикация образов

### Шаг 1: Собрать образ

```bash
docker build -t myuser/myapp:1.0.0 .
```

**Что происходит:** образ собирается с именем `myuser/myapp` и тегом `1.0.0`.

> **Важно:** имя образа должно совпадать с namespace в реестре. Для Docker Hub — `username/repository`.

### Шаг 2: Тегировать

```bash
docker tag myuser/myapp:1.0.0 myuser/myapp:latest
```

**Что происходит:** создаётся дополнительный тег `latest`, указывающий на тот же образ.

```bash
docker tag myapp:1.0.0 ghcr.io/myuser/myapp:1.0.0
```

**Что происходит:** создаётся тег для GitHub Container Registry.

### Шаг 3: Авторизоваться

```bash
docker login
```

**Что происходит:** авторизация в Docker Hub.

### Шаг 4: Отправить

```bash
docker push myuser/myapp:1.0.0
```

**Что происходит:** образ отправляется в Docker Hub. Слои, которые уже есть в реестре, не отправляются повторно.

```bash
docker push myuser/myapp:latest
```

**Что происходит:** отправляется тег `latest`.

```bash
docker push --all-tags myuser/myapp
```

**Что происходит:** отправляются все теги образа.

### Пример: полный цикл

```bash
# Собрать
docker build -t myuser/myapp:1.0.0 .

# Тегировать
docker tag myuser/myapp:1.0.0 myuser/myapp:latest

# Авторизоваться
docker login

# Отправить
docker push myuser/myapp:1.0.0
docker push myuser/myapp:latest
```

**Что происходит:** образ опубликован в Docker Hub.

### Скачивание своего образа

```bash
docker pull myuser/myapp:1.0.0
```

**Что происходит:** образ скачивается из Docker Hub.

---

## 05. Теги и версионирование

### Что такое тег

**Тег** — это метка, которая указывает на определённый образ. Тег может быть перезаписан.

```bash
docker tag myapp:1.0.0 myapp:latest
docker push myapp:latest
```

**Что происходит:** тег `latest` теперь указывает на `1.0.0`. Если завтра вы соберёте `2.0.0` и перетегируете `latest` — он будет указывать на `2.0.0`.

> **Важно:** тег `latest` — это не «последняя версия». Это просто тег по умолчанию. Он может указывать на что угодно.

### Стратегии версионирования

| Стратегия | Пример | Когда использовать |
|-----------|--------|-------------------|
| **Semantic Versioning** | `1.2.3` | Production |
| **Major.Minor** | `1.2` | Стабильные ветки |
| **Major** | `1` | Последняя в мажоре |
| **latest** | `latest` | Не рекомендуется |
| **Git SHA** | `abc1234` | CI/CD |
| **Date** | `2024-01-01` | Регулярные сборки |

### Пример: семантическое версионирование

```bash
docker build -t myapp:1.2.3 .
docker tag myapp:1.2.3 myapp:1.2
docker tag myapp:1.2.3 myapp:1
docker tag myapp:1.2.3 myapp:latest

docker push myapp:1.2.3
docker push myapp:1.2
docker push myapp:1
docker push myapp:latest
```

**Что происходит:**

- `1.2.3` — точная версия
- `1.2` — последняя в ветке 1.2
- `1` — последняя в мажоре 1
- `latest` — последняя

**Зачем это нужно:**

- `1.2.3` — для production (воспроизводимость)
- `1.2` — для автоматических обновлений в пределах ветки
- `1` — для автоматических обновлений в пределах мажора
- `latest` — для разработки

### Удаление тега

```bash
docker rmi myapp:1.0.0
```

**Что происходит:** тег удаляется локально. Образ остаётся, если есть другие теги.

```bash
docker rmi myapp:1.0.0 myapp:latest
```

**Что происходит:** удаляются оба тега. Образ удаляется.

### Удаление из реестра

```bash
docker push myuser/myapp:1.0.0
```

**Что происходит:** тег можно перезаписать, но не удалить через CLI. Удаление — через веб-интерфейс реестра или API.

---

## 06. Digest

### Что это

**Digest** — это SHA256-хеш образа. Он неизменяем.

```
myapp@sha256:abc123def456...
```

### Просмотр digest

```bash
docker images --digests
```

**Что происходит:** вывод показывает digest:

```
REPOSITORY   TAG   DIGEST                    IMAGE ID
myapp        1.0   sha256:abc123def456...    def456abc123
```

```bash
docker inspect myapp:1.0 | grep -A 5 '"RepoDigests"'
```

**Что происходит:** вывод показывает:

```json
"RepoDigests": [
  "myapp@sha256:abc123def456..."
]
```

### Использование digest

```bash
docker pull myapp@sha256:abc123def456...
```

**Что происходит:** скачивается конкретный образ по digest. Даже если тег `1.0` перезаписан — digest указывает на тот же образ.

```yaml
# docker-compose.yml
services:
  app:
    image: myapp@sha256:abc123def456...
```

**Что происходит:** используется конкретный образ. Воспроизводимость гарантирована.

> **Правило:** для production используйте digest, а не теги. Тег может быть перезаписан, digest — нет.

### Тег vs digest

| Характеристика | Тег | Digest |
|----------------|-----|--------|
| **Изменяемость** | Может быть перезаписан | Неизменяем |
| **Читаемость** | Человекочитаемый | Хеш |
| **Воспроизводимость** | Не гарантирована | Гарантирована |
| **Использование** | Development | Production |

---

## 07. Приватные реестры

### Зачем нужен свой реестр

| Причина | Что даёт |
|---------|----------|
| **Безопасность** | Образы не доступны публично |
| **Скорость** | Локальный реестр быстрее |
| **Контроль** | Свои политики |
| **Изоляция** | Нет зависимости от Docker Hub |

### Запуск локального реестра

```bash
docker run -d \
  --name registry \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  registry:2
```

**Что происходит:** запускается локальный реестр на порту 5000. Образы хранятся в томе `registry-data`.

### Тегирование для локального реестра

```bash
docker tag myapp:1.0.0 localhost:5000/myapp:1.0.0
```

**Что происходит:** образ тегируется для локального реестра.

### Отправка

```bash
docker push localhost:5000/myapp:1.0.0
```

**Что происходит:** образ отправляется в локальный реестр.

### Скачивание

```bash
docker pull localhost:5000/myapp:1.0.0
```

**Что происходит:** образ скачивается из локального реестра.

### Просмотр каталога

```bash
curl http://localhost:5000/v2/_catalog
```

**Что происходит:** вывод показывает:

```json
{"repositories":["myapp"]}
```

### Приватный реестр с авторизацией

```bash
docker run -d \
  --name registry \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  -v /path/to/auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2
```

**Что происходит:** реестр требует авторизацию.

**Создание htpasswd:**

```bash
mkdir -p /path/to/auth
docker run --rm --entrypoint htpasswd \
  httpd:2 -Bbn myuser mypassword > /path/to/auth/htpasswd
```

### Облачные реестры

**AWS ECR:**

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

docker tag myapp:1.0.0 \
  123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0.0

docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0.0
```

**GitHub Container Registry:**

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u myuser --password-stdin

docker tag myapp:1.0.0 ghcr.io/myuser/myapp:1.0.0
docker push ghcr.io/myuser/myapp:1.0.0
```

**Google Artifact Registry:**

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev

docker tag myapp:1.0.0 \
  us-central1-docker.pkg.dev/myproject/myrepo/myapp:1.0.0

docker push us-central1-docker.pkg.dev/myproject/myrepo/myapp:1.0.0
```

---

## 08. Управление образами

### Просмотр

```bash
docker images
docker images --filter "dangling=true"
docker images --filter "reference=myapp:*"
```

**Что происходит:** вывод показывает образы с фильтрами.

**Dangling images** — это образы без тегов (промежуточные слои).

### Удаление

```bash
docker rmi myapp:1.0.0
docker rmi $(docker images -q)
docker image prune
docker image prune -a
```

**Что происходит:**

- `rmi` — удаляет конкретный образ
- `prune` — удаляет dangling images
- `prune -a` — удаляет все неиспользуемые образы

### Экспорт и импорт

```bash
docker save myapp:1.0.0 -o myapp.tar
docker load -i myapp.tar
```

**Что происходит:** образ сохраняется в tar-файл и загружается обратно. Полезно для передачи без реестра.

```bash
docker save myapp:1.0.0 | gzip > myapp.tar.gz
docker load < myapp.tar.gz
```

**Что происходит:** сжатие при сохранении.

### Копирование между реестрами

```bash
docker pull myuser/myapp:1.0.0
docker tag myuser/myapp:1.0.0 ghcr.io/myuser/myapp:1.0.0
docker push ghcr.io/myuser/myapp:1.0.0
```

**Что происходит:** образ копируется из Docker Hub в GitHub Container Registry.

### Инструменты

| Инструмент | Что делает |
|------------|------------|
| **skopeo** | Копирование между реестрами без скачивания |
| **crane** | Управление образами |
| **dive** | Анализ слоёв |
| **trivy** | Сканирование уязвимостей |

```bash
skopeo copy docker://myuser/myapp:1.0.0 docker://ghcr.io/myuser/myapp:1.0.0
```

**Что происходит:** образ копируется напрямую между реестрами.

---

## 09. Безопасность

### Сканирование уязвимостей

```bash
docker scout cves myapp:1.0.0
```

**Что происходит:** вывод показывает уязвимости в образе.

```bash
trivy image myapp:1.0.0
```

**Что происходит:** альтернативный сканер.

### Подпись образов

```bash
docker trust sign myapp:1.0.0
```

**Что происходит:** образ подписывается. При скачивании проверяется подпись.

### Content Trust

```bash
export DOCKER_CONTENT_TRUST=1
docker pull myapp:1.0.0
```

**Что происходит:** Docker проверяет подпись образа. Если подписи нет — скачивание не происходит.

### Best practices

| Практика | Почему |
|----------|--------|
| **Используйте официальные образы** | Проверены |
| **Фиксируйте версии** | Воспроизводимость |
| **Используйте digest** | Неизменяемость |
| **Сканируйте уязвимости** | Безопасность |
| **Не храните секреты** | Утечка |
| **Приватные реестры** | Контроль |
| **Подписывайте образы** | Целостность |

---

## 10. Практические примеры

### Пример: публикация в Docker Hub

```bash
# Собрать
docker build -t myuser/myapp:1.0.0 .

# Тегировать
docker tag myuser/myapp:1.0.0 myuser/myapp:latest

# Авторизоваться
docker login

# Отправить
docker push myuser/myapp:1.0.0
docker push myuser/myapp:latest

# Проверить
docker pull myuser/myapp:1.0.0
```

### Пример: локальный реестр

```bash
# Запустить реестр
docker run -d --name registry -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  registry:2

# Тегировать
docker tag myapp:1.0.0 localhost:5000/myapp:1.0.0

# Отправить
docker push localhost:5000/myapp:1.0.0

# Скачать
docker pull localhost:5000/myapp:1.0.0

# Просмотреть каталог
curl http://localhost:5000/v2/_catalog
```

### Пример: CI/CD с GitHub Actions

```yaml
name: Build and Push

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.ref_name }}
            ghcr.io/${{ github.repository }}:latest
```

**Что происходит:** при пуше тега `v*` образ собирается и публикуется в GHCR.

### Пример: multi-arch образ

```bash
docker buildx create --name mybuilder --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myuser/myapp:1.0.0 \
  --push .
```

**Что происходит:** собирается образ для двух архитектур. При скачивании Docker выберет подходящую.

---

## Итог раздела

| Тема | Что даёт |
|------|----------|
| **Реестры** | Хранение и распространение образов |
| **Docker Hub** | Публичный реестр |
| **Авторизация** | Доступ к приватным образам |
| **Публикация** | `docker push` |
| **Теги** | Версионирование |
| **Digest** | Неизменяемые ссылки |
| **Приватные реестры** | Свой реестр |
| **Безопасность** | Сканирование и подпись |

> **Главный вывод:** образ — это артефакт. Реестр — это место для его хранения. Тег — это версия. Digest — это неизменяемая ссылка.

**Ключевые правила:**

1. **Используйте semantic versioning** для тегов
2. **Не используйте `latest`** в production
3. **Используйте digest** для воспроизводимости
4. **Сканируйте уязвимости** перед публикацией
5. **Не храните секреты** в образах
6. **Приватные реестры** для внутренних образов
7. **Multi-arch** для кроссплатформенности