#!/usr/bin/env zsh
# 🐳 DOCKER ALIASES - Docker и Docker Compose команды
# ===================================================

# 🚀 Docker basics
# ----------------
alias d='docker'
alias dp='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dil='docker images | head -20'  # Список первых 20 образов

# 📦 Container management
# -----------------------
alias dstart='docker start'
alias dstop='docker stop'
alias drestart='docker restart'
alias dkill='docker kill'
alias drm='docker rm'
alias drmf='docker rm -f'  # Force remove

# Remove all stopped containers
alias dprune='docker container prune -f'

# 🧹 Cleanup commands
# -------------------
alias dclear='docker system prune -af --volumes'  # ⚠️ Удалит ВСЁ!
alias dclean='docker system prune -f'  # Безопасная очистка
alias drmi='docker rmi'  # Remove image
alias drmid='docker rmi $(docker images -q -f dangling=true)'  # Remove dangling images

# 📊 Docker stats & logs
# ----------------------
alias dstats='docker stats'
alias dlogs='docker logs'
alias dlogsf='docker logs -f'  # Follow logs
alias dlogst='docker logs --tail 50'  # Last 50 lines

# 🏗️ Docker Compose
# -----------------
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'  # Detached mode
alias dcd='docker-compose down'
alias dcr='docker-compose restart'
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'  # Follow logs
alias dcps='docker-compose ps'
alias dcexec='docker-compose exec'

# Quick rebuild
alias dcb='docker-compose build'
alias dcub='docker-compose up --build'
alias dcubd='docker-compose up --build -d'

# 🔍 Docker inspect & debug
# -------------------------
alias dinspect='docker inspect'
alias dexec='docker exec -it'
alias dsh='docker exec -it $1 /bin/sh'  # Shell into container
alias dbash='docker exec -it $1 /bin/bash'  # Bash into container

# 🌐 Docker network
# -----------------
alias dn='docker network'
alias dnl='docker network ls'
alias dni='docker network inspect'

# 📁 Docker volumes
# -----------------
alias dv='docker volume'
alias dvl='docker volume ls'
alias dvi='docker volume inspect'
alias dvrm='docker volume rm'
alias dvprune='docker volume prune -f'

# 🎯 Useful functions
# -------------------
# Быстро зайти в контейнер
denter() {
    if [ -z "$1" ]; then
        echo "Usage: denter <container_name_or_id>"
        return 1
    fi
    docker exec -it "$1" "${2:-/bin/bash}"
}

# Показать IP адрес контейнера
dip() {
    if [ -z "$1" ]; then
        echo "Usage: dip <container_name_or_id>"
        return 1
    fi
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

# Остановить все контейнеры
dstopall() {
    docker stop $(docker ps -q)
}

# Удалить все остановленные контейнеры
drmall() {
    docker rm $(docker ps -a -q)
}

# Показать размер образов
dsizes() {
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k3 -h
}

# 💡 Docker tips
# --------------
alias dtips='echo "
🐳 Docker Tips:
- denter <name>    → Быстро войти в контейнер
- dip <name>       → Показать IP контейнера
- dstopall         → Остановить все контейнеры
- dclean           → Безопасная очистка системы
- dclear           → ⚠️ УДАЛИТЬ ВСЁ (образы, volumes, etc)
- dsizes           → Размеры образов
"'

