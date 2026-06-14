# Процесс загрузки ядра

Процесс загрузки ядра Linux — это комплексный процесс, включающий в себя несколько этапов. В общем виде процесс загрузки системы можно разбить на 4 основных этапа, в трёх из которых так или иначе участвует ядро:

1. Физическое включение и старт BIOS/UEFI
2. Работа программы загрузчика
3. Загрузка ядра и инициализация системы
4. Инициализация служб и процессов

## BIOS/UEFI

Первый этап загрузки начинается с момента включения компьютера. Процессор начинает выполнение кода, находящегося в непосредственной близости от него, который обычно находится в *Basic Input/Output System* (BIOS) или *Unified Extensible Firmware Interface* (UEFI). Этот код инициализирует базовые компоненты системы, такие как процессор, память, контроллеры устройств. После инициализации базовых компонентов системы BIOS/UEFI передаёт управление загрузчику операционной системы, который обычно находится на загрузочном разделе диска.

## Загрузчик

Загрузчик (например, GRUB — Grand Unified Bootloader), обычно имеющий в своём составе базовую поддержку большинства файловых систем Linux, монтирует корневую файловую систему, считывает с неё свой конфигурационный файл, обнаруживает все доступные для загрузки опции и либо выполняет назначенный по умолчанию вариант, либо ожидает команды пользователя. В случае загрузки дистрибутива Linux загрузчик находит, загружает, инициализирует и запускает ядро Linux и начальную файловую систему (initramfs или initrd).

Логи работы загрузчика можно увидеть на экране компьютера или виртуальной машины в момент загрузки. С момента запуска ядра и дальнейшей загрузки системы информацию можно получить из лога `dmesg` или (для современных дистрибутивов) из лога systemd с помощью утилиты `journalctl` с флагом `-b`:

```bash
# просмотр лога загрузки ядра и начала запуска системы инициализации
dmesg

# просмотр лога загрузки ядра + полного лога запуска системы инициализации,
# запуска служб, cloud-init и прочего
journalctl -b
```

Пример вывода `dmesg`:

```
[    0.000000] Linux version 5.15.0-91-generic (buildd@lcy02-amd64-098) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #101-Ubuntu SMP Tue Nov 21 11:00:00 UTC 2023
[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-5.15.0-91-generic root=UUID=abc123 ro quiet splash
[    0.000000] KERNEL supported cpus:
[    0.000000]   Intel GenuineIntel
[    0.000000]   AMD AuthenticAMD
[    0.000000] KASLR disabled due to boot option!
[    0.000000] e820: BIOS-provided physical RAM map:
[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009efff] usable
[    0.000000] BIOS-e820: [mem 0x000000000009f000-0x00000000000fffff] reserved
[    0.000000] DMI 2.8 present.
[    0.000000] Hypervisor detected: KVM
[    0.000000] NX (Execute Disable) protection: active
```

## Инициализация системы

Когда ядро Linux загружается, оно начинает инициализировать основные компоненты системы, такие как процессор, память, устройства и другие. Ядро также запускает процесс init, который является родительским процессом для всех остальных процессов в системе. В современных дистрибутивах (в подавляющем большинстве) основной системой инициализации и дальнейшего управления службами-демонами является *systemd*.

Для просмотра информации на этом этапе используется утилита `journalctl -b`:

```bash
journalctl -b | head -50
```

Пример вывода:

```
-- Logs begin at Tue 2024-01-15 10:00:00 UTC, end at Tue 2024-01-15 10:05:00 UTC. --
Jan 15 10:00:01 hostname kernel: Linux version 5.15.0-91-generic (buildd@lcy02-amd64-098) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #101-Ubuntu SMP Tue Nov 21 11:00:00 UTC 2023
Jan 15 10:00:01 hostname kernel: Command line: BOOT_IMAGE=/boot/vmlinuz-5.15.0-91-generic root=UUID=abc123 ro quiet splash
Jan 15 10:00:01 hostname kernel: KERNEL supported cpus:
Jan 15 10:00:01 hostname kernel:   Intel GenuineIntel
Jan 15 10:00:01 hostname kernel:   AMD AuthenticAMD
Jan 15 10:00:01 hostname systemd[1]: systemd 249.11-0ubuntu3.12 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR +IMA +SMACK +SECCOMP +GCRYPT +GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBFDISK +PCRE2 -PWQUALITY -P11KIT -QRENCODE +BZIP2 +LZ4 +XZ +ZLIB +ZSTD -XKBCOMMON +UTMP +SYSVINIT default-hierarchy=unified)
Jan 15 10:00:01 hostname systemd[1]: Detected virtualization kvm.
Jan 15 10:00:01 hostname systemd[1]: Detected architecture x86-64.
Jan 15 10:00:01 hostname systemd[1]: Running in initial RAM disk.
```

## Старт служб и процессов

После инициализации ядра и процесса init начинают запускаться различные службы и процессы, необходимые для работы системы. Это может включать в себя демоны, сетевые сервисы, файловые системы и другие компоненты.

В зависимости от конкретного процесса или сервиса для просмотра логов используется `journalctl -u <имя службы>` либо просмотр выделенного лог-файла службы.

**Пример просмотра логов запуска ssh-демона:**

```bash
sudo journalctl -u ssh
```

Пример вывода:

```
Jan 15 10:00:15 hostname systemd[1]: Starting OpenBSD Secure Shell server...
Jan 15 10:00:15 hostname sshd[1234]: Server listening on 0.0.0.0 port 22.
Jan 15 10:00:15 hostname sshd[1234]: Server listening on :: port 22.
Jan 15 10:00:15 hostname systemd[1]: Started OpenBSD Secure Shell server.
Jan 15 10:00:20 hostname sshd[1235]: Accepted publickey for user from 192.168.1.100 port 54321 ssh2: RSA SHA256:abc123
```

**Пример просмотра логов запуска сетевой службы:**

```bash
sudo journalctl -u networking
```

Пример вывода:

```
Jan 15 10:00:10 hostname systemd[1]: Starting Network configuration...
Jan 15 10:00:10 hostname ifup[1000]: Waiting for systemd-networkd to be ready
Jan 15 10:00:12 hostname ifup[1000]: Configuring interface eth0=eth0
Jan 15 10:00:12 hostname ifup[1000]: dhclient: Internet Systems Consortium DHCP Client 4.4.1
Jan 15 10:00:12 hostname ifup[1000]: dhclient: Listening on LPF/eth0/00:11:22:33:44:55
Jan 15 10:00:12 hostname ifup[1000]: dhclient: Sending on   LPF/eth0/00:11:22:33:44:55
Jan 15 10:00:13 hostname dhclient[1050]: DHCPACK of 192.168.1.50 from 192.168.1.1
Jan 15 10:00:13 hostname systemd[1]: Finished Network configuration.
```

**Пример просмотра логов конкретной загрузки (не текущей):**

```bash
# просмотр логов загрузки от предыдущего запуска системы
journalctl -b -1

# просмотр логов загрузки от двух запусков назад
journalctl -b -2
```

**Пример фильтрации логов по времени:**

```bash
# просмотр логов за последние 5 минут
journalctl --since "5 minutes ago"

# просмотр логов за конкретный промежуток времени
journalctl --since "2024-01-15 10:00:00" --until "2024-01-15 10:05:00"
```