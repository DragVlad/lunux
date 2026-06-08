# Перенаправление вывода
echo "Hello" > test.txt
echo "World" >> test.txt
cat test.txt

# Перенаправление ошибок
ls /nonexist 2> error.txt
cat error.txt

# Перенаправление всего
ls /home /nonexist &> all.txt
cat all.txt

# Скрыть вывод
echo "Silent" > /dev/null

# Перенаправление ввода
sort < test.txt

# Пайпы
cat test.txt | wc -l
ps aux | grep bash

# Tee (экран + файл)
echo "Save me" | tee saved.txt
cat saved.txt

# Очистка
rm -f test.txt error.txt all.txt saved.txt