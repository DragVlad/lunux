# 05. Жизненный цикл контейнера

## О чём этот раздел

Мы разобрали, как устроен контейнер, как работает OCI и runc, как собрать образ из Dockerfile. Теперь разберём, **что происходит с контейнером от создания до удаления**. Это важно для понимания состояний, управления и отладки.

| Тема | Что даёт |
|------|----------|
| **Состояния** | Какие состояния бывают у контейнера |
| **Команды** | Как управлять жизненным циклом |
| **Сигналы** | Как Docker останавливает контейнеры |
| **Рестарт-политики** | Как автоматически перезапускать |
| **Healthcheck** | Как проверять здоровье |
| **Логи** | Как читать логи контейнера |
| **Отладка** | Как разбираться с проблемами |

> **Ключевая мысль:** контейнер — это процесс. У него есть жизненный цикл: создание, запуск, остановка, удаление. Docker управляет этим циклом, но всё, что происходит внутри, — это работа ядра Linux с процессами.

---

## 01. Состояния контейнера

### Почему это важно

Контейнер — не «маленькая виртуалка», которая живёт вечно. Это процесс. У процесса есть начало и конец. Если процесс завершился — контейнер остановился. Если процесс убит — контейнер убит. Если процесс приостановлен — контейнер приостановлен.

Понимание состояний даёт:

- **Предсказуемость** — вы знаете, что произойдёт при той или иной команде
- **Отладку** — если контейнер не запускается, вы понимаете, на каком этапе проблема
- **Управление** — вы можете останавливать, перезапускать, приостанавливать контейнеры

### Основные состояния

| Состояние | Что означает | Как попасть |
|-----------|--------------|-------------|
| **Created** | Контейнер создан, но не запущен | `docker create` |
| **Running** | Контейнер запущен, процесс работает | `docker start` / `docker run` |
| **Paused** | Контейнер приостановлен (процесс заморожен) | `docker pause` |
| **Stopped** | Контейнер остановлен | `docker stop` |
| **Exited** | Процесс завершился сам | (автоматически) |
| **Restarting** | Контейнер перезапускается | (автоматически) |
| **Dead** | Контейнер в состоянии ошибки | (редко) |
| **Removed** | Контейнер удалён | `docker rm` |

### Диаграмма жизненного цикла

```
┌─────────────┐
│   Created   │ ← docker create
└──────┬──────┘
       │ docker start
       ▼
┌─────────────┐
│   Running   │ ← docker run
└──────┬──────┘
       │
       ├── docker pause ──→ ┌─────────────┐
       │                    │   Paused    │
       │                    └──────┬──────┘
       │                           │ docker unpause
       │                           ▼
       │                    ┌─────────────┐
       │                    │   Running   │
       │                    └─────────────┘
       │
       ├── docker stop ───→ ┌─────────────┐
       │                    │   Stopped   │
       │                    └──────┬──────┘
       │                           │ docker start
       │                           ▼
       │                    ┌─────────────┐
       │                    │   Running   │
       │                    └─────────────┘
       │
       └── процесс завершился ──→ ┌─────────────┐
                                  │   Exited    │
                                  └──────┬──────┘
                                         │ docker rm
                                         ▼
                                  ┌─────────────┐
                                  │   Removed   │
                                  └─────────────┘
```

### Running vs Exited

**Running** — процесс работает. Контейнер занимает ресурсы: CPU, память, PID.

**Exited** — процесс завершился. Контейнер не занимает ресурсы, но всё ещё существует: его файловая система, метаданные, логи сохранены. Его можно запустить снова или удалить.

> **Важно:** остановленный контейнер — это не «мусор». Это сохранённое состояние. Если вы удалите контейнер — потеряете его верхний слой (все изменения файловой системы).

### Просмотр состояния

```bash
docker ps
```

**Что происходит:** вывод показывает только запущенные контейнеры:

```
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS         PORTS   NAMES
abc123def456   nginx   "nginx"   5 min ago Up 5 minutes   80/tcp  happy_tesla
```

```bash
docker ps -a
```

**Что происходит:** вывод показывает все контейнеры, включая остановленные:

```
CONTAINER ID   IMAGE   COMMAND   CREATED       STATUS                     PORTS   NAMES
abc123def456   nginx   "nginx"   5 min ago     Up 5 minutes               80/tcp  happy_tesla
def456abc123   ubuntu  "bash"    1 hour ago    Exited (0) 30 minutes ago          sad_einstein
```

| Колонка | Что означает |
|---------|--------------|
| `CONTAINER ID` | Уникальный ID контейнера |
| `IMAGE` | Образ, из которого создан |
| `COMMAND` | Команда запуска |
| `CREATED` | Когда создан |
| `STATUS` | Текущий статус |
| `PORTS` | Проброшенные порты |
| `NAMES` | Имя контейнера |

### Фильтрация по состоянию

```bash
docker ps -a --filter "status=exited"
docker ps -a --filter "status=running"
docker ps -a --filter "status=paused"
```

**Что происходит:** вывод показывает только контейнеры с указанным статусом.

### Детальный статус

```bash
docker inspect happy_tesla
```

**Что происходит:** вывод показывает JSON с полной информацией. Нас интересует секция `State`:

```json
"State": {
  "Status": "running",
  "Running": true,
  "Paused": false,
  "Restarting": false,
  "OOMKilled": false,
  "Dead": false,
  "Pid": 12345,
  "ExitCode": 0,
  "Error": "",
  "StartedAt": "2024-01-01T00:00:00Z",
  "FinishedAt": "0001-01-01T00:00:00Z"
}
```

| Поле | Что означает |
|------|--------------|
| `Status` | Текущий статус (`running`, `exited`, `paused`, `created`) |
| `Running` | Запущен ли процесс |
| `Paused` | Приостановлен ли |
| `Restarting` | Перезапускается ли |
| `OOMKilled` | Убит ли OOM Killer |
| `Dead` | В состоянии ошибки |
| `Pid` | PID процесса на хосте (0, если не запущен) |
| `ExitCode` | Код выхода (0 — успех, иначе — ошибка) |
| `Error` | Сообщение об ошибке |
| `StartedAt` | Когда запущен |
| `FinishedAt` | Когда остановлен |

> **Важно:** `Pid` — это PID процесса на **хосте**, а не внутри контейнера. Внутри контейнера процесс может быть PID 1, но на хосте у него будет другой PID.

### Быстрый просмотр состояния

