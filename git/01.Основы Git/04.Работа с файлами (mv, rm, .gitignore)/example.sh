# Работа с файлами: mv, rm, .gitignore

# ---- Настройка ----
cd ~/git-practice
# Убедитесь, что вы в репозитории

# ---- git rm - удаление файлов ----

# Создаем файл, добавляем и коммитим
echo "To be deleted" > delete_me.txt
git add delete_me.txt
git commit -m "Add file to delete"

# Удаляем файл из рабочей директории и индекса
git rm delete_me.txt

# Проверяем статус
git status

# Фиксируем удаление
git commit -m "Remove delete_me.txt"

# ---- git rm --cached - перестать отслеживать ----

# Создаем файл, который случайно закоммитили
echo "Secret data" > secret.env
git add secret.env
git commit -m "Add secret.env by mistake"

# Удаляем файл из индекса, но оставляем в рабочей директории
git rm --cached secret.env

# Проверяем статус (файл стал неотслеживаемым)
git status

# Добавляем его в .gitignore, чтобы не закоммитить снова
echo "secret.env" >> .gitignore
git add .gitignore
git commit -m "Stop tracking secret.env and add to gitignore"

# ---- git mv - перемещение/переименование файлов ----

# Создаем файл
echo "Content" > old_name.txt
git add old_name.txt
git commit -m "Add old_name.txt"

# Переименовываем файл (правильный способ)
git mv old_name.txt new_name.txt

# git mv эквивалентен:
# mv old_name.txt new_name.txt
# git rm old_name.txt
# git add new_name.txt

# Проверяем статус (Git покажет rename)
git status

# Фиксируем переименование
git commit -m "Rename old_name.txt to new_name.txt"

# ---- Перемещение файла в другую папку ----

# Создаем папку
mkdir src

# Перемещаем файл
git mv new_name.txt src/

# Проверяем статус
git status

# Фиксируем перемещение
git commit -m "Move new_name.txt to src/"

# ---- .gitignore - исключение файлов ----

# .gitignore — это файл, в котором перечислены шаблоны файлов,
# которые Git не должен отслеживать и добавлять.

# Создаем пример .gitignore
cat > .gitignore << EOF
# Логи
*.log

# Скомпилированные файлы
*.class
*.pyc

# Временные файлы ОС
.DS_Store
Thumbs.db

# Директории с зависимостями
node_modules/
.env/

# Исключение всего в папке temp
temp/

# Но не игнорировать важный файл внутри temp
!temp/important.txt
EOF

# Добавляем .gitignore в репозиторий
git add .gitignore
git commit -m "Add .gitignore file"

# ---- Проверка работы .gitignore ----

# Создаем файл, который должен игнорироваться
echo "Log content" > app.log
echo "Node modules" > node_modules/dummy.txt

# Проверяем статус (эти файлы не должны отображаться)
git status

# ---- Игнорирование уже отслеживаемых файлов ----

# Если файл уже отслеживается, добавление в .gitignore не поможет
# Нужно сначала удалить его из индекса

# Пример: отслеживаемый файл
echo "Important" > tracked.txt
git add tracked.txt
git commit -m "Add tracked.txt"

# Добавляем в .gitignore
echo "tracked.txt" >> .gitignore
git add .gitignore
git commit -m "Add tracked.txt to gitignore"

# Файл все еще отслеживается! Удаляем его из индекса
git rm --cached tracked.txt
git commit -m "Stop tracking tracked.txt"

# Теперь файл игнорируется
git status