# Псевдонимы(alias)

Псевдонимы для команд и их комбинаций
```bash
echo "Hello ${USER}"

nano .bash_aliases
# записываем в файл
alias hw='echo "Hello ${USER}"'
# Обновляем окружение
source ~/.bashrc
# Проверяем алиасы
alias
# Юзаем алиас
hw
#> Hello USER
```