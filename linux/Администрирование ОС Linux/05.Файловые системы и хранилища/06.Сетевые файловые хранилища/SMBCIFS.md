# Samba для SMB

- Настройка сервера:
```bash
# Установка
sudo apt update
sudo apt install samba

# Версия
smbd --version

# Выдача прав на /var/storage/smb
sudo chown -R root:root /var/storage/smb
sudo chmod -R 755 /var/storage/smb

# создаем группы
sudo groupadd smbadmins
sudo groupadd smbusers
sudo groupadd smbguests

# создаем пользователей
sudo useradd -M -s /sbin/nologin adminuser
sudo useradd -M -s /sbin/nologin regularuser
sudo useradd -M -s /sbin/nologin guestuser

# добавляем их в группы
sudo usermod -aG smbadmins adminuser
sudo usermod -aG smbusers regularuser
sudo usermod -aG smbguests guestuser

# Создаем пароли для пользаков
sudo smbpasswd -a adminuser
sudo smbpasswd -a regularuser
sudo smbpasswd -a guestuser

# Редактируем конфиг
sudo nano /etc/samba/smb.conf >
[global]
server min protocol = SMB3
[smbshare]
path = /var/storage/smb
browsable = yes
writable = yes
read only = no
guest ok = no
valid users = @smbadmins, @smbusers, @smbguests
force group = smbadmins
create mask = 0660
directory mask = 0770
write list = @smbadmins, @smbusers
read list = @smbguests

# Настройка прав доступа к файлам
sudo apt -y install acl
sudo setfacl -R -m g:smbadmins:rwx /var/storage/smb
sudo setfacl -R -m g:smbusers:rwx /var/storage/smb
sudo setfacl -R -m g:smbguests:rx /var/storage/smb
sudo setfacl -R -d -m g:smbadmins:rwx /var/storage/smb
sudo setfacl -R -d -m g:smbusers:rwx /var/storage/smb
sudo setfacl -R -d -m g:smbguests:rx /var/storage/smb

sudo ufw allow 139/tcp
sudo ufw allow 445/tcp
```

- Настройка клиента:
```bash
sudo apt update
sudo apt install smbclient

smbclient //192.168.0.29/smbshare -U adminuser
put /etc/hostname testfile_admin.txt
ls
exit

smbclient //192.168.0.29/smbshare -U regularuser
put /etc/hostname testfile_admin.txt
ls
exit

smbclient  //192.168.0.29/smbshare -U guestuser
put /etc/hostname testfile_admin.txt
ls
exit
```

- Монтирование ресурса
```bash
sudo apt update
sudo apt -y install cifs-utils
sudo mkdir -p /mnt/smb-share
sudo mount -t cifs //192.168.0.29/smbshare /mnt/smb-share -o username=regularuser,password=admin
sudo nano /etc/fstab >
//192.168.0.29/smbshare /mnt/smb-share cifs username=regularuser,password=admin,iocharset=utf8,file_mode=0777,dir_mo>

sudo mount -a
```