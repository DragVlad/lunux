# Добавляем место на логическом томе
lvdisplay
df -h

# Проверяем что в группе томов есть свободное место
vgdisplay

# Добавляем место
lvextend -L +3G /dev/vg_data/mlv
lvdisplay

# Расширяем файловую систему и проверяем
resize2fs /dev/vg_data/mlv
df -h