```bash
docker inspect -f '{{.State.Status}}' happy_tesla
```

**Что происходит:** вывод показывает только статус:

```
running
```

```bash
docker inspect -f '{{.State.Pid}}' happy_tesla
```

**Что происходит:** вывод показывает PID процесса на хосте:

```
12345
```

---

## 02. Команды управления жизненным циклом

### Создание контейнера

```bash
docker create --name mycontainer nginx
```

**Что делает:** создаёт контейнер, но **не запускает** его.

**Что происходит:**

- Docker создаёт верхний слой (diff) для контейнера
- Docker создаёт метаданные в `/var/lib/docker/containers/<id>/`
- Docker формирует `config.json` для runc
- Процесс **не запускается**

**Зачем это нужно:**

- Настроить контейнер перед запуском
- Подготовить контейнер и запустить его позже
- Создать контейнер с определённой конфигурацией

```bash
docker create -it --name myubuntu ubuntu bash
docker start -ai myubuntu
```

**Что происходит:** контейнер создаётся, затем запускается с подключением к терминалу.

### Запуск контейнера

```bash
docker start mycontainer
```

**Что делает:** запускает остановленный контейнер.

**Что происходит:**

- Docker берёт существующий контейнер
- Формирует `config.json`
- Передаёт его в containerd → runc
- runc настраивает изоляцию и запускает процесс

```bash
docker start -a mycontainer
```

**Что делает:** запускает и подключается к выводу (attach).

```bash
docker start -i mycontainer
```

**Что делает:** запускает и подключается к stdin.

```bash
docker start -ai mycontainer
```

**Что делает:** запускает и подключается к stdin и stdout.

> **Важно:** `docker start` не создаёт новый контейнер — он запускает существующий. Все изменения файловой системы сохраняются.

### Запуск нового контейнера

```bash
docker run nginx
```

**Что делает:** это комбинация `docker create` + `docker start`.

**Что происходит:**

1. Docker создаёт контейнер (как `docker create`)
2. Docker запускает его (как `docker start`)
3. Docker подключается к выводу (если не указан `-d`)

```bash
docker run -d nginx
```

**Что делает:** создаёт и запускает контейнер в фоне.

**Что происходит:** `-d` (detached) — контейнер запускается в фоне, CLI возвращает управление.

```bash
docker run -it ubuntu bash
```

**Что делает:** создаёт и запускает контейнер с интерактивным терминалом.

**Что происходит:** `-it` — интерактивный терминал. Вы попадаете внутрь контейнера.

### Остановка контейнера

```bash
docker stop mycontainer
```

**Что делает:** останавливает запущенный контейнер.

**Что происходит:**

1. Docker отправляет процессу сигнал `SIGTERM`
2. Ждёт 10 секунд (по умолчанию)
3. Если процесс не завершился — отправляет `SIGKILL`

```bash
docker stop -t 30 mycontainer
```

**Что делает:** ждёт 30 секунд перед `SIGKILL`.

**Зачем это нужно:** если приложение должно корректно завершиться (закрыть соединения, сохранить данные), нужно дать ему время.

> **Важно:** `SIGTERM` — это «мягкая» остановка. Процесс может её обработать и завершиться корректно. `SIGKILL` — это «жёсткая» остановка. Процесс не может её обработать и убивается немедленно.

### Убийство контейнера

```bash
docker kill mycontainer
```

**Что делает:** немедленно убивает контейнер.

**Что происходит:** Docker отправляет `SIGKILL`. Процесс убивается немедленно, без возможности корректного завершения.

```bash
docker kill -s SIGUSR1 mycontainer
```

**Что делает:** отправляет указанный сигнал.

**Что происходит:** можно отправить любой сигнал: `SIGHUP`, `SIGUSR1`, `SIGUSR2` и т.д.

### Приостановка и возобновление

```bash
docker pause mycontainer
```

**Что делает:** приостанавливает все процессы в контейнере.

**Что происходит:** Docker использует cgroup freezer — процесс замораживается. Он не получает CPU, но остаётся в памяти.

```bash
docker unpause mycontainer
```

**Что делает:** возобновляет процессы.

**Что происходит:** процесс размораживается и продолжает работу с того же места.

**Зачем это нужно:**

- Временное освобождение CPU
- Отладка
- Миграция контейнера

### Перезапуск

```bash
docker restart mycontainer
```

**Что делает:** останавливает и запускает контейнер заново.

**Что происходит:** это `docker stop` + `docker start`.

```bash
docker restart -t 30 mycontainer
```

**Что делает:** ждёт 30 секунд при остановке.

### Удаление

```bash
docker rm mycontainer
```

**Что делает:** удаляет остановленный контейнер.

**Что происходит:**

- Удаляется верхний слой (diff)
- Удаляются метаданные
- Удаляются логи

> **Важно:** удалить можно только остановленный контейнер. Если контейнер запущен — нужно сначала остановить его.

```bash
docker rm -f mycontainer
```

**Что делает:** удаляет контейнер принудительно, даже если он запущен.

**Что происходит:** Docker сначала убивает контейнер (`SIGKILL`), затем удаляет.

```bash
docker rm $(docker ps -aq)
```

**Что делает:** удаляет все остановленные контейнеры.

```bash
docker container prune
```

**Что делает:** удаляет все остановленные контейнеры.

### Автоматическое удаление

```bash
docker run --rm nginx
```

**Что делает:** запускает контейнер и удаляет его после остановки.

**Что происходит:** `--rm` — контейнер удаляется автоматически, когда процесс завершается. Это удобно для одноразовых задач.

```bash
docker run --rm -it ubuntu bash
```

**Что происходит:** вы попадаете внутрь контейнера. Когда вы выходите (`exit`), контейнер удаляется.

### Переименование

```bash
docker rename old_name new_name
```

**Что делает:** переименовывает контейнер.

**Что происходит:** имя контейнера меняется. Это удобно, если вы создали контейнер с автоматическим именем и хотите дать ему осмысленное.

---

## 03. Сигналы и остановка

### Как Docker останавливает контейнеры

Когда вы запускаете `docker stop`, происходит следующее:

```
1. Docker отправляет SIGTERM процессу с PID 1 в контейнере
2. Процесс должен обработать SIGTERM и завершиться
3. Docker ждёт 10 секунд (по умолчанию)
4. Если процесс не завершился — Docker отправляет SIGKILL
5. Процесс убивается немедленно
```

