# Сеть: нервная система

Когда CPU и диск чувствуют себя хорошо, нет нагрузки на память и свопинга, а приложение продолжает «тормозить» — скорее всего, проблема в сети. Как и в нервной системе организма, задержка или потеря сигнала здесь вызывает «онемение»: подвисшие соединения, таймауты, ошибки и фрустрация пользователей.

## ss

`ss` — быстрый и современный аналог классического `netstat`.

```bash
sudo ss -tulnp
```

Показывает список сокетов:
- `-t`: TCP
- `-u`: UDP
- `-l`: только слушающие (listening)
- `-n`: без попыток DNS-резолва (быстрее)
- `-p`: процесс, который открыл сокет

Если нужный порт не отображается — возможно, служба не запущена или слушает не на том интерфейсе.

```bash
sudo ss -s
```

Даёт краткую сводку TCP-состояний (ESTABLISHED, TIME_WAIT, CLOSE_WAIT и др.). Большое количество `CLOSE_WAIT` часто говорит о проблеме в приложении, которое не закрывает соединения корректно.

### Пример: открытие соединений без закрытия

Приведённый ниже Python-скрипт демонстрирует два режима работы, позволяющих наблюдать состояния `TIME_WAIT` и `CLOSE_WAIT`.

```python
import socket
import threading
import time
import sys

HOST = "127.0.0.1"
PORT = 9090

MODE = "timewait"  # по умолчанию
if len(sys.argv) > 1:
    MODE = sys.argv[1].lower()

print(f"Running in mode: {MODE.upper()}")


def server():
    """TCP сервер — поведение зависит от MODE"""
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((HOST, PORT))
    srv.listen(5)
    print(f"Server listening on {HOST}:{PORT}")

    while True:
        conn, addr = srv.accept()
        print(f"Accepted connection from {addr}")

        if MODE == "timewait":
            # TIME_WAIT сценарий — эхо и закрытие
            data = conn.recv(1024)
            print(f"Server received: {data}")
            conn.sendall(b"Bye")
            conn.close()
        elif MODE == "closewait":
            # CLOSE_WAIT сценарий — сразу закрываем серверную сторону
            conn.shutdown(socket.SHUT_RDWR)
            conn.close()
            print("Server closed connection to trigger CLOSE_WAIT")
        else:
            print("Unknown mode!")
            conn.close()


def client_timewait():
    """Подключается и закрывается сам — TIME_WAIT"""
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((HOST, PORT))
            s.sendall(b"Hello server")
            data = s.recv(1024)
            print(f"Client got: {data}")
            s.close()
            print("Client closed socket (TIME_WAIT)")
        except Exception as e:
            print(e)
        time.sleep(0.5)


def client_closewait():
    """Подключается и НИЧЕГО не закрывает — CLOSE_WAIT"""
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((HOST, PORT))
            print("Client connected, waiting for server to close. This will trigger CLOSE_WAIT.")
            time.sleep(9999)  # Ждём, не закрываем сокет!
        except Exception as e:
            print(e)
        time.sleep(0.5)


if __name__ == "__main__":
    threading.Thread(target=server, daemon=True).start()

    if MODE == "timewait":
        threading.Thread(target=client_timewait, daemon=True).start()
    elif MODE == "closewait":
        threading.Thread(target=client_closewait, daemon=True).start()
    else:
        print("Unknown mode, exiting.")
        sys.exit(1)

    print("Server and client running. Check `ss -tan` or `ss -s`!")
    input("Press Enter to exit.\n")
```

**Запуск:**

- Для TIME_WAIT: `python sockets_demo.py timewait`
- Для CLOSE_WAIT: `python sockets_demo.py closewait`

- **`timewait`**: клиент подключается → шлёт → сервер отвечает и закрывает → клиент закрывает → сокет в TIME_WAIT.
- **`closewait`**: клиент подключается → сервер закрывает первым → клиент ничего не делает → CLOSE_WAIT у клиента.

Наблюдать состояния можно через `ss -s` или `ss -tan`.

## iftop и nload

Эти утилиты помогают ответить на вопросы: кто и куда/откуда передаёт данные?

