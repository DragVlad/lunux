lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   20G  0 disk 
├─sda1   8:1    0    1M  0 part 
└─sda2   8:2    0   20G  0 part /
sdb      8:16   0   10G  0 disk # наша цель
sr0     11:0    1 1024M  0 rom

# Создание физического тома(подготовка)
pvcreate /dev/sdb
Physical volume "/dev/sdb" successfully created.
pvdisplay

# Создание группы томов(для послед создания из нее логических томов)
vgcreate vg_data /dev/sdb
vgdisplay

# Создание логического тома(его уже будем монтировать и тд)
lvcreate -L 5G -n mlv vg_data
lvdisplay

# Создание файловой системы на лог томе
mkfs4.ext4 -L MyData /dev/vg_data/mlv

# Монтирование файловой системы
mkdir /mnt/data
mount /dev/vg_data/mlv /mnt/data/
df -h