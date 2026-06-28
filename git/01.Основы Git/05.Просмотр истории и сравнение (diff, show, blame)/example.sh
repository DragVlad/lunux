# Просмотр истории и сравнение: diff, show, blame

# ---- Настройка тестовой среды ----
# Продолжаем работать в ~/git-practice

# Создаем файл для экспериментов
echo "Line 1: Initial content" > example.txt
echo "Line 2: More content" >> example.txt
echo "Line 3: Final content" >> example.txt
git add example.txt
git commit -m "Add example.txt with 3 lines"

# Вносим изменения
echo "Line 1: Updated content" > example.txt
echo "Line 2: More content" >> example.txt
echo "Line 3: Final content" >> example.txt
echo "Line 4: New line" >> example.txt

# ---- git diff - сравнение изменений ----

# Просмотр неиндексированных изменений (изменения в рабочей директории)
git diff

# Просмотр конкретного файла
git diff example.txt

# Просмотр индексированных изменений (что уже в staging area)
git add example.txt
git diff --staged

# Сравнение между двумя коммитами
git log --oneline
git diff <hash1> <hash2>

# Сравнение веток
git diff main..feature-branch

# Сравнение с предыдущим коммитом
git diff HEAD~1 HEAD

# ---- git diff с опциями ----

# Показать только имена измененных файлов
git diff --name-only

# Показать статистику изменений
git diff --stat

# Показать изменения в компактном виде
git diff --word-diff

# ---- git show - просмотр коммита ----

# Просмотр последнего коммита
git show

# Просмотр конкретного коммита
git show <hash>

# Просмотр только изменений в определенном файле за коммит
git show <hash> -- example.txt

# Просмотр только сообщения коммита (без изменений)
git show -s

# Просмотр коммита в компактном виде
git show --oneline

# ---- git blame - кто изменил файл ----

# Показывает, кто и когда изменил каждую строку файла
git blame example.txt

# Более компактный вывод (без email, только имена)
git blame -s example.txt

# Ограничить диапазон строк
git blame -L 1,10 example.txt

# Показать время изменения в читаемом формате
git blame -t example.txt

# ---- git blame с деталями ----
# Показать хеш коммита, автора, дату и строку
git blame -f example.txt

# ---- Использование git log для просмотра изменений ----

# Показать историю с изменениями для конкретного файла
git log -p example.txt

# Показать коммиты, которые изменили определенную строку (продвинуто)
git log -S "Updated" --oneline

# Показать коммиты по дате
git log --since="2024-01-01" --until="2024-12-31"

# Показать коммиты с графиком
git log --oneline --graph --all

# ---- Использование git diff для сравнения версий файла ----

# Сравнить текущую версию с версией 2 коммита назад
git diff HEAD~2 example.txt

# Сравнить две разные версии файла
git diff <hash1> <hash2> -- example.txt