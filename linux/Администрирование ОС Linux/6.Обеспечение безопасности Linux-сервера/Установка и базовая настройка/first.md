- Просмотр активных сервисов
```bash
systemctl list-units --type=service --state=running
```
- Просмотр открытых портов
```bash
sudo ss -tulnp
```

- Просмотр с помощью курла версии и дистра с помощью курла
```bash
admin@ubuntuserv:~$ curl -I http://127.0.0.1
HTTP/1.1 200 OK
Date: Wed, 03 Jun 2026 20:10:06 GMT
Server: Apache/2.4.58 (Ubuntu)
Last-Modified: Tue, 02 Jun 2026 19:21:21 GMT
ETag: "29af-6534a37555347"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
```
- Проверка открытых портов сервера
```bash
sudo apt install nmap
ip a
sudo nmap -sSV -p- -Pn 192.168.0.32
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-06-03 20:12 UTC
Nmap scan report for ubuntuserv (192.168.0.32)
Host is up (0.0000030s latency).
Not shown: 65533 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.16 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.58 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 7.06 seconds
```

- stop + disable одной командой
```bash
sudo systemctl disable --now apache2.service
sudo systemctl status apache2.service
# выключаем возможность включения сервера
sudo systemctl mask apache2.service
Created symlink /etc/systemd/system/apache2.service → /dev/null.
sudo systemctl start apache2.service
Failed to start apache2.service: Unit apache2.service is masked.
sudo apt remove --purge apache2
```

- классная штука по аудиту безопасности
```bash
wget https://github.com/aquasecurity/trivy/releases/download/v0.70.0/trivy_0.70.0_Linux-64bit.deb
sudo dpkg -i trivy_0.70.0_Linux-64bit.deb
trivy --version

# Сканирование файловой системы на высокие и критические уязвимости
trivy fs --scanners vuln --severity HIGH,CRITICAL /
trivy fs --scanners vuln --severity HIGH,CRITICAL / | grep Total

# версии ядер
ls -ls /boot/
uname -r

# обновляем ядро
sudo apt upgrade -y && apt sudo dist-upgrade -y

# версии ядер
ls -ls /boot/
uname -r

# удаляем для примера старое ядро(откатываться некуда ...)
sudo apt-get purge linux-image-6.8.0-117-generic*

# чистим систему от мусора
sudo apt autoremove --purge
trivy fs --scanners vuln --severity HIGH,CRITICAL /
```