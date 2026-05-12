```bash
# Логические тома

lsblk # смотрим что по дискам
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   50G  0 disk 
├─sda1   8:1    0    1M  0 part 
└─sda2   8:2    0   50G  0 part /
sdb      8:16   0   10G  0 disk 
sdc      8:32   0   10G  0 disk 
sdd      8:48   0   10G  0 disk 
sr0     11:0    1 1024M  0 rom 

# создаем физические тома (PV) из чистых дисков
sudo pvcreate /dev/sdb
sudo pvcreate /dev/sdc
sudo pvcreate /dev/sdd

sudo pvdisplay # статистика по физическим томам

# создаем группу томов (VG), объединяем три диска в одну кучу ресурсов
sudo vgcreate my_volume_group /dev/sdb /dev/sdc /dev/sdd # создаем логическую группу
sudo vgdisplay # чекаем ее (размер = сумма всех PV)

# создаем обычный логический том на 15 ГБ
sudo lvcreate --name my_logical_volume_1 --size 15G my_volume_group

# создаем тонкий пул (хранилище для тонких томов)
sudo lvcreate --thinpool my_thin_pool --size 14.9G my_volume_group

# создаем тонкий том с виртуальным размером 14ГБ (реально занимает сколько записано)
sudo lvcreate --virtualsize 14G --thin my_volume_group/my_thin_pool --name my_thin_volume_2
sudo lvdisplay # чекаем что вышло

# добавляем еще один oversize том (места в пуле физически уже нет, но LVM позволяет)
sudo lvcreate --virtualsize 14G --thin my_volume_group/my_thin_pool --name my_thin_volume_3

# Создаем директории под точки монтирования
sudo mkdir -p /var/my_lvm/logical_volume_1
sudo mkdir -p /var/my_lvm/logical_volume_2
sudo mkdir -p /var/my_lvm/logical_volume_3

# Создаем файловую систему на каждом томе (форматируем)
sudo mkfs.ext4 /dev/my_volume_group/my_logical_volume_1
sudo mkfs.ext4 /dev/my_volume_group/my_thin_volume_2
sudo mkfs.ext4 /dev/my_volume_group/my_thin_volume_3

# монтируем тома в систему
sudo mount /dev/my_volume_group/my_logical_volume_1 /var/my_lvm/logical_volume_1
sudo mount /dev/my_volume_group/my_thin_volume_2 /var/my_lvm/logical_volume_2
sudo mount /dev/my_volume_group/my_thin_volume_3 /var/my_lvm/logical_volume_3

# размонтируем тонкие тома перед удалением
sudo umount /dev/my_volume_group/my_thin_volume_2 /var/my_lvm/logical_volume_2
sudo umount /dev/my_volume_group/my_thin_volume_3 /var/my_lvm/logical_volume_3

# удаляем oversize тома (они всё равно не работали бы без места)
sudo lvremove /dev/my_volume_group/my_thin_volume_2
sudo lvremove /dev/my_volume_group/my_thin_volume_3

sudo lvdisplay # проверяем, что осталось

# удаляем тонкий пул (он тоже больше не нужен)
sudo lvremove /dev/my_volume_group/my_thin_pool

# расширяем обычный том на всё свободное место в группе (было 15ГБ, станет 30ГБ)
sudo lvextend -l 100%VG /dev/my_volume_group/my_logical_volume_1
df -h # смотрим - размер тома еще старый, только LVM расширился

# расширяем файловую систему под новый размер тома
sudo resize2fs /dev/my_volume_group/my_logical_volume_1
# теперь df -h покажет 30ГБ
```

## Снапшоты LVM
```bash
sudo -s # становимся рутом, чтобы не писать sudo перед каждой командой

# отмонтируем том, с которым будем работать
umount /var/my_lvm/logical_volume_1

# удаляем старый том (для чистоты эксперимента)
lvremove /dev/mapper/my_volume_group-my_logical_volume_1

lvdisplay # проверяем, что удалили
vgdisplay # смотрим свободное место в группе

# создаем новый обычный том 10ГБ
lvcreate --name my_logical_volume --size 10G my_volume_group

# форматируем в ext4
mkfs.ext4 /dev/my_volume_group/my_logical_volume_1

# создаем точку монтирования и монтируем
mkdir /var/my_lvm/logical_volume
mount /dev/my_volume_group/my_logical_volume /var/my_lvm/logical_volume

df -h # проверяем, что примонтировалось

# заходим на том и создаем файл с данными
cd /var/my_lvm/logical_volume
echo "Hello world!" > test.txt

# создаем снапшот (снимок) на 5ГБ - в него будут попадать изменения исходного тома
lvcreate --size 5G --snapshot --name my_snapshot /dev/my_volume_group/my_logical_volume
lvdisplay # видим два тома: оригинал и снапшот (оба по 10ГБ виртуально)

# монтируем снапшот в отдельную папку
mkdir /var/my_lvm/snapshot
mount /dev/my_volume_group/my_snapshot /var/my_lvm/snapshot/

# заходим в снапшот и дописываем данные в тот же файл
cd /var/my_lvm/snapshot
echo "123456789" >> test.txt

# смотрим исходный том - изменений нет! снапшот хранит разницу
cat ../logical_volume/test.txt # выведет только "Hello world!"
# при этом в самом снапшоте test.txt содержит обе строки
```

**Суть снапшота:** при изменении оригинального тома старые данные копируются в снапшот, поэтому он занимает место только на разницу. Исходный том продолжает жить своей жизнью, а снапшот — это его замороженная копия на момент создания.