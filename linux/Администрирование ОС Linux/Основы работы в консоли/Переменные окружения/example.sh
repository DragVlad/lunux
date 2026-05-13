#!/bin/bash

# Просмотр переменных
printenv
env
echo $HOME

# Создать новую переменную
export MY_NAME="John Doe"
echo $MY_NAME

# Создать переменную с путём
export MY_PROJECT="/home/$USER/projects"
echo $MY_PROJECT

# Создать числовую переменную
export MY_NUMBER=42
echo $MY_NUMBER

# Добавить новый путь в PATH (временно)
export PATH=$PATH:/home/$USER/myscripts
echo $PATH

# Изменить переменную
export MY_NAME="Jane Doe"
echo $MY_NAME

# Удалить созданные переменные
unset MY_NAME
echo $MY_NAME  # Ничего не выведет

unset MY_PROJECT
unset MY_NUMBER