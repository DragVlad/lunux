# Настройка входа по ssh

## Первичная настройка

```bash
ssh root@your_ip

apt update

adduser dev
# Создаем сложный пароль

adduser dev sudo

exit
ssh dev@your_ip

#Добавляем наш публичный ssh на сервер
ssh-copy-id dev@your_ip

#Запрещаем вход под root
sudo vi /etc/ssh/sshd_config

#Добавляем в конец файла
AllowUsers dev # только dev может ходить по ssh

PermitRootLogin no
PasswordAuthentication no
sudo service ssh restart
```
## Отключение пароля sudo для dev

На боевых серверах не стоит такое делать(только на учебных проектах).

- Добавление в `nopasswd`:
```bash
# пример для пользователя dev
sudo vi /etc/sudoers.d/dev-nopasswd

# Добавляем строчку
dev ALL=(ALL) NOPASSWD: ALL
# ALL=(ALL)- может выполнять коменды от любого пользователя
# NOPASSWD: ALL - может выполнять любые команды
```

- Ограничение на выбранные команды:
```bash
dev ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/systemctl
```

- Удаление `nopasswd`:
```bash
sudo rm /etc/sudoers.d/dev-nopasswd
```

## Настройка локального ssh:

```bash
touch ~/.ssh/config

chmod 600 ~/.ssh/config
```
- Самый простой пример файла
```bash
Host dev
    HostName your_ip
```

- Теперь можем входить на сервер по 1 команде:
```bash
ssh dev
```