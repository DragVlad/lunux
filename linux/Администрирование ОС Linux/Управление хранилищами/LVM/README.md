# Концепция логических томов и LVM (Logical Volume Manager)

Всё хорошо с обычными дисками, но есть одно **но**: ограниченность, конечность места. Какой бы большой диск вы ни купили — он конечен. Технология создания разделов поверх физического диска не позволяет создать единое непрерывное пространство хранения.

> **LVM** (Logical Volume Manager) — технология, позволяющая гибко управлять дисковым пространством, создавая логические тома поверх физических разделов.

---

## Зачем нужен LVM?

Представьте: у вас есть диски размером 1 ТБ (не более). Ваша база данных уже занимает 950 ГБ и по расчётам разработчиков вырастет вдвое в течение года. Что делать?

LVM приходит на помощь, предлагая:

- **Гибкость** в управлении дисковым пространством
- Возможность **динамического изменения размеров** томов
- Создание **моментальных снимков** (snapshots)

---

## Преимущества использования LVM

| Категория | Преимущества |
|-----------|--------------|
| **Гибкость** | Динамическое изменение размеров томов без перемонтирования; создание снимков для резервного копирования |
| **Управление ресурсами** | Объединение нескольких дисков в один пул; логическое разбиение на тома |
| **Производительность** | Распределение нагрузки между дисками (striping); зеркалирование (mirroring) для отказоустойчивости |
| **Администрирование** | Упрощение управления дисками; интеграция с инструментами мониторинга |

> [!note]
> За всё нужно платить — LVM вводит дополнительный уровень абстракции, который необходимо освоить.

---

## Основные концепции LVM

| Компонент | Описание | Команда создания |
|-----------|----------|------------------|
| **PV (Physical Volume)** | Физический носитель (диск или раздел) | `pvcreate` |
| **VG (Volume Group)** | Пул хранения, объединяющий несколько PV | `vgcreate` |
| **LV (Logical Volume)** | Виртуальный раздел внутри VG | `lvcreate` |

### Дополнительные термины

- **PE (Physical Extent)** — минимальный блок хранения на физическом томе (обычно 4 МБ)
- **LE (Logical Extent)** — соответствует PE, отображается один к одному
- **Толстый (Thick) LV** — резервирует всё выделенное пространство сразу
- **Тонкий (Thin) LV** — выделяет пространство по мере необходимости (оверселлинг)
- **Snapshot** — моментальная копия состояния LV (copy-on-write)

### Схема работы LVM

```
Физические диски (PV) → Группа томов (VG) → Логические тома (LV) → Файловые системы
   /dev/sdc  ─┐
   /dev/sdd  ─┼─→  my_volume_group  ──→  my_lv_1  ──→  /mnt/data1
   /dev/sde  ─┘                        my_lv_2  ──→  /mnt/data2
```

---

## Практический пример: создание LVM из трёх дисков

### Исходные данные
- 3 дополнительных диска по 10 ГБ: `/dev/sdc`, `/dev/sdd`, `/dev/sde`
- Цель: создать единое пространство 30 ГБ с двумя томами по 15 ГБ

### Шаг 1: Создание физических томов (PV)

```bash
sudo pvcreate /dev/sdc /dev/sdd /dev/sde
sudo pvdisplay   # просмотр
```

### Шаг 2: Создание группы томов (VG)

```bash
sudo vgcreate my_volume_group /dev/sdc /dev/sdd /dev/sde
sudo vgdisplay   # просмотр
```

### Шаг 3: Создание логических томов (LV)

```bash
# Толстый том (15 ГБ)
sudo lvcreate --name my_logical_volume_1 --size 15G my_volume_group

# Тонкий том: сначала пул, потом том
sudo lvcreate --thinpool my_thin_pool --size 14.9G my_volume_group
sudo lvcreate --virtualsize 14G --thin my_volume_group/my_thin_pool --name my_thin_volume_2
```

### Шаг 4: Создание ФС и монтирование

```bash
# Точки монтирования
sudo mkdir -p /var/my_lvm/logical_volume_1
sudo mkdir -p /var/my_lvm/logical_volume_2
sudo mkdir -p /var/my_lvm/logical_volume_3

# Файловые системы
sudo mkfs.ext4 /dev/my_volume_group/my_logical_volume_1
sudo mkfs.ext4 /dev/my_volume_group/my_thin_volume_2
sudo mkfs.ext4 /dev/my_volume_group/my_thin_volume_3

# Монтирование
sudo mount /dev/my_volume_group/my_logical_volume_1 /var/my_lvm/logical_volume_1
```