```bash
sudo apt install -y iftop nload
sudo iftop -i enp0s3
nload enp0s3
```

- **iftop** — визуализирует активные TCP-соединения, показывая IP-адреса и объёмы трафика. Аналог top для сети.
- **nload** — простая графическая утилита, отображающая общий входящий и исходящий трафик по интерфейсу.

### Пример: нагрузка на сеть через speedtest

```bash
# установка пакета
sudo apt install -y python3-pip
pip3 install speedtest-cli
```

```python
import speedtest

def run_speedtest():
    st = speedtest.Speedtest()
    st.get_best_server()
    st.download()
    st.upload()
    print("Speedtest done!")

if __name__ == "__main__":
    run_speedtest()
```

## sar -n DEV

```bash
sar -n DEV 1 5
```

Показывает количество пакетов и байтов, входящих и исходящих (`rxpck/s`, `txpck/s`, `rxkB/s`, `txkB/s`). Используется для диагностики перегрузки: если значения зашкаливают — это повод разобраться, откуда и куда идёт трафик.

### Пример: flood-трафик на loopback

```python
# Бомбим loopback ICMP-пакетами (не требует root)
import os
while True:
    os.system("ping -c 1 127.0.0.1 > /dev/null")
```

Можно наблюдать рост пакетов в `sar`, `ss`, `iftop`, `ip -s link show lo`.

## ip -s link

Эта команда показывает здоровье сетевого интерфейса:

```bash
ip -s link show enp0s8
```

```text
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:a6:67:a7 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped overrun mcast
    72794      739      0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    2166       29       0       0       0       0
```

**Разбор вывода:**

| Часть | Описание |
|-------|----------|
| **Первая строка** | |
| `3:` | Порядковый номер интерфейса в системе |
| `enp0s8:` | Имя сетевого интерфейса (Predictable Network Interface Names) |
| `<BROADCAST,MULTICAST,UP,LOWER_UP>` | Флаги интерфейса: поддержка широковещательных пакетов, мультикаст, интерфейс включён, физически подключён |
| `mtu 1500` | Максимальный размер пакета (стандарт для Ethernet) |
| `qdisc fq_codel` | Алгоритм управления очередью пакетов |
| `state UP` | Текущее состояние интерфейса: работает |
| `qlen 1000` | Длина очереди передачи |
| **Вторая строка** | |
| `link/ether` | Ethernet-интерфейс |
| `08:00:27:a6:67:a7` | MAC-адрес интерфейса |
| `brd` | Широковещательный адрес |
| **RX (Receive) — приём** | |
| `bytes` | Общее количество принятых байтов |
| `packets` | Количество принятых пакетов |
| `errors` | Ошибки при приёме (CRC, повреждённые кадры) |
| `dropped` | Пакеты, отброшенные интерфейсом (переполнение буфера) |
| `overrun` | Переполнение приёмного буфера |
| `mcast` | Количество мультикаст-пакетов |
| **TX (Transmit) — передача** | |
| `bytes` | Количество отправленных байтов |
| `packets` | Количество отправленных пакетов |
| `errors` | Ошибки при передаче |
| `dropped` | Пакеты, отброшенные при отправке |
| `carrier` | Ошибки несущей (проблемы с кабелем) |
| `collsns` | Коллизии (актуально для Half-Duplex) |

## Современные альтернативы

| Название | Описание |
|----------|----------|
| [bmon](https://github.com/tgraf/bmon) | Графическая утилита для мониторинга сетевых интерфейсов с красивыми графиками |
| [bandwhich](https://github.com/imsnif/bandwhich) | Отображает сетевой трафик в реальном времени, включая адреса и процессы. Написана на Rust |
| [gping](https://github.com/orf/gping) | Графический ping с анимацией в терминале |
| [iptraf-ng](https://github.com/iptraf-ng/iptraf-ng) | Полноэкранная curses-утилита для мониторинга сетевого трафика по интерфейсам и IP-адресам |
| [Wireshark / TShark](https://www.wireshark.org/) | Самый мощный сниффер и анализатор пакетов. TShark — CLI-версия |