### Почему это важно

**Проблема:** если процесс не обрабатывает `SIGTERM`, он будет убит через 10 секунд. Это может привести к:

- Потере данных
- Повреждению файлов
- Некорректному завершению транзакций

**Решение:** процесс должен обрабатывать `SIGTERM` и корректно завершаться.

### PID 1 и сигналы

**Важно:** в контейнере процесс с PID 1 имеет особый статус. Ядро Linux игнорирует сигналы по умолчанию для PID 1. Это значит, что если процесс не обрабатывает `SIGTERM` явно, он его проигнорирует.

**Проблема:** многие приложения не рассчитаны на работу в качестве PID 1. Они не обрабатывают `SIGTERM` и не «усыновляют» дочерние процессы.

**Решение:** использовать init-процесс (например, `tini`) или запускать приложение через shell.

### Пример: проблема с PID 1

```dockerfile
FROM ubuntu
CMD ["sleep", "infinity"]
```

```bash
docker run -d --name test ubuntu sleep infinity
docker stop test
```

**Что происходит:** `sleep` не обрабатывает `SIGTERM`. Docker ждёт 10 секунд, затем отправляет `SIGKILL`. Контейнер останавливается, но не корректно.

### Решение: tini

```dockerfile
FROM ubuntu
RUN apt-get update && apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]
```

**Что происходит:** `tini` — это минимальный init-процесс. Он:

- Запускается как PID 1
- Обрабатывает сигналы
- Передаёт их дочерним процессам
- «Усыновляет» зомби-процессы

```bash
docker run -d --name test myimage
docker stop test
```

**Что происходит:** `tini` получает `SIGTERM`, передаёт его `sleep`, `sleep` завершается, контейнер останавливается корректно.

### Docker и tini

Docker имеет встроенную поддержку init-процесса:

```bash
docker run --init nginx
```

**Что делает:** Docker запускает `tini` как PID 1.

**Что происходит:** `tini` обрабатывает сигналы и «усыновляет» дочерние процессы.

> **Правило:** если ваше приложение не рассчитано на работу в качестве PID 1, используйте `--init` или добавляйте `tini` в Dockerfile.

### Обработка сигналов в приложении

**Python:**

```python
import signal
import sys
import time

def handle_sigterm(signum, frame):
    print("Received SIGTERM, shutting down...")
    # Закрыть соединения, сохранить данные
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)

while True:
    print("Working...")
    time.sleep(1)
```

**Node.js:**

```javascript
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down...');
  // Закрыть соединения, сохранить данные
  process.exit(0);
});

setInterval(() => {
  console.log('Working...');
}, 1000);
```

**Go:**

```go
package main

import (
    "fmt"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGTERM)

    go func() {
        <-sigChan
        fmt.Println("Received SIGTERM, shutting down...")
        os.Exit(0)
    }()

    for {
        fmt.Println("Working...")
        time.Sleep(time.Second)
    }
}
```

### Graceful shutdown

**Graceful shutdown** — это корректное завершение работы:

1. Получить `SIGTERM`
2. Перестать принимать новые запросы
3. Дождаться завершения текущих запросов
4. Закрыть соединения с БД, Redis и т.д.
5. Сохранить состояние
6. Завершиться с кодом 0

```python
import signal
import sys
import time

running = True

def handle_sigterm(signum, frame):
    global running
    print("Received SIGTERM, starting graceful shutdown...")
    running = False

signal.signal(signal.SIGTERM, handle_sigterm)

while running:
    print("Handling request...")
    time.sleep(1)

print("Closing connections...")
time.sleep(2)
print("Saving state...")
time.sleep(1)
print("Shutdown complete")
sys.exit(0)
```

**Что происходит:** при получении `SIGTERM` приложение перестаёт обрабатывать новые запросы, завершает текущие, закрывает соединения и завершается.

### Таймаут остановки

```bash
docker stop -t 30 mycontainer
```

**Что делает:** ждёт 30 секунд перед `SIGKILL`.

**Зачем это нужно:** если приложению нужно больше 10 секунд для graceful shutdown, увеличьте таймаут.

```bash
docker run -d --stop-timeout 30 nginx
```

**Что делает:** устанавливает таймаут остановки при запуске.

### Коды выхода

```bash
docker ps -a
```

**Что происходит:** вывод показывает код выхода:

```
CONTAINER ID   IMAGE   STATUS
abc123def456   nginx   Exited (0) 5 minutes ago
def456abc123   ubuntu  Exited (1) 10 minutes ago
```

| Код | Что означает |
|-----|--------------|
| `0` | Успешное завершение |
| `1` | Ошибка приложения |
| `137` | Убит `SIGKILL` (128 + 9) |
| `143` | Завершён `SIGTERM` (128 + 15) |
| `139` | Segmentation fault (128 + 11) |

**Что происходит:** код выхода помогает понять, почему контейнер остановился.

---

## 04. Рестарт-политики

### Что это

**Рестарт-политика** — это правило, которое определяет, должен ли Docker автоматически перезапускать контейнер при его завершении.

### Виды политик

| Политика | Что делает |
|----------|------------|
| `no` | Не перезапускать (по умолчанию) |
| `on-failure` | Перезапускать только при ошибке (код выхода ≠ 0) |
| `always` | Всегда перезапускать |
| `unless-stopped` | Всегда перезапускать, кроме случая ручной остановки |

### no

```bash
docker run -d --restart no nginx
```

**Что делает:** контейнер не перезапускается.

**Что происходит:** если процесс завершился — контейнер остаётся в состоянии `Exited`.

### on-failure

```bash
docker run -d --restart on-failure nginx
```

**Что делает:** контейнер перезапускается, если процесс завершился с ошибкой (код выхода ≠ 0).

**Что происходит:**

- Если процесс завершился с кодом 0 — контейнер не перезапускается
- Если процесс завершился с кодом ≠ 0 — контейнер перезапускается

```bash
docker run -d --restart on-failure:5 nginx
```

**Что делает:** перезапускает не более 5 раз.

**Что происходит:** после 5 неудачных попыток контейнер остаётся в состоянии `Exited`.

### always

```bash
docker run -d --restart always nginx
```

**Что делает:** контейнер всегда перезапускается.

**Что происходит:**

- Если процесс завершился — контейнер перезапускается
- Если Docker перезапустился — контейнер запускается автоматически
- Если контейнер остановлен вручную (`docker stop`) — он не перезапускается до перезапуска Docker

