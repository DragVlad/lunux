- Создание 2ух RAID-массива уровня 1 из 4 дисков
```bash
lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   50G  0 disk
├─sda1   8:1    0    1M  0 part
└─sda2   8:2    0   50G  0 part /
sdb      8:16   0   10G  0 disk
sdc      8:32   0   10G  0 disk
sdd      8:48   0   10G  0 disk
sde      8:64   0   10G  0 disk
sr0     11:0    1 1024M  0 rom

# Наши красавцы sdb sdc sdd sde

# Создание рейд массивов
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
sudo mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sdd /dev/sde

# Мониторинг создания
watch -n 1 cat /proc/mdstat
lsblk

# Создание физикал волюм LVM
sudo pvcreate /dev/md0
sudo pvcreate /dev/md1

sudo pvs # чекаем наличие физического волюма

sudo vgcreate vg_storage /dev/md0 /dev/md1 # Создание волюм групп
sudo vgs # чекаем что вышло
lsblk # видим изменения

# Создаем логические тома
sudo lvcreate -n lv_smb -L 6G vg_storage
sudo lvcreate -n lv_nfs -L 6G vg_storage
sudo lvcreate -n lv_iscsi -L 6G vg_storage

# чекаем 
sudo lvs
lsblk

# Создаем файловую систему
sudo mkfs.ext4 /dev/vg_storage/lv_smb
sudo mkfs.ext4 /dev/vg_storage/lv_nfs
sudo mkfs.ext4 /dev/vg_storage/lv_iscsi

# чек
blkid | grep vg_storage

# Создаем директории
sudo mkdir -p /var/storage/smb
sudo mkdir -p /var/storage/nfs
sudo mkdir -p /var/storage/iscsi

# Монтируем тома
sudo mount /dev/vg_storage/lv_smb /var/storage/smb
sudo mount /dev/vg_storage/lv_nfs /var/storage/nfs
sudo mount /dev/vg_storage/lv_iscsi /var/storage/iscsi

# Чек
df -h
lsblk

# Добавляем по UUID
blkid /dev/vg_storage/lv_smb > UUID="aef85fc0-c268-4515-9892-8f835881103b"
blkid /dev/vg_storage/lv_nfs > UUID="85d5ff49-6ce0-43ae-a631-8c3ba5aca697"
blkid /dev/vg_storage/lv_iscsi > UUID="a91763f1-515d-486b-a6af-b5833af1b6d6"

# вносим изменения в файл
vi /etc/fstab
UUID="aef85fc0-c268-4515-9892-8f835881103b"  /var/storage/smb    ext4  defaults  0 2
UUID="85d5ff49-6ce0-43ae-a631-8c3ba5aca697"  /var/storage/nfs    ext4  defaults  0 2
UUID="a91763f1-515d-486b-a6af-b5833af1b6d6"  /var/storage/iscsi  ext4  defaults  0 2

# Проверяем что после ребута все ок
sudo reboot
df -h
lsblk
```