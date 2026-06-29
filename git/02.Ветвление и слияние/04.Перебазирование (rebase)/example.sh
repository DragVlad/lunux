# Перебазирование (rebase)

# ---- Подготовка тестового репозитория ----
mkdir ~/git-rebase
cd ~/git-rebase
git init

# Создаем начальные коммиты в main
echo "Initial content" > file.txt
git add file.txt
git commit -m "Initial commit"

echo "Main change 1" >> file.txt
git add file.txt
git commit -m "Main: change 1"

echo "Main change 2" >> file.txt
git add file.txt
git commit -m "Main: change 2"

# ---- Создание feature ветки от второго коммита ----
git checkout -b feature HEAD~1

# Вносим изменения в feature ветке
echo "Feature change 1" >> feature.txt
git add feature.txt
git commit -m "Feature: change 1"

echo "Feature change 2" >> feature.txt
git add feature.txt
git commit -m "Feature: change 2"

# ---- Просмотр истории перед rebase ----
git log --oneline --graph --all

# ---- Возврат на main и создание новых коммитов ----
git checkout main
echo "Main change 3" >> file.txt
git add file.txt
git commit -m "Main: change 3"

echo "Main change 4" >> file.txt
git add file.txt
git commit -m "Main: change 4"

# ---- Просмотр истории перед rebase ----
git log --oneline --graph --all

# ---- Перебазирование feature на main ----
git checkout feature
git rebase main

# ---- Просмотр истории после rebase ----
git log --oneline --graph --all

# ---- Создание конфликта при rebase ----
git checkout main
echo "Conflict line in main" >> file.txt
git add file.txt
git commit -m "Main: add conflict line"

git checkout feature
echo "Conflict line in feature" >> file.txt
git add file.txt
git commit -m "Feature: add conflict line"

# ---- Попытка rebase (будет конфликт) ----
git rebase main

# ---- Разрешение конфликта при rebase ----
# Открываем file.txt и разрешаем конфликт
# После разрешения:
git add file.txt
git rebase --continue

# ---- Отмена rebase ----
git rebase --abort

# ---- Интерактивный rebase ----
# Создаем несколько коммитов для интерактивного rebase
git checkout -b feature-interactive

echo "Feature A" > feature_a.txt
git add feature_a.txt
git commit -m "feat: add feature A"

echo "Feature B" > feature_b.txt
git add feature_b.txt
git commit -m "feat: add feature B"

echo "Feature C" > feature_c.txt
git add feature_c.txt
git commit -m "feat: add feature C"

# Интерактивный rebase на последние 3 коммита
git rebase -i HEAD~3

# В редакторе можно:
# - Изменить порядок коммитов
# - Объединить коммиты (squash)
# - Изменить сообщения (reword)
# - Разделить коммиты (edit)
# - Удалить коммиты (drop)

# ---- Rebase с сохранением изменений в main ----
git checkout main
git merge feature-interactive

# ---- Сравнение merge и rebase ----
# Создаем ветку для демонстрации
git checkout -b demo-merge HEAD~3
git merge main

git checkout -b demo-rebase HEAD~3
git rebase main

# Просмотр истории для сравнения
git log --oneline --graph --all
