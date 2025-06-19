#!/usr/bin/env zsh
# 🧭 NAVIGATION ALIASES - Быстрое перемещение по системе
# ======================================================
# ADHD tip: Чем короче алиас, тем чаще используется!

# 🏠 Quick Home Access
# --------------------
alias ~='cd ~'
alias h='cd ~'
alias home='cd ~'

# ⬆️ Going Up (вверх по директориям)
# -----------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Альтернативный вариант с числами (легче запомнить)
alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# 📁 Quick Access to Important Dirs
# ---------------------------------
# Repositories
alias repos='cd /Users/user/__Repositories'
alias rep='cd /Users/user/__Repositories'
alias r='cd /Users/user/__Repositories'
alias reposs='cd /Users/user/____Sandruk/__Vaults_Databases/__Repositories && pwd'

# Sandruk (Personal)
alias sand='cd /Users/user/____Sandruk'
alias pkm='cd /Users/user/____Sandruk/PKM'
alias brain='cd /Users/user/____Sandruk/PKM/__SecondBrain'
alias devopss='cd /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS && pwd'

# PARA Method folders
alias projectss='cd /Users/user/____Sandruk/___PARA/__Projects && pwd'
alias areass='cd /Users/user/____Sandruk/___PARA/__Areas && pwd' 
alias resourcess='cd /Users/user/____Sandruk/___PARA/__Resources && pwd'
alias archivess='cd /Users/user/____Sandruk/___PARA/__Archives && pwd'
alias systemm='cd /Users/user/____Sandruk/___PARA/__Areas/__7.2.SYSTEM-GROWTH-SECOND-BRAIN && pwd'

# Downloads & Temp
alias dl='cd ~/Downloads'
alias downloads='cd ~/Downloads'
alias tmp='cd /tmp'
alias temp='cd /Users/user/__Repositories/_temp'

# Config
alias conf='cd ~/.config'
alias zshconf='cd ~/.config/zsh'

# Media & Recordings
alias recs='cd /Users/user/NextCloud2/__Vaults_Databases_nxtcld/__Recordings_nxtcld/__cloud-recordings/_huawei_recordings && pwd'

# 🔄 Quick Back (вернуться назад)
# -------------------------------
alias -- -='cd -'  # Вернуться в предыдущую директорию
alias back='cd -'

# 📍 Bookmarks (закладки на часто используемые пути)
# --------------------------------------------------
# Добавь свои часто используемые пути здесь
# alias work='cd /path/to/work/project'
# alias docs='cd /path/to/documentation'

# 🚀 Smart Navigation (если установлены)
# --------------------------------------
# Эти команды работают если установлены соответствующие tools
# z - прыгает в часто используемые директории
# zoxide - умная навигация на основе frecency
# alias j='z'  # Если используешь z
# alias ji='zi'  # Интерактивный выбор

# 📂 Create and Enter (создать и войти)
# -------------------------------------
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Пример: mkcd new-project → создаст папку и перейдет в неё

# 🎯 Quick navigation helpers
# ---------------------------
# Show current location with tree
here() {
    echo "📍 Current location: $(pwd)"
    echo "📁 Contents:"
    ls -la | head -20
}

# Go to directory and list contents
cdl() {
    cd "$1" && ls -la
}

# Go to directory and show tree
cdt() {
    cd "$1" && tree -L 2
}

# Find directory and cd into it
fcd() {
    local dir=$(find . -type d -name "*$1*" 2>/dev/null | head -1)
    if [ -n "$dir" ]; then
        cd "$dir"
        pwd
    else
        echo "❌ Directory not found: $1"
    fi
}