### unless-stopped

```bash
docker run -d --restart unless-stopped nginx
```

**Что делает:** контейнер перезапускается, кроме случая, когда он был остановлен вручную.

**Что происходит:**

- Если процесс завершился — контейнер перезапускается
- Если Docker перезапустился — контейнер запускается автоматически
- Если контейнер остановлен вручную (`docker stop`) — он **не** перезапускается даже после перезапуска Docker

### Сравнение

| Ситуация | `no` | `on-failure` | `always` | `unless-stopped` |
|----------|------|--------------|----------|------------------|
| Процесс завершился с кодом 0 | Не перезапускается | Не перезапускается | Перезапускается | Перезапускается |
| Процесс завершился с кодом ≠ 0 | Не перезапускается | Перезапускается | Перезапускается | Перезапускается |
| Docker перезапустился | Не перезапускается | Не перезапускается | Перезапускается | Перезапускается |
| Ручная остановка | Не перезапускается | Не перезапускается | Перезапускается после перезапуска Docker | Не перезапускается |

> **Правило:** для production используйте `unless-stopped`. Это самый предсказуемый вариант.

### Изменение политики

```bash
docker update --restart always mycontainer
```

**Что делает:** изменяет рестарт-политику существующего контейнера.

**Что происходит:** политика применяется без перезапуска контейнера.

### Задержка перезапуска

Docker использует экспоненциальную задержку между перезапусками:

```
1-й перезапуск: 100 мс
2-й перезапуск: 200 мс
3-й перезапуск: 400 мс
...
Максимум: 1 минута
```

**Что происходит:** это защищает от «штормов» перезапусков, когда контейнер падает сразу после запуска.

### Просмотр политики

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' mycontainer
```

**Что происходит:** вывод показывает политику:

```
always
```

---

## 05. Healthcheck

### Что это

**Healthcheck** — это проверка, которая определяет, здоров ли контейнер. Docker периодически запускает команду внутри контейнера и смотрит на код выхода.

### Зачем это нужно

**Проблема:** контейнер может быть запущен (`Running`), но приложение внутри может не работать. Например:

- Процесс запущен, но завис
- Приложение не может подключиться к БД
- Приложение возвращает ошибки

**Решение:** healthcheck. Docker проверяет, что приложение действительно работает.

### Статусы здоровья

| Статус | Что означает |
|--------|--------------|
| `starting` | Начальный период, проверки ещё не проходили |
| `healthy` | Проверка проходит |
| `unhealthy` | Проверка не проходит |

### Healthcheck в Dockerfile

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

| Параметр | Что означает | По умолчанию |
|----------|--------------|--------------|
| `--interval` | Интервал между проверками | 30s |
| `--timeout` | Таймаут проверки | 30s |
| `--start-period` | Время на запуск приложения | 0s |
| `--retries` | Количество неудачных проверок до `unhealthy` | 3 |

**Что происходит:**

1. Docker ждёт `start-period` (5 секунд)
2. Запускает проверку каждые `interval` (30 секунд)
3. Если проверка не завершилась за `timeout` (3 секунды) — считается неудачной
4. После `retries` (3) неудачных проверок — статус `unhealthy`

### Healthcheck при запуске

```bash
docker run -d \
  --health-cmd="curl -f http://localhost:8080/health || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  myapp
```

**Что делает:** устанавливает healthcheck при запуске контейнера.

### Просмотр статуса

```bash
docker ps
```

**Что происходит:** вывод показывает статус здоровья:

```
CONTAINER ID   IMAGE   STATUS                    PORTS
abc123def456   myapp   Up 5 minutes (healthy)    0.0.0.0:8080->8080/tcp
def456abc123   app2    Up 3 minutes (unhealthy)  0.0.0.0:8081->8080/tcp
```

```bash
docker inspect myapp | grep -A 10 '"Health"'
```

**Что происходит:** вывод показывает детальную информацию:

```json
"Health": {
  "Status": "healthy",
  "FailingStreak": 0,
  "Log": [
    {
      "Start": "2024-01-01T00:00:00Z",
      "End": "2024-01-01T00:00:01Z",
      "ExitCode": 0,
      "Output": "OK"
    }
  ]
}
```

| Поле | Что означает |
|------|--------------|
| `Status` | Текущий статус здоровья |
| `FailingStreak` | Количество неудачных проверок подряд |
| `Log` | История проверок |

### Пример: healthcheck для Python

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1
CMD ["python", "app.py"]
```

**Что происходит:** healthcheck использует Python для проверки HTTP-эндпоинта `/health`.

