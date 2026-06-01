# создание пользователей
sudo adduser admin_dev
sudo adduser dev_user

# создание группы
sudo groupadd developers

# инфа о группе
getent group developers

# добавление пользователей в группу
sudo usermod -aG developers admin_dev
sudo usermod -aG developers dev_user

# проверка группы пользователя
groups admin_dev
groups dev_user

# Изменение основной группы пользователя(чтобы созданные им файлы имели группу developers)
sudo usermod -g developers admin_dev
id admin_dev

# Назначения пользователя admin_dev администратором группы developers
sudo gpasswd -A admin_dev developers
# Теперь он может добавлять и удалять пользователей в developers
# Удалить - sudo gpasswd -a dev_user developers
# Добавить - sudo gpasswd -d dev_user developers

# Просмотр состояния группы
getent group developers

# Удаление пользователя
sudo userdel qa_user