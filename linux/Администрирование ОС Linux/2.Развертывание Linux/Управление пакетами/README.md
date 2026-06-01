# Управление пакетами в Linux

В Linux программное обеспечение поставляется в виде **пакетов**.

> **Пакет** — это архив, содержащий все необходимые файлы для установки программы: бинарные файлы, библиотеки, документацию и метаданные.
>
> **Пакетные менеджеры** — инструменты, автоматизирующие установку, обновление, конфигурацию и удаление ПО. Они обеспечивают целостность и согласованность системы.

---

## Основные пакетные менеджеры

| Менеджер | Дистрибутивы | Формат пакетов |
|----------|--------------|----------------|
| **APT** (Advanced Package Tool) | Debian, Ubuntu, Mint | `.deb` |
| **YUM / DNF** | Fedora, RHEL, CentOS | `.rpm` |

> [!note]
> DNF (Dandified YUM) — современная замена YUM в новых версиях Fedora и RHEL.

---

## Сравнение команд: APT vs YUM/DNF

| Задача | APT | YUM / DNF |
|--------|-----|-----------|
| Обновление списка пакетов | `sudo apt update` | `sudo yum update` / `sudo dnf update` |
| Обновление всех пакетов | `sudo apt upgrade` | (то же самое, что выше) |
| Установка пакета | `sudo apt install package_name` | `sudo yum install package_name` / `sudo dnf install package_name` |
| Удаление пакета | `sudo apt remove package_name` | `sudo yum remove package_name` / `sudo dnf remove package_name` |
| Поиск пакета | `apt search package_name` | `yum search package_name` / `dnf search package_name` |
| Информация о пакете | `apt show package_name` | `yum info package_name` / `dnf info package_name` |
| Удаление неиспользуемых пакетов | `sudo apt autoremove` | — |

---

## Репозитории

Пакетные менеджеры работают с **репозиториями** — серверами, хранящими пакеты и метаданные. Репозитории бывают:

- **Официальные** — поддерживаются разработчиками дистрибутива
- **Неофициальные** — созданы сообществом или сторонними организациями

### Репозитории в APT

Указываются в:
- `/etc/apt/sources.list`
- Файлах внутри `/etc/apt/sources.list.d/`

**Пример строки репозитория:**
```bash
deb http://archive.ubuntu.com/ubuntu/ focal main restricted
```

| Элемент | Значение |
|---------|----------|
| `deb` | Бинарные пакеты (deb-src — исходные коды) |
| `http://...` | URL репозитория |
| `focal` | Кодовое имя релиза (Ubuntu 20.04) |
| `main`, `restricted` | Разделы репозитория |

### Репозитории в YUM/DNF

Указываются в файлах `.repo` внутри `/etc/yum.repos.d/`

**Пример файла .repo:**
```ini
[base]
name=CentOS-$releasever - Base
baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
```

| Элемент | Значение |
|---------|----------|
| `[base]` | Имя репозитория |
| `name` | Человеко-читаемое имя |
| `baseurl` | URL репозитория |
| `gpgcheck` | Проверка подписи (1 — включена) |
| `gpgkey` | Путь к GPG-ключу |

---

## GPG-подпись репозиториев

Для безопасности и целостности пакетов используется **цифровая подпись с помощью GPG-ключей**. Ключи хранятся в системе и проверяют, что пакеты подписаны доверенным источником и не были изменены.

---

## Работа с PPA в Ubuntu (Personal Package Archive)

> **PPA** — личные архивы пакетов на сервисе Launchpad. Позволяют получать ПО, не входящее в официальные репозитории.

| Действие | Команда |
|----------|---------|
| Добавление PPA | `sudo add-apt-repository ppa:graphics-drivers/ppa`<br>`sudo apt update` |
| Удаление PPA | `sudo add-apt-repository --remove ppa:graphics-drivers/ppa`<br>`sudo apt update` |

### Ручное добавление PPA

```bash
# Добавление репозитория
echo "deb http://ppa.launchpad.net/graphics-drivers/ppa/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/graphics-drivers-ppa.list

# Добавление GPG-ключа
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABCDEFGH12345678

# Обновление списка пакетов
sudo apt update
```

---

## Добавление сторонних репозиториев

### APT (на примере Nginx)

```bash
# Добавление репозитория
echo "deb http://nginx.org/packages/ubuntu/ focal nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

# Добавление GPG-ключа
wget -qO - https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

# Установка
sudo apt update
sudo apt install nginx
```

### YUM/DNF (на примере Nginx)

Создайте файл `/etc/yum.repos.d/nginx.repo`:

```ini
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
```

```bash
# Импорт ключа
sudo rpm --import https://nginx.org/keys/nginx_signing.key

# Установка
sudo yum update    # или dnf update
sudo yum install nginx    # или dnf install nginx
```

---

## Удаление репозитория

| Система | Действие |
|---------|----------|
| **APT** | Удалить строку из `/etc/apt/sources.list` или файл из `/etc/apt/sources.list.d/` |
| **YUM/DNF** | Удалить `.repo`-файл из `/etc/yum.repos.d/` |

---

## Итог

Пакетные менеджеры — основа управления ПО в Linux. Понимание различий между APT и YUM/DNF необходимо для работы с разными семействами дистрибутивов.

> [!tip]
> Независимо от менеджера, перед установкой пакетов из сторонних репозиториев всегда проверяйте:
> 1. Корректность URL репозитория
> 2. Наличие и подлинность GPG-ключа
> 3. Совместимость с версией вашего дистрибутива