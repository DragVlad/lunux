# RAID

```bash
sudo -s

lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   50G  0 disk 
├─sda1   8:1    0    1M  0 part 
└─sda2   8:2    0   50G  0 part /
sdb      8:16   0   10G  0 disk 
sdc      8:32   0   10G  0 disk 
sdd      8:48   0   10G  0 disk 
sr0     11:0    1 1024M  0 rom 

cat /proc/mdstat
mdadm --create --verbose /dev/md0 --level=1 raid-devices=2 /dev/sdc /dev/sdb
watch cat /proc/mdstat
mdadm --detail /dev/md0

lsblk
mkfs.ext4 /dev/md0
mkdir -p /mnt/raid1
df -h
mount /dev/md0 /mnt/raid1/
mdadm --manage /dev/md0 --fail /dev/sdc
cat /proc/mdstat
mdadm --detail /dev/md0
mdadm --manage /dev/md0 --remove /dev/sdc
mdadm --manage /dev/md0 --add /dev/sdd

umount /dev/md0 /mnt/raid1/
df -h
mdadm --stop /dev/md0
cat /proc/mdstat

mdadm --zero-superblock /dev/sdc
```