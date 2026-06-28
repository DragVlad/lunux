# Установка и настройка Git

# ---- Установка Git ----

# Проверка, установлен ли Git
git --version

# Ubuntu / Debian
sudo apt update
sudo apt install -y git

# CentOS / RHEL / Fedora
sudo yum install -y git
# или
sudo dnf install -y git

# macOS (через Homebrew)
brew install git

# Windows
# Скачайте установщик с https://git-scm.com/download/win

# ---- Базовая настройка (обязательно!) ----

# Настройка имени пользователя (будет отображаться в коммитах)
git config --global user.name "Your Full Name"

# Настройка адреса электронной почты
git config --global user.email "your.email@example.com"

# ---- Дополнительные настройки ----

# Настройка редактора по умолчанию (для редактирования сообщений коммитов)
git config --global core.editor "vim"   # или nano, code, etc.

# Настройка автоматического преобразования окончаний строк (CRLF/LF)
# Для Windows
git config --global core.autocrlf true

# Для Linux/macOS
git config --global core.autocrlf input

# Настройка цвета в выводе Git
git config --global color.ui auto

# ---- Просмотр настроек ----

# Список всех глобальных настроек
git config --global --list

# Просмотр конкретной настройки
git config user.name
git config user.email

# ---- Удаление настроек ----

# Удалить глобальную настройку
git config --global --unset user.name

# ---- Уровни конфигурации ----

# Системный уровень (для всех пользователей системы)
# git config --system

# Глобальный уровень (для текущего пользователя)
# git config --global

# Локальный уровень (для конкретного репозитория)
# git config --local