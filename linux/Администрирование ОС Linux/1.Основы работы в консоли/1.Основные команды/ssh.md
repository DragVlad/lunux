Примеры подключения по ssh:
```bash
ssh user@hostname
ssh user@ip
ssh host -l username -p 1488

# Принудительная аутентификация по паролю
ssh username@hostname/ip  -o PreferredAuthentications=password -o PubkeyAuthentication=no

# Режим дебага
ssh -v user@hostname
```

Генерация ssh-ключа
```bash
ssh-keygen -q -t Ed25519 -C "maxhc@inbox.ru" -f ./linux_base/test-key
# получаем публичный и приватный ключ и кладем публичный на наш сервер

ssh root@82.146.60.224 -i .ssh/test-key
```
