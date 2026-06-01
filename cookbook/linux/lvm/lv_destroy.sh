# Очистка идет в обратном порядке

# Удаление логического тома
lvremove /dev/vg_data/mlv
lvdisplay

# Удаление группы томов
vgremove vg_data
vgdisplay

# Удаление физического тома
pvremove /dev/sdb
pvdisplay

# Зачистка диска с помощью заполнения его рандомными данными
dd if=/dev/urandom of=/dev/sdb bs=1M status=progress