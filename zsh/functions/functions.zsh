#!/usr/bin/env zsh
# 🔥 Kill port
# ------------
# Функция для убийства процесса на порту
kill_port() {
    if [ -z "$1" ]; then
        echo "Usage: kill_port <port>"
        return 1
    fi
    lsof -ti:$1 | xargs kill -9
    echo "✅ Killed process on port $1"
}

# Алиас для обратной совместимости
alias killport='kill_port'