### Пример: healthcheck для Node.js

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY . .
RUN npm ci
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))" || exit 1
CMD ["node", "index.js"]
```

**Что происходит:** healthcheck использует Node.js для проверки HTTP-эндпоинта.

### Healthcheck для nginx

```dockerfile
FROM nginx
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
```

**Что происходит:** healthcheck проверяет, что nginx отвечает на запросы.

### Отключение healthcheck

```dockerfile
HEALTHCHECK NONE
```

**Что делает:** отключает healthcheck, унаследованный от базового образа.

### Healthcheck и рестарт

**Важно:** healthcheck **не** перезапускает контейнер. Он только помечает его как `unhealthy`.

**Что происходит:** если контейнер `unhealthy`, это может:

- Быть замечено оркестратором (Kubernetes, Swarm)
- Быть замечено мониторингом
- Не влиять на работу контейнера

**Решение:** для автоматического перезапуска используйте:

- `--restart on-failure` (перезапуск при завершении процесса)
- Оркестратор (Kubernetes убивает `unhealthy` поды)
- Внешний мониторинг

---

## 06. Логи

### Как Docker собирает логи

Docker собирает логи из **stdout** и **stderr** процесса. Всё, что процесс пишет в эти потоки, попадает в логи Docker.

**Что происходит:**

1. Процесс пишет в stdout/stderr
2. Docker перехватывает эти потоки
3. Docker сохраняет их в файл (или отправляет в драйвер логирования)

### Просмотр логов

```bash
docker logs mycontainer
```

**Что делает:** показывает все логи контейнера.

```bash
docker logs -f mycontainer
```

**Что делает:** показывает логи в реальном времени (follow).

```bash
docker logs --tail 100 mycontainer
```

**Что делает:** показывает последние 100 строк.

```bash
docker logs --since 2024-01-01T00:00:00 mycontainer
```

**Что делает:** показывает логи с указанного времени.

```bash
docker logs --until 2024-01-01T01:00:00 mycontainer
```

**Что делает:** показывает логи до указанного времени.

```bash
docker logs -t mycontainer
```

**Что делает:** показывает логи с временными метками.

### Пример

```bash
docker run -d --name test nginx
docker logs test
```

**Что происходит:** вывод показывает логи nginx:

```
/docker-entrypoint.sh: Configuration complete; ready for start up
2024/01/01 00:00:00 [notice] 1#1: nginx/1.25.3
2024/01/01 00:00:00 [notice] 1#1: built by gcc 12.2.0
```

### Драйверы логирования

Docker поддерживает несколько драйверов логирования:

| Драйвер | Что делает |
|---------|------------|
| `json-file` | Сохраняет логи в JSON-файл (по умолчанию) |
| `syslog` | Отправляет логи в syslog |
| `journald` | Отправляет логи в journald |
| `fluentd` | Отправляет логи в Fluentd |
| `awslogs` | Отправляет логи в AWS CloudWatch |
| `gcplogs` | Отправляет логи в Google Cloud Logging |
| `none` | Отключает логирование |

```bash
docker run -d --log-driver json-file nginx
docker run -d --log-driver syslog nginx
docker run -d --log-driver none nginx
```

### Настройка логирования

```bash
docker run -d \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  nginx
```

**Что происходит:**

- `max-size=10m` — максимальный размер файла логов (10 МБ)
- `max-file=3` — максимальное количество файлов (3)

**Зачем это нужно:** без ограничений логи могут занять всё место на диске.

### Где хранятся логи

```bash
ls /var/lib/docker/containers/<container-id>/
```

**Что происходит:** вывод показывает файлы:

```
<container-id>-json.log
```

```bash
cat /var/lib/docker/containers/<container-id>/<container-id>-json.log
```

**Что происходит:** вывод показывает логи в формате JSON:

```json
{"log":"Hello from nginx\n","stream":"stdout","time":"2024-01-01T00:00:00Z"}
```

| Поле | Что означает |
|------|--------------|
| `log` | Строка лога |
| `stream` | Поток (`stdout` или `stderr`) |
| `time` | Время |

### Логи и приложение

**Важно:** Docker собирает только то, что приложение пишет в **stdout** и **stderr**. Если приложение пишет в файл внутри контейнера — Docker это не увидит.

**Плохо:**

```python
import logging

logging.basicConfig(filename='/var/log/app.log', level=logging.INFO)
logging.info("Application started")
```

**Что происходит:** лог пишется в файл внутри контейнера. Docker его не видит. Файл будет расти и занимать место.

**Хорошо:**

```python
import logging
import sys

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logging.info("Application started")
```

**Что происходит:** лог пишется в stdout. Docker его перехватывает и сохраняет.

> **Правило:** приложение в контейнере должно писать логи в stdout/stderr. Не пишите логи в файлы внутри контейнера. Если нужны файлы — используйте тома.

### Логи и nginx

**Проблема:** nginx по умолчанию пишет логи в файлы `/var/log/nginx/access.log` и `/var/log/nginx/error.log`. Docker их не видит.

**Решение 1: симлинки на stdout/stderr**

```dockerfile
FROM nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
```

**Что происходит:** логи nginx пишутся в stdout/stderr, Docker их перехватывает.

**Решение 2: конфигурация nginx**

```nginx
access_log /dev/stdout;
error_log /dev/stderr;
```

**Что происходит:** nginx пишет логи напрямую в stdout/stderr.

### Логи и Docker Compose

```yaml
services:
  app:
    image: myapp
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

**Что происходит:** настройки логирования применяются ко всем контейнерам сервиса.

```bash
docker compose logs
docker compose logs -f
docker compose logs --tail 100 app
```

**Что происходит:** вывод показывает логи всех сервисов или конкретного сервиса.

---

## 07. Отладка контейнеров

### Проблема

Контейнер не запускается, падает, работает неправильно. Как разобраться?

### Шаг 1: Посмотреть статус

```bash
docker ps -a
```

**Что происходит:** вывод показывает статус:

```
CONTAINER ID   IMAGE   STATUS                     NAMES
abc123def456   myapp   Exited (1) 5 minutes ago   myapp
```

**Что означает:** контейнер завершился с кодом 1 — ошибка приложения.

### Шаг 2: Посмотреть логи

```bash
docker logs myapp
```

**Что происходит:** вывод показывает логи. Если приложение упало — здесь будет ошибка.

```bash
docker logs --tail 50 myapp
```

**Что происходит:** вывод показывает последние 50 строк.

### Шаг 3: Посмотреть детали

```bash
docker inspect myapp
```

**Что происходит:** вывод показывает JSON с полной информацией. Обратите внимание на:

```json
"State": {
  "Status": "exited",
  "ExitCode": 1,
  "Error": "",
  "OOMKilled": false
}
```

| Поле | Что означает |
|------|--------------|
| `ExitCode` | Код выхода |
| `Error` | Сообщение об ошибке |
| `OOMKilled` | Убит ли OOM Killer |

### Шаг 4: Запустить с другим entrypoint

```bash
docker run -it --entrypoint bash myapp
```

**Что делает:** запускает контейнер с `bash` вместо `CMD`.

**Что происходит:** вы попадаете внутрь контейнера. Можно проверить:

- Есть ли файлы на месте
- Работают ли команды
- Какие переменные окружения
- Какие права у файлов

```bash
docker run -it --entrypoint sh myapp
```

**Что происходит:** если `bash` нет — используйте `sh`.

### Шаг 5: Запустить и посмотреть, что происходит

```bash
docker run -it myapp
```

**Что происходит:** контейнер запускается в интерактивном режиме. Вы видите всё, что он пишет. Если он падает — вы видите ошибку.

### Шаг 6: Проверить конфигурацию

```bash
docker inspect myapp | grep -A 20 '"Config"'
```

**Что происходит:** вывод показывает конфигурацию:

```json
"Config": {
  "Hostname": "abc123def456",
  "Env": ["PATH=/usr/local/bin:/usr/bin:/bin"],
  "Cmd": ["python", "app.py"],
  "WorkingDir": "/app",
  "Entrypoint": null
}
```

### Шаг 7: Проверить сеть

```bash
docker inspect myapp | grep -A 20 '"NetworkSettings"'
```

**Что происходит:** вывод показывает сетевые настройки:

