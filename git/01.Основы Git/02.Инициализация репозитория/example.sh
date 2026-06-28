# Перейдите в директорию вашего проекта
cd ~/my-project

# Создайте новый пустой репозиторий Git
git init

# Теперь в папке появилась скрытая директория .git
ls -la | grep .git

# ---- Первый коммит в новом репозитории ----

# Создаем файл README.md
echo "# My Project" > README.md

# Добавляем файл в индекс
git add README.md

# Создаем первый коммит
git commit -m "Initial commit"

# Проверяем статус
git status

# ---- Клонирование существующего репозитория ----

# Клонирование по HTTPS
git clone https://github.com/user/repo.git

# Клонирование по SSH
git clone git@github.com:user/repo.git

# Клонирование в директорию с другим именем
git clone https://github.com/user/repo.git my-folder

# ---- Проверка состояния репозитория ----

# Убедитесь, что вы находитесь внутри репозитория
git status

# Посмотреть удаленные репозитории (после клонирования)
git remote -v

# ---- Инициализация в существующей папке ----

# Если у вас уже есть папка с проектом
cd /path/to/existing/project
git init
git add .
git commit -m "Initial commit with existing files"