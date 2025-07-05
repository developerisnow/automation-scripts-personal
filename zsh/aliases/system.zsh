#!/usr/bin/env zsh
# 💻 SYSTEM ALIASES - Улучшенные системные команды
# ================================================
# Modern replacements для стандартных Unix команд

# 📂 Better ls (если установлен exa/eza)
# --------------------------------------
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias l='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    alias lt='eza --tree --icons'
    alias ltl='eza --tree --level=2 --icons'
else
    # Fallback на обычный ls
    alias ls='ls -G'  # macOS colored
    alias l='ls -CF'
    alias ll='ls -lFh'
    alias la='ls -lAFh'
fi

# 🔍 Better cat (если установлен bat)
# -----------------------------------
if command -v bat &> /dev/null; then
    alias cat='bat'
    alias catp='bat --plain'  # Без номеров строк
    alias catl='bat --line-range'  # Показать диапазон строк
fi

# 🔎 Better find/grep (если установлен ripgrep)
# ---------------------------------------------
if command -v rg &> /dev/null; then
    alias grep='rg'
    alias rgi='rg -i'  # Case insensitive
    alias rgf='rg --files'  # Список файлов
    alias rgh='rg --hidden'  # Включая скрытые
fi

# 📊 Disk usage (если установлен dust)
# ------------------------------------
if command -v dust &> /dev/null; then
    alias du='dust'
else
    alias du='du -h'
    alias duh='du -h --max-depth=1'
fi

# 📈 Better top (если установлен htop/btop)
# -----------------------------------------
if command -v btop &> /dev/null; then
    alias top='btop'
elif command -v htop &> /dev/null; then
    alias top='htop'
fi

# 📁 Directory operations
# -----------------------
alias mkdir='mkdir -pv'  # Создавать родительские директории + verbose
# alias cp='cp -iv'        # Interactive + verbose
# alias mv='mv -iv'        # Interactive + verbose
# alias rm='rm -i'         # Interactive (защита от случайного удаления)

# Безопасное удаление в корзину (если установлен trash)
if command -v trash &> /dev/null; then
    alias del='trash'    # Удалить в корзину
    alias rm!='rm'       # Настоящий rm когда точно нужно
fi

# 🌐 Network
# ----------
alias ip='curl -s ifconfig.me'  # Внешний IP
alias localip='ipconfig getifaddr en0'  # Локальный IP (macOS)
alias ping='ping -c 5'  # Пинг только 5 раз
alias ports='netstat -tulanp'  # Открытые порты

# 📦 Package managers
# -------------------
# Homebrew (macOS)
if command -v brew &> /dev/null; then
    alias brewup='brew update && brew upgrade'
    alias brewclean='brew cleanup -s'
    alias brewlist='brew list --formula'
    alias brewcask='brew list --cask'
fi

# npm
alias npmg='npm list -g --depth=0'  # Глобальные пакеты
alias npmclean='npm cache clean --force'

# 🔧 System info & maintenance
# ----------------------------
alias reload='source ~/.zshrc'  # Перезагрузить конфиг
alias zshrc='${EDITOR} ~/.zshrc'  # Редактировать .zshrc
alias zshconfig='${EDITOR} ~/.config/zsh'  # Редактировать zsh конфиг

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
    alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"  # Удалить .DS_Store
    alias emptytrash='rm -rf ~/.Trash/*'  # Очистить корзину
    alias flushdns='sudo dscacheutil -flushcache'  # Сбросить DNS кэш
fi

# 📝 Quick editors
# ----------------
alias v='vim'
alias nv='nvim'
alias c='code'
alias s='subl'

# 🕐 Date & Time
# --------------
alias now='date +"%Y-%m-%d Week %V %H:%M:%S "'
alias nowdate='date +"%Y-%m-%d"'
alias nowtime='date +"%H:%M:%S"'
alias week='date +%V'  # Номер недели

# 🔄 Process management
# ---------------------
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'  # Поиск процессов
# killport теперь функция в tools.zsh

# 📋 Clipboard (macOS)
# --------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias copy='pbcopy'
    alias paste='pbpaste'
    # Пример: ls | copy → скопировать вывод в буфер
fi

# 🎯 Shortcuts
# ------------
alias h='history'
alias j='jobs'
alias e='exit'
alias c='clear'
alias cls='clear'

# 🔐 Permissions
# --------------
alias chmodx='chmod +x'  # Сделать исполняемым
alias chmodr='chmod -R'  # Рекурсивно

# 💾 Backup function
# ------------------
backup() {
    if [ -z "$1" ]; then
        echo "Usage: backup <file/directory>"
        return 1
    fi
    cp -r "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backed up to: $1.backup.$(date +%Y%m%d_%H%M%S)"
}

# 🔍 Extract any archive
# ----------------------
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# === Migrated from old .zshrc ===
alias findname='find . -name "*" -print | grep -i'
