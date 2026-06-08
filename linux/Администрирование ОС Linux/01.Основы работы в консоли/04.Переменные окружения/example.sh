# Переменные окружения - практические примеры

# Просмотр переменных
echo $HOME
echo $USER
echo $SHELL
echo $PWD
echo $PATH

# Просмотр всех переменных
printenv
env

# Создание локальной переменной
MY_VAR="Hello, World!"
echo $MY_VAR

# Создание экспортированной переменной
export GLOBAL_VAR="I am global"
echo $GLOBAL_VAR

# Изменение существующей переменной
export PATH=$PATH:/my/custom/path
echo $PATH

# Добавление каталога в PATH (в начало)
export PATH=/my/new/path:$PATH
echo $PATH

# Удаление переменной
unset MY_VAR
echo $MY_VAR

# Переменная для редактора
export EDITOR=nano
echo $EDITOR

# Переменная для языка
export LANG=en_US.UTF-8
echo $LANG

# Временное изменение переменной для одной команды
LANG=ru_RU.UTF-8 date

# Просмотр всех переменных с grep
env | grep HOME
set | grep USER

# Сохранение переменной в файл
echo "export MY_SAVED_VAR='persistent'" >> ~/.bashrc
echo "MY_SAVED_VAR saved to ~/.bashrc"

# Применение изменений без перезагрузки
source ~/.bashrc

# Переменная PS1 (формат приглашения)
export PS1="\u@\h:\w\$ "
echo "PS1 changed"

# Показать PATH в удобном виде
echo $PATH | tr ':' '\n'

# Экспорт переменной в дочерний процесс
export CHILD_VAR="visible to child"
bash -c 'echo $CHILD_VAR'

# Локальная переменная НЕ видна дочернему процессу
LOCAL_VAR="not visible"
bash -c 'echo $LOCAL_VAR'

# Очистка
unset GLOBAL_VAR CHILD_VAR