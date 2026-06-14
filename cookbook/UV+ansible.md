- Устанавливаем uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

- Инициализация проекта
```bash
uv init ansible-tech
uv add ansible
```

- Теперь можем запускать ansible под командами:
```bash
uv run ansible myhosts -m ping -i inventory.ini
```