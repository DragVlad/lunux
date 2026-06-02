# Открываем редактор для пользаков
sudo visudo

# Добавляем строчку для admin_dev
admin_dev ALL=(ALL:ALL) ALL

# Проверяем права админа
sudo -u admin_dev sudo whoami
> root

# выдача прав на перезагрузку и просмотра пользователей dev_user
sudo visudo
dev_user ALL=(ALL) /usr/sbin/reboot, /bin/cat /etc/passwd
sudo -u dev_user sudo apt update
> Sorry, user dev_user is not allowed to execute '/usr/bin/apt update' as root on ubuntuserv.

# Настройка админа под apache2
sudo apt install -y apache2
sudo adduser web_admin

sudo visudo
web_admin ALL=(ALL) NOPASSWD: /usr/sbin/service apache2 *

su - web_admin
sudo service apache2 restart