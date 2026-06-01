# Базовая настройка сервера

sudo apt update && sudo apt upgrade -y &
sudo echo "localhost 127.0.0.1" > /etc/hosts
sudo apt install openssh-server -y &
sudo systemctl start ssh
sudo systemctl enable ssh
sudo systemctl status ssh
ss -antlp # проверяем порты
ssh-copy-id user@ip_address # на тачке откуда подключаемся к серверу
# добавляем удобство в конфиг на клиенте
vim .ssh/config
Host ubuntuserv
  User admin
  Port 22
  HostName 192.168.0.32

sudo nano /etc/ssh/sshd_config
# Меняем порт
# PermitRootLogin no
# PubkeyAuthentication yes
#PasswordAuthentication no
sudo systemctl stop ssh.socket
sudo systemctl disable ssh.socket
sudo systemctl restart sshd

# включаем фаервол
sudo ufw allow 31200/tcp
sudo ufw enable