> [!tip]
> Несмотря на то, что каждый физический диск имеет 10 ГБ, нам удалось создать тома по 15 ГБ. Тонкие тома делят общее пространство, потребляя его только по факту реальной записи.

---

## Динамическое расширение тома

### На лету, без размонтирования

```bash
# Расширить LV на всё свободное место в VG
sudo lvextend -l +100%FREE /dev/my_volume_group/my_logical_volume_1

# Расширить файловую систему
sudo resize2fs /dev/my_volume_group/my_logical_volume_1
```

> [!important]
> Это можно делать на работающих серверах, например, при плановом увеличении пространства для базы данных.

---

## Работа со снапшотами (Snapshots)

> **Snapshot** — моментальная копия состояния логического тома, основанная на механизме copy-on-write (CoW).

### Как работает CoW

1. При создании снимка оригинальные данные не копируются
2. При записи в исходный том старые данные копируются в область снимка
3. Снимок читает сохранённые копии, если блок был изменён

### Преимущества и ограничения

| ✅ Преимущества | ⚠️ Ограничения |
|----------------|----------------|
| Мгновенное создание | Снижение производительности при интенсивной записи |
| Экономия места (только изменённые блоки) | Снапшот может быстро заполниться |
| Резервное копирование без остановки | При заполнении снапшот становится недействительным |

### Пример работы со снапшотами

```bash
# Переключение под root
sudo -s

# Создание тестового LV
lvcreate --name my_logical_volume --size 10G my_volume_group
mkfs.ext4 /dev/my_volume_group/my_logical_volume
mkdir /var/my_lvm/logical_volume
mount /dev/my_volume_group/my_logical_volume /var/my_lvm/logical_volume

# Создание тестовых данных
cd /var/my_lvm/logical_volume
echo "Hello world" > test.txt

# Создание снапшота
lvcreate --size 5G --snapshot --name my_snapshot /dev/my_volume_group/my_logical_volume

# Монтирование снапшота
mkdir /var/my_lvm/snapshot
mount /dev/my_volume_group/my_snapshot /var/my_lvm/snapshot

# Проверка — данные видны в снапшоте
cat /var/my_lvm/snapshot/test.txt   # "Hello world"

# Изменение исходных данных
echo "123 123 123" >> /var/my_lvm/logical_volume/test.txt

# Сравнение: исходный том изменён, снапшот хранит оригинал
cat /var/my_lvm/logical_volume/test.txt   # Hello world + 123 123 123
cat /var/my_lvm/snapshot/test.txt         # Hello world
```

### Очистка

```bash
umount /var/my_lvm/snapshot
lvremove /dev/my_volume_group/my_snapshot
umount /var/my_lvm/logical_volume
lvremove /dev/my_volume_group/my_logical_volume
vgremove my_volume_group
pvremove /dev/sdc /dev/sdd /dev/sde
```

---

## Основные команды LVM

| Задача | Команда |
|--------|---------|
| Создание PV | `pvcreate /dev/sdX` |
| Просмотр PV | `pvdisplay`, `pvs` |
| Создание VG | `vgcreate VG_NAME /dev/sdX` |
| Просмотр VG | `vgdisplay`, `vgs` |
| Создание LV | `lvcreate -n LV_NAME -L SIZE VG_NAME` |
| Создание тонкого LV | `lvcreate --thinpool POOL --size SIZE VG`<br>`lvcreate -V SIZE --thin -n LV_NAME VG/POOL` |
| Создание снапшота | `lvcreate --size SIZE --snapshot --name SNAP_NAME /dev/VG/LV` |
| Расширение LV | `lvextend -L +SIZE /dev/VG/LV` |
| Расширение ФС | `resize2fs /dev/VG/LV` (для ext4) |
| Просмотр LV | `lvdisplay`, `lvs` |
| Удаление LV | `lvremove /dev/VG/LV` |
| Удаление VG | `vgremove VG_NAME` |
| Удаление PV | `pvremove /dev/sdX` |

---

## Итог

LVM — мощный инструмент для управления дисковым пространством, который:

1. Позволяет объединять несколько физических дисков в один пул
2. Даёт возможность изменять размеры томов на лету
3. Предоставляет механизм снапшотов для резервного копирования
4. Поддерживает тонкое выделение места (thin provisioning)

> [!warning]
> Все операции с LVM необратимы. Перед удалением томов убедитесь, что важные данные сохранены. Для production-систем всегда тестируйте изменения на тестовых стендах.