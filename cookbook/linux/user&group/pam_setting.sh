# Установка pam плагина
sudo apt-get install libpam-pwquality

# Настройка политики для пароля
sudo nano /etc/security/pwquality.conf

# minlen = 12          # Минимальная длина пароля - 12 символов
# dcredit = 1         # Требовать хотя бы одну цифру
# ucredit = 1         # Требовать хотя бы одну заглавную букву
# lcredit = 1         # Требовать хотя бы одну строчную букву
# ocredit = 1         # Требовать хотя бы один специальный символ (например, !, @, #)

# Меняем пароль для пользователя
sudo passwd dev_user

# Настройка срока действия пароля
sudo chage -m 7 -M 90 -W 7 dev_user
# -m 7 - не сможет менять пароль 7 дней
# -M 90 - срок действия пароля
# -W 7 - предупреждения для пользователя

# показывает настройку пользователя
sudo chage -l dev_user

# Блокировка пользователя
sudo usermod -L dev_user

# Проверка блокировки
sudo passwd -S dev_user

# Разблокировка
sudo usermod -U dev_user