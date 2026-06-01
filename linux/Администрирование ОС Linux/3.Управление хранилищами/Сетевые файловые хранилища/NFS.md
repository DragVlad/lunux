# NFS

- Настройка сервера:
```bash
# Установка пакетов
sudo apt update
sudo apt -y install nfs-kernel-server

# создание и настройка директории
sudo mkdir -p /var/storage/nfs/home/testuser
sudo chown nobody:nogroup /var/storage/nfs 
sudo chmod 755 /var/storage/nfs

# Добавление конфигов
sudo nano /etc/exports >
/var/storage/nfs   *(rw,sync,no_subtree_check,no_root_squash)

# применение конфигов и рестарт сервиса
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

- Клиент:
```bash
# Установка необходимого
sudo apt update
sudo apt -y install nfs-common

# Создание и монтирование директории по nfs
sudo mkdir -p /mnt/nfs
sudo mount -t nfs 192.168.0.29:/var/storage/nfs /mnt/nfs
df -h | grep nfs

# Создание и настройка пользователя для директории
sudo mkdir -p /mnt/nfs/home/testuser
sudo useradd -m -d /mnt/nfs/home/testuser testuser
sudo chown testuser:testuser /mnt/nfs/home/testuser
sudo passwd testuser

# Добавление настройки для сохранения монтирования
sudo nano /etc/fstab >
IP add первого сервера:/var/storage/nfs  /mnt/nfs  nfs  defaults  0  0

# Проверка монтирования
sudo mount -a

# Проверка функционала
sudo su - testuser
touch /mnt/nfs/home/testuser/testfile

# На сервере
ls /var/storage/nfs/home/testuser
```