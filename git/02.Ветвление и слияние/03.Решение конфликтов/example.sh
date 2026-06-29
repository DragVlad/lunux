# Решение конфликтов в Git

# ---- Подготовка тестового репозитория ----
mkdir ~/git-conflict
cd ~/git-conflict
git init

# Создаем файл с базовым содержимым
cat > app.py << EOF
def main():
    print("Hello, World!")
    print("Version 1.0")
    
if __name__ == "__main__":
    main()
EOF

git add app.py
git commit -m "Initial commit: add app.py"

# ---- Создание ветки feature1 ----
git checkout -b feature1

# Изменяем файл в ветке feature1
cat > app.py << EOF
def main():
    print("Hello, World!")
    print("Version 1.1")
    print("Feature 1 added")
    
if __name__ == "__main__":
    main()
EOF

git add app.py
git commit -m "feat: add feature 1 to app.py"

# ---- Возврат на main и создание feature2 ----
git checkout main
git checkout -b feature2

# Изменяем файл в ветке feature2
cat > app.py << EOF
def main():
    print("Hello, World!")
    print("Version 1.2")
    print("Feature 2 added")
    
if __name__ == "__main__":
    main()
EOF

git add app.py
git commit -m "feat: add feature 2 to app.py"

# ---- Слияние feature1 в main ----
git checkout main
git merge feature1

# ---- Слияние feature2 в main (будет конфликт) ----
git merge feature2

# ---- Просмотр состояния конфликта ----
git status
git diff

# ---- Исследование конфликта ----
# Показать общий родительский коммит
git merge-base main feature2

# Показать изменения в текущей ветке
git diff --ours

# Показать изменения в сливаемой ветке
git diff --theirs

# ---- Разрешение конфликта вручную ----
# Открываем app.py и редактируем его
cat > app.py << EOF
def main():
    print("Hello, World!")
    print("Version 1.3")
    print("Feature 1 added")
    print("Feature 2 added")
    
if __name__ == "__main__":
    main()
EOF

# ---- Завершение слияния ----
git add app.py
git commit -m "merge: resolve conflict between feature1 and feature2"

# ---- Альтернативный способ: использование наших изменений ----
# Если нужно оставить только изменения из текущей ветки
git checkout --ours app.py
git add app.py
git commit -m "merge: keep ours changes"

# ---- Альтернативный способ: использование их изменений ----
# Если нужно оставить только изменения из сливаемой ветки
git checkout --theirs app.py
git add app.py
git commit -m "merge: keep theirs changes"

# ---- Отмена слияния ----
# Если что-то пошло не так
git merge --abort

# ---- Использование git mergetool ----
# Настройка и использование визуального инструмента
git config --global merge.tool vimdiff
git mergetool

# ---- Продвинутые техники разрешения конфликтов ----

# 1. Использование git log для понимания изменений
git log --merge --oneline

# 2. Просмотр изменений в конфликтных файлах
git diff --name-only --diff-filter=U

# 3. Просмотр трехстороннего diff
git diff --base app.py

# 4. Просмотр изменений только в нашей ветке
git diff --ours app.py

# 5. Просмотр изменений только в их ветке
git diff --theirs app.py
