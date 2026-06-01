admin@ubuntu-server:~$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   50G  0 disk 
├─sda1   8:1    0    1M  0 part 
└─sda2   8:2    0   50G  0 part /
sdb      8:16   0    1G  0 disk 
sdc      8:32   0   10G  0 disk # диск для развлечения 
sr0     11:0    1 1024M  0 rom 

sudo parted /dev/sdc mklabel gpt # делаем разметку gtp на диске
sudo parted -a optimal /dev/sdc mkpart primary ext4 0% 2GB # создаем файловую систему под ext4
sudo parted -a optimal /dev/sdc mkpart primary ext4 2GB 5GB
sudo parted -a optimal /dev/sdc mkpart primary ext4 5GB 10GB
lsblk /dev/sdc # появится 3 новых раздела

sudo mkfs.ext4 /dev/sdc1 # создание файловой системы
sudo mkfs.ext4 /dev/sdc2
sudo mkfs.ext4 /dev/sdc3

sudo dd if=/dev/zero of=/dev/sdc bs=1M status=progress # очистка диска с помощью его перезаписи, юзаем ее
sudo shred -v -n 1 /dev/sdc # очистка с помощью утилиты шред
sudo wipefs --all /dev/sdc # удаляет информацию о разделе файловой системы

# Пример для приложения
sudo parted /dev/sdc mklabel msdos

sudo parted -a optimal /dev/sdc mkpart primary ext4 0% 2GB # создаем файловую систему под ext4
sudo parted -a optimal /dev/sdc mkpart primary ext4 2GB 5GB
sudo parted -a optimal /dev/sdc mkpart primary ext4 5GB 10GB

sudo mkfs.ext4 /dev/sdc1 # создание файловой системы
sudo mkfs.ext4 /dev/sdc2
sudo mkfs.ext4 /dev/sdc3

lsblk /dev/sdc

sudo mkdir -p /var/www/mysite
sudo mkdir -p /opt/myapp
sudo mkdir -p /var/mydatabase

df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           197M  1.1M  196M   1% /run
/dev/sda2        49G  2.9G   44G   7% /
tmpfs           984M     0  984M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           197M   12K  197M   1% /run/user/1000

# Команда mount работает до перезагрузки
sudo mount /dev/sdc1 /var/www/mysite
sudo mount /dev/sdc2 /opt/myapp
sudo mount /dev/sdc3 /var/mydatabase

df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           197M  1.1M  196M   1% /run
/dev/sda2        49G  2.9G   44G   7% /
tmpfs           984M     0  984M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           197M   12K  197M   1% /run/user/1000
/dev/sdc1       1.8G   24K  1.7G   1% /var/www/mysite
/dev/sdc2       2.7G   24K  2.6G   1% /opt/myapp
/dev/sdc3       4.6G   24K  4.3G   1% /var/mydatabase

# Фиксируем монтирование дисков
sudo vim /etc/fstab
>>>
# что монтируем|куда монтируем|какая файловая система|опции монтирования
/dev/sdc1    /var/www/mysite    ext4    defaults     0 2
/dev/sdc2    /opt/myapp         ext4    defaults     0 2
/dev/sdc3    /var/mydatabase    ext4    defaults     0 2

# отменяем монтирования(для демонстрации того что все ок)
sudo umount /dev/sdc1
sudo umount /dev/sdc2
sudo umount /dev/sdc3

# запускаем монтирование из /etc/fstab
sudo mount -a

# Теперь все ок!
# список UUID блочных устройств
# гарантирует что в нужный диск, будет писать нужная инфа(если в ЦОДЕ переткнули порты для дисков)
sudo blkid 
/dev/sda2: UUID="b2297e2b-d6b5-437d-a722-2bdde8749e7a" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="63fb3993-fe13-48c7-aa2b-f54ba09c3e01"
/dev/sdc2: UUID="ac18e8df-917c-4d00-ab0f-e2528e100a77" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="209c12fe-02"
/dev/sdc3: UUID="0690af70-e58f-4eb7-824d-0c7cad582c35" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="209c12fe-03"
/dev/sdc1: UUID="728141e1-459b-4b53-9264-e0185d830ec4" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="209c12fe-01"
/dev/sda1: PARTUUID="3980fd61-8268-4a25-a80b-5175fd04ea8f"