```json
"NetworkSettings": {
  "IPAddress": "172.17.0.2",
  "Ports": {
    "8080/tcp": [{"HostIp": "0.0.0.0", "HostPort": "8080"}]
  }
}
```

### Шаг 8: Проверить монтирования

```bash
docker inspect myapp | grep -A 20 '"Mounts"'
```

**Что происходит:** вывод показывает тома и bind mounts:

```json
"Mounts": [
  {
    "Type": "volume",
    "Name": "mydata",
    "Source": "/var/lib/docker/volumes/mydata/_data",
    "Destination": "/data"
  }
]
```

### Шаг 9: Проверить процессы

```bash
docker top myapp
```

**Что делает:** показывает процессы внутри контейнера.

**Что происходит:** вывод показывает процессы:

```
UID   PID   PPID   C   STIME   TTY   TIME   CMD
root  12345 12300  0   00:00   ?     00:00  python app.py
```

### Шаг 10: Проверить ресурсы

```bash
docker stats myapp
```

**Что делает:** показывает использование ресурсов в реальном времени.

**Что происходит:** вывод показывает:

```
CONTAINER ID   NAME    CPU %   MEM USAGE / LIMIT   MEM %   NET I/O       BLOCK I/O
abc123def456   myapp   0.50%   50MiB / 512MiB      9.77%   1.2kB / 0B    0B / 0B
```

### Шаг 11: Войти в запущенный контейнер

```bash
docker exec -it myapp bash
```

**Что делает:** запускает `bash` внутри запущенного контейнера.

**Что происходит:** вы попадаете внутрь контейнера. Можно:

- Посмотреть файлы
- Проверить переменные окружения
- Проверить сеть
- Запустить команды

```bash
docker exec -it myapp sh
```

**Что происходит:** если `bash` нет — используйте `sh`.

### Шаг 12: Скопировать файлы из контейнера

```bash
docker cp myapp:/app/logs/monitor.log ./monitor.log
```

**Что делает:** копирует файл из контейнера на хост.

```bash
docker cp ./config.json myapp:/app/config.json
```

**Что делает:** копирует файл с хоста в контейнер.

### Шаг 13: Проверить healthcheck

```bash
docker inspect myapp | grep -A 10 '"Health"'
```

**Что происходит:** вывод показывает статус здоровья и историю проверок.

### Шаг 14: Проверить события

```bash
docker events
```

**Что делает:** показывает события Docker в реальном времени.

```bash
docker events --filter container=myapp
```

**Что происходит:** вывод показывает события только для указанного контейнера.

### Шаг 15: Проверить логи ядра

```bash
dmesg | grep -i docker
dmesg | grep -i "killed process"
```

**Что происходит:** вывод показывает, не убил ли OOM Killer процесс контейнера.

### Пример: контейнер не запускается

```bash
docker run -d --name test myapp
docker ps -a
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE   STATUS                     NAMES
abc123def456   myapp   Exited (1) 2 seconds ago   test
```

**Шаг 1: Логи**

```bash
docker logs test
```

**Что происходит:** вывод показывает:

```
Traceback (most recent call last):
  File "/app/app.py", line 1, in <module>
    import flask
ModuleNotFoundError: No module named 'flask'
```

**Шаг 2: Проверяем Dockerfile**

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
```

**Что происходит:** забыли `RUN pip install -r requirements.txt`.

**Шаг 3: Исправляем**

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

**Шаг 4: Пересобираем и запускаем**

```bash
docker build -t myapp .
docker run -d --name test myapp
docker ps
```

**Что происходит:** контейнер запущен.

### Пример: контейнер падает через секунду

```bash
docker run -d --name test myapp
sleep 2
docker ps -a
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE   STATUS                     NAMES
abc123def456   myapp   Exited (0) 1 second ago    test
```

**Шаг 1: Логи**

```bash
docker logs test
```

**Что происходит:** вывод показывает:

```
Application started
Application finished
```

**Шаг 2: Понимаем проблему**

Приложение завершилось с кодом 0 — успех. Но контейнер остановился, потому что процесс завершился.

**Шаг 3: Решение**

Если приложение должно работать постоянно — оно не должно завершаться. Например, веб-сервер.

Если это одноразовая задача — используйте `--rm`:

```bash
docker run --rm myapp
```

**Что происходит:** контейнер запускается, выполняет задачу, завершается и удаляется.

### Пример: контейнер убит OOM Killer

```bash
docker run -d --memory 512m --name test myapp
docker ps -a
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE   STATUS                       NAMES
abc123def456   myapp   Exited (137) 2 minutes ago   test
```

**Шаг 1: Проверяем**

```bash
docker inspect test | grep -A 5 '"State"'
```

**Что происходит:** вывод показывает:

```json
"State": {
  "Status": "exited",
  "ExitCode": 137,
  "OOMKilled": true
}
```

**Шаг 2: Понимаем проблему**

`OOMKilled: true` — процесс убит OOM Killer. Он превысил лимит памяти 512 МБ.

**Шаг 3: Решение**

- Увеличить лимит: `--memory 1g`
- Оптимизировать приложение
- Проверить утечки памяти

### Пример: контейнер не отвечает

```bash
docker run -d -p 8080:80 --name test nginx
curl http://localhost:8080
```

**Что происходит:** `curl` не отвечает.

**Шаг 1: Проверяем статус**

```bash
docker ps
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE   STATUS         PORTS                  NAMES
abc123def456   nginx   Up 2 minutes   0.0.0.0:8080->80/tcp   test
```

Контейнер запущен, порт проброшен.

**Шаг 2: Проверяем внутри контейнера**

```bash
docker exec -it test bash
curl http://localhost:80
```

**Что происходит:** если внутри работает — проблема в пробросе портов. Если не работает — проблема в приложении.

**Шаг 3: Проверяем проброс**

```bash
docker port test
```

**Что происходит:** вывод показывает:

```
80/tcp -> 0.0.0.0:8080
```

**Шаг 4: Проверяем сеть**

```bash
docker inspect test | grep -A 10 '"NetworkSettings"'
```

**Что происходит:** вывод показывает IP-адрес контейнера.

```bash
curl http://172.17.0.2:80
```

**Что происходит:** если работает — проблема в пробросе портов на хост.

### Полезные команды для отладки

| Команда | Что делает |
|---------|------------|
| `docker logs` | Логи контейнера |
| `docker inspect` | Детальная информация |
| `docker exec` | Войти в запущенный контейнер |
| `docker top` | Процессы внутри контейнера |
| `docker stats` | Использование ресурсов |
| `docker events` | События Docker |
| `docker port` | Проброшенные порты |
| `docker cp` | Копировать файлы |
| `docker diff` | Изменения в файловой системе |

### docker diff

```bash
docker diff mycontainer
```

**Что делает:** показывает изменения в файловой системе контейнера.

**Что происходит:** вывод показывает:

```
A /app/newfile.txt
C /app/config.json
D /app/oldfile.txt
```

| Символ | Что означает |
|--------|--------------|
| `A` | Added (добавлен) |
| `C` | Changed (изменён) |
| `D` | Deleted (удалён) |

**Зачем это нужно:** понять, какие файлы изменились в контейнере.

---

## 08. Практические примеры

### Пример: контейнер с graceful shutdown

**Dockerfile:**

```dockerfile
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["python", "app.py"]
```

**app.py:**

```python
import signal
import sys
import time

running = True

def handle_sigterm(signum, frame):
    global running
    print("Received SIGTERM, starting graceful shutdown...")
    running = False

signal.signal(signal.SIGTERM, handle_sigterm)

print("Application started")
while running:
    print("Working...")
    time.sleep(1)

print("Closing connections...")
time.sleep(2)
print("Saving state...")
time.sleep(1)
print("Shutdown complete")
sys.exit(0)
```

**Запуск:**

```bash
docker build -t graceful-app .
docker run -d --name graceful graceful-app
docker stop graceful
docker logs graceful
```

**Что происходит:** вывод показывает:

```
Application started
Working...
Working...
Received SIGTERM, starting graceful shutdown...
Closing connections...
Saving state...
Shutdown complete
```

**Что произошло:** `tini` получил `SIGTERM`, передал его Python-процессу. Python обработал сигнал, корректно завершился.

### Пример: контейнер с healthcheck

**Dockerfile:**

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["python", "app.py"]
```

**app.py:**

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

@app.route('/')
def index():
    return jsonify({"message": "Hello, World!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

**Запуск:**

```bash
docker build -t health-app .
docker run -d --name health -p 8080:8080 health-app
sleep 15
docker ps
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE        STATUS                   PORTS
abc123def456   health-app   Up 15 seconds (healthy)  0.0.0.0:8080->8080/tcp
```

**Проверка:**

```bash
docker inspect health | grep -A 5 '"Health"'
```

**Что происходит:** вывод показывает:

```json
"Health": {
  "Status": "healthy",
  "FailingStreak": 0
}
```

### Пример: контейнер с рестарт-политикой

```bash
docker run -d --restart unless-stopped --name web nginx
```

**Что происходит:** контейнер запущен с политикой `unless-stopped`.

**Проверка:**

```bash
docker stop web
docker ps -a
```

**Что происходит:** контейнер остановлен:

```
CONTAINER ID   IMAGE   STATUS                     NAMES
abc123def456   nginx   Exited (0) 5 seconds ago   web
```

**Перезапуск Docker:**

```bash
sudo systemctl restart docker
sleep 5
docker ps -a
```

**Что происходит:** контейнер **не** перезапустился, потому что был остановлен вручную.

**Проверка с always:**

```bash
docker run -d --restart always --name web2 nginx
docker stop web2
sudo systemctl restart docker
sleep 5
docker ps -a
```

**Что происходит:** контейнер `web2` перезапустился, потому что политика `always`.

### Пример: отладка падающего контейнера

**Dockerfile:**

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
```

**app.py:**

```python
import nonexistent_module
print("Hello")
```

**Запуск:**

```bash
docker build -t broken-app .
docker run -d --name broken broken-app
docker ps -a
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE        STATUS                     NAMES
abc123def456   broken-app   Exited (1) 2 seconds ago   broken
```

**Отладка:**

```bash
docker logs broken
```

**Что происходит:** вывод показывает:

```
Traceback (most recent call last):
  File "/app/app.py", line 1, in <module>
    import nonexistent_module
ModuleNotFoundError: No module named 'nonexistent_module'
```

**Решение:** исправить `app.py` или добавить зависимость.

### Пример: контейнер с томом для логов

**Dockerfile:**

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN mkdir -p /var/log/app
CMD ["python", "app.py"]
```

**app.py:**

```python
import logging
import time

logging.basicConfig(
    filename='/var/log/app/monitor.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

while True:
    logging.info("Application is running")
    time.sleep(5)
```

**Запуск:**

```bash
docker build -t log-app .
docker run -d --name logapp -v /mnt/logs:/var/log/app log-app
```

**Что происходит:** том `/mnt/logs` на хосте монтируется в `/var/log/app` в контейнере. Логи пишутся в файл, который доступен на хосте.

**Проверка:**

```bash
cat /mnt/logs/monitor.log
```

**Что происходит:** вывод показывает:

```
2024-01-01 00:00:00,000 - Application is running
2024-01-01 00:00:05,000 - Application is running
```

### Пример: вход в запущенный контейнер и просмотр логов

```bash
docker build -t my_app .
docker run -d my_app
docker ps
```

**Что происходит:** вывод показывает:

```
CONTAINER ID   IMAGE    STATUS         NAMES
ddc6d494a8f5   my_app   Up 5 seconds   happy_tesla
```

```bash
docker exec -it ddc6d494a8f5 /bin/sh
```

**Что происходит:** вы попадаете внутрь контейнера.

```bash
cd /var/www/logs
ls
cat monitor.log
```

**Что происходит:** вывод показывает содержимое лога:

```
2024-01-01 00:00:00 - Application started
2024-01-01 00:00:05 - Request handled
2024-01-01 00:00:10 - Request handled
```

**Выход:**

```bash
exit
```

**Что происходит:** вы выходите из контейнера. Контейнер продолжает работать.

### Пример: монтирование волюма и nginx с самоподписанным сертификатом

**Шаг 1: Создаём том**

```bash
docker volume create nginx-data
```

**Что происходит:** создаётся именованный том `nginx-data`.

**Шаг 2: Создаём самоподписанный сертификат**

```bash
mkdir -p /mnt/logs/certs
cd /mnt/logs/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx.key \
  -out nginx.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=Dev/CN=localhost"
```

**Что происходит:** создаются файлы `nginx.key` и `nginx.crt` — приватный ключ и сертификат.

| Параметр | Что означает |
|----------|--------------|
| `-x509` | Создать самоподписанный сертификат |
| `-nodes` | Без пароля на ключ |
| `-days 365` | Срок действия — 365 дней |
| `-newkey rsa:2048` | Новый ключ RSA 2048 бит |
| `-keyout` | Файл для приватного ключа |
| `-out` | Файл для сертификата |
| `-subj` | Данные сертификата |

**Шаг 3: Создаём конфигурацию nginx**

```bash
mkdir -p /mnt/logs/nginx
cat > /mnt/logs/nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/certs/nginx.crt;
    ssl_certificate_key /etc/nginx/certs/nginx.key;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /logs/ {
        alias /var/log/nginx/;
        autoindex on;
    }
}
EOF
```

**Что происходит:** создаётся конфигурация nginx с:

- Редиректом с HTTP на HTTPS
- SSL-сертификатом
- Отдачей логов по `/logs/`

**Шаг 4: Запускаем nginx**

```bash
docker run -d \
  --name nginx-ssl \
  -p 80:80 \
  -p 443:443 \
  -v /mnt/logs/certs:/etc/nginx/certs:ro \
  -v /mnt/logs/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
  -v nginx-data:/var/log/nginx \
  nginx
```

**Что происходит:**

| Флаг | Что делает |
|------|------------|
| `-p 80:80` | Проброс HTTP-порта |
| `-p 443:443` | Проброс HTTPS-порта |
| `-v /mnt/logs/certs:/etc/nginx/certs:ro` | Монтирование сертификатов (только чтение) |
| `-v /mnt/logs/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro` | Монтирование конфигурации |
| `-v nginx-data:/var/log/nginx` | Том для логов |

**Шаг 5: Проверяем**

```bash
curl -k https://localhost
```

**Что происходит:** вывод показывает HTML-страницу nginx.

```bash
curl -k https://localhost/logs/
```

**Что происходит:** вывод показывает список файлов в `/var/log/nginx/`:

```
access.log
error.log
```

**Шаг 6: Смотрим логи**

```bash
docker exec -it nginx-ssl cat /var/log/nginx/access.log
```

**Что происходит:** вывод показывает:

```
127.0.0.1 - - [01/Jan/2024:00:00:00 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.81.0"
```

**Шаг 7: Монтирование волюма с UUID**

Если у вас есть отдельный диск с UUID `2874bb04-4132-4d84-9c7f-af1212c7693b`, монтируем его в `/mnt/logs`:

```bash
sudo mkdir -p /mnt/logs
sudo mount UUID="2874bb04-4132-4d84-9c7f-af1212c7693b" /mnt/logs
```

**Что происходит:** диск монтируется в `/mnt/logs`.

**Добавляем в `/etc/fstab` для автоматического монтирования:**

```
UUID="2874bb04-4132-4d84-9c7f-af1212c7693b" /mnt/logs    ext4  defaults  0 2
```

**Что происходит:** при загрузке системы диск автоматически монтируется в `/mnt/logs`.

**Проверка:**

```bash
df -h /mnt/logs
```

**Что происходит:** вывод показывает:

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1       100G  1.2G   99G   2% /mnt/logs
```

**Шаг 8: Перезапускаем nginx с новым монтированием**

```bash
docker stop nginx-ssl
docker rm nginx-ssl
docker run -d \
  --name nginx-ssl \
  -p 80:80 \
  -p 443:443 \
  -v /mnt/logs/certs:/etc/nginx/certs:ro \
  -v /mnt/logs/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
  -v /mnt/logs/nginx-logs:/var/log/nginx \
  nginx
```

**Что происходит:** логи nginx теперь пишутся в `/mnt/logs/nginx-logs` на отдельном диске.

**Проверка:**

```bash
ls /mnt/logs/nginx-logs/
```

**Что происходит:** вывод показывает:

```
access.log
error.log
```

### Пример: полный стек с Docker Compose

**docker-compose.yml:**

```yaml
services:
  nginx:
    image: nginx:1.25
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./certs:/etc/nginx/certs:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      - app
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 3s
      retries: 3

  app:
    build: .
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
      - REDIS_URL=redis://cache:6379
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

  db:
    image: postgres:16
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 10s
      timeout: 3s
      retries: 5

  cache:
    image: redis:7
    volumes:
      - cache-data:/data
    restart: unless-stopped

volumes:
  nginx-logs:
  db-data:
  cache-data:
```

**Запуск:**

```bash
docker compose up -d
docker compose ps
```

**Что происходит:** вывод показывает:

```
NAME                IMAGE          STATUS                   PORTS
project-app-1       project-app    Up 10 seconds (healthy)  8080/tcp
project-cache-1     redis:7        Up 10 seconds            6379/tcp
project-db-1        postgres:16    Up 10 seconds (healthy)  5432/tcp
project-nginx-1     nginx:1.25     Up 10 seconds (healthy)  0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

**Проверка:**

```bash
curl -k https://localhost
docker compose logs -f
```

**Что происходит:** вывод показывает логи всех сервисов в реальном времени.

---

## Итог раздела

Мы разобрали жизненный цикл контейнера:

| Тема | Что даёт |
|------|----------|
| **Состояния** | Понимание, в каком состоянии контейнер |
| **Команды** | Управление жизненным циклом |
| **Сигналы** | Как Docker останавливает контейнеры |
| **Рестарт-политики** | Автоматический перезапуск |
| **Healthcheck** | Проверка здоровья |
| **Логи** | Чтение и настройка логов |
| **Отладка** | Разбор проблем |

> **Главный вывод:** контейнер — это процесс. У него есть жизненный цикл: создание, запуск, остановка, удаление. Docker управляет этим циклом. Понимание жизненного цикла помогает:

> - Правильно останавливать контейнеры (graceful shutdown)
> - Настраивать автоматический перезапуск (рестарт-политики)
> - Проверять здоровье (healthcheck)
> - Отлаживать проблемы (логи, inspect, exec)

**Ключевые правила:**

1. **Обрабатывайте `SIGTERM`** — для корректного завершения
2. **Используйте `--init` или `tini`** — если приложение не рассчитано на PID 1
3. **Настраивайте `restart: unless-stopped`** — для production
4. **Добавляйте `healthcheck`** — для проверки здоровья
5. **Пишите логи в stdout/stderr** — Docker их перехватит
6. **Ограничивайте логи** — `max-size` и `max-file`
7. **Используйте `docker inspect`** — для отладки