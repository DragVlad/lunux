# Слияние веток (merge)

# ---- Подготовка тестового репозитория ----
cd ~/git-branching

# Создаем начальную ветку main с несколькими коммитами
echo "Project started" > README.md
git add README.md
git commit -m "Initial commit: add README"

echo "Main file" > main.txt
git add main.txt
git commit -m "Add main.txt"

# ---- Создание feature ветки ----
git checkout -b feature/new-module

# Вносим изменения в feature ветке
echo "Module code" > module.py
git add module.py
git commit -m "feat: add module.py"

echo "# Module documentation" >> module.py
git add module.py
git commit -m "docs: add module documentation"

# ---- Возврат на main и слияние ----
git checkout main

# Проверяем, что в main нет изменений
ls -la

# Выполняем слияние feature ветки в main
git merge feature/new-module

# Проверяем результат
ls -la
git log --oneline --graph --all

# ---- Создание ветки с конфликтом ----
git checkout -b feature/conflicting-change

# Меняем файл, который существует в main
echo "Changed in feature branch" > main.txt
git add main.txt
git commit -m "feat: change main.txt in feature"

# ---- Возврат на main и изменение того же файла ----
git checkout main

echo "Changed in main branch" > main.txt
git add main.txt
git commit -m "fix: change main.txt in main"

# ---- Попытка слияния (будет конфликт) ----
git merge feature/conflicting-change

# ---- Разрешение конфликта ----
# Открываем файл main.txt и редактируем его
# После разрешения конфликта:
git add main.txt
git commit -m "merge: resolve conflict in main.txt"

# ---- Fast-forward merge (без конфликтов) ----
git checkout -b feature/simple-change
echo "Simple change" > simple.txt
git add simple.txt
git commit -m "feat: add simple.txt"

# Возврат на main
git checkout main

# Выполняем fast-forward merge
git merge feature/simple-change

# Проверяем историю (ветка feature/simple-change стала частью main)
git log --oneline --graph --all

# ---- Слияние с --no-ff (без fast-forward) ----
git checkout -b feature/no-ff-change
echo "No-ff change" > noff.txt
git add noff.txt
git commit -m "feat: add noff.txt"

git checkout main
git merge --no-ff feature/no-ff-change -m "merge: add no-ff feature"

# Проверяем историю (виден merge commit)
git log --oneline --graph --all

# ---- Слияние с --squash (объединение коммитов) ----
git checkout -b feature/squash-change
echo "Squash change 1" > squash1.txt
git add squash1.txt
git commit -m "feat: add squash1"

echo "Squash change 2" > squash2.txt
git add squash2.txt
git commit -m "feat: add squash2"

git checkout main
git merge --squash feature/squash-change
git commit -m "feat: add squash changes (squashed)"

# Проверяем историю (все коммиты из feature объединены в один)
git log --oneline --graph --all