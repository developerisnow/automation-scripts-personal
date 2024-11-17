# Проверим настройки Poetry
poetry config virtualenvs.path

# Стандартные локации Poetry
du -sh ~/Library/Caches/pypoetry/virtualenvs/* 2>/dev/null
du -sh ~/.cache/pypoetry/virtualenvs/* 2>/dev/null
du -sh .venv/ 2>/dev/null  # локальные окружения в проектах

# 4. Для каждого pyproject.toml из CSV:
echo "=== Project Dependencies Sizes ==="
# (нужно перейти в директорию и выполнить poetry show)

# Для каждого pyproject.toml проверить:
# - .venv
# - venv
# - .env
# - env
while IFS=, read -r title file created updated path; do
    dir=$(dirname "$path")
    echo "=== Checking $title ==="
    du -sh "$dir"/{.venv,venv,.env,env} 2>/dev/null
done < logs/python-local-configs-2024-11-11_07-05.csv

# Homebrew Python packages
du -sh /opt/homebrew/lib/python*
du -sh /usr/local/lib/python*

# System Python
du -sh /Library/Python/*/site-packages

# Pipenv обычно хранит окружения здесь
du -sh ~/.local/share/virtualenvs/*

# 1. В virtualenvs Pipenv
ls -la ~/.local/share/virtualenvs/*/lib/python*/site-packages/

# 2. В проектах с venv
ls -la /path/to/project/.venv/lib/python*/site-packages/

# 3. В системных пакетах
ls -la /opt/homebrew/lib/python3.11/site-packages/

# Посмотрим общие пакеты в разных окружениях
for venv in ~/.local/share/virtualenvs/*; do
    echo "=== $(basename $venv) ==="
    pip list --path "$venv/lib/python*/site-packages"
done