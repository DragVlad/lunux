# ---- Настройка тестовой среды ----
mkdir ~/git-practice
cd ~/git-practice
git init

# ---- git status ----
# Показывает состояние рабочей директории и индекса
git status

# ---- git add ----
# Создаем новый файл
echo "Hello, Git!" > file1.txt

# Проверяем статус (файл неотслеживаемый)
git status

# Добавляем файл в индекс (staging area)
git add file1.txt

# Проверяем статус (файл подготовлен к коммиту)
git status

# ---- git commit ----
# Создаем коммит с сообщением
git commit -m "Add file1.txt with greeting"

# Проверяем статус (чисто, нет изменений для коммита)
git status

# ---- git log ----
# Просмотр истории коммитов
git log

# Более компактный вывод (одна строка на коммит)
git log --oneline

# Просмотр истории с графическим отображением веток
git log --oneline --graph --all

# ---- Изменяем файл и создаем еще один коммит ----
echo "New line" >> file1.txt
echo "Second file" > file2.txt

# Добавляем оба файла в индекс
git add file1.txt file2.txt

# Или добавляем все изменения в текущей директории
# git add .

# Создаем второй коммит
git commit -m "Add new line to file1 and create file2"

# ---- Просмотр последнего коммита ----
git log --oneline

# ---- git add -p (интерактивное добавление) ----
# Создаем файл с несколькими изменениями
echo -e "Line 1\nLine 2\nLine 3" > file3.txt
git add file3.txt
git commit -m "Add file3 with multiple lines"

# Изменяем файл
echo "Line 1 changed" > file3.txt
echo "Line 2" >> file3.txt
echo "Line 4" >> file3.txt

# Интерактивно выбираем, какие изменения добавить
git add -p file3.txt

# После выбора частей, создаем коммит
git commit -m "Partially update file3"

# ---- Продвинутые команды для просмотра истории ----

# Показать последние 3 коммита
git log -n 3

# Показать коммиты с изменениями (патчем)
git log -p

# Показать коммиты, сделанные сегодня
git log --since="today"

# Показать коммиты, сделанные за последнюю неделю
git log --since="1 week ago"

# Поиск коммитов по сообщению
git log --grep="file"

# Поиск коммитов по содержимому (что изменилось)
git log -S "Hello"

# ---- git commit --amend - исправление последнего коммита ----
# Если вы забыли добавить файл или хотите изменить сообщение
echo "Forgot this file" > forgot.txt
git add forgot.txt
git commit --amend -m "Add file1, file2, and forgot file"

# ---- git commit --amend --no-edit - исправить только состав коммита ----
echo "Another change" >> file1.txt
git add file1.txt
git commit --amend --no-edit