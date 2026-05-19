python -V --version

which python

# Pyenv install

https://github.com/pyenv/pyenv

curl -fsSL https://pyenv.run | bash

copy
```
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# Restart your shell for the changes to take effect.

# Load pyenv-virtualenv automatically by adding
# the following to ~/.bashrc:

eval "$(pyenv virtualenv-init -)"
```

вставляем в  ~/.bashrc

maxhc@DESKTOP-BK7E710:~$ pyenv --version
pyenv 2.6.7

будут траблы, читаем еще wiki
https://github.com/pyenv/pyenv/wiki

pyenv install 3.13.2
pyenv global 3.13.2
which python

# Pipx

https://github.com/pypa/pipx?tab=readme-ov-file#on-linux

sudo apt update
sudo apt install pipx
pipx ensurepath