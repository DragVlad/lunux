sudo apt-get install acl

# создание директории
sudo mkdir /project_data
ls -ld /project_data
drwxr-xr-x   2 root root  4096 Jun  1 20:32 project_data

# назначение владельца и группы владельцев
sudo chown admin_dev:developers /project_data
ls -ld /project_data
drwxr-xr-x   2 admin_dev developers  4096 Jun  1 20:32 project_data

# задаем доступ на директорию (все владельцу + группе, ничего остальным)
sudo chmod 770 /project_data
ls -ld /project_data
drwxrwx---   2 admin_dev developers  4096 Jun  1 20:32 project_data

# Создание тестового пользователя
sudo adduser qa_user

# выдача прав на просмотр содержимого в директории
sudo setfacl -m u:qa_user:r /project_data
getfacl project_data

# запрет dev_user записи в /project_data
sudo setfacl -m u:dev_user:r-x /project_data
getfacl project_data

# делаем рекурсивное добавление прав на директорию
sudo setfacl -d -m u:qa_user:r /project_data
getfacl project_data

# Удаление acl записи
sudo setfacl -d -x u:qa_user /project_data