#!/usr/bin/env zsh
# 📜 HISTORY CONFIGURATION - Настройки истории команд
# ===================================================
# Супер-важно для ADHD: легко найти что делал раньше!

# 📍 История команд
# -----------------
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000        # Количество команд в памяти
export SAVEHIST=50000        # Количество команд сохраняемых в файл
export HISTFILESIZE=100000   # Максимальный размер файла истории

# 🔧 Опции истории
# ----------------
setopt EXTENDED_HISTORY          # Записывать timestamp для каждой команды
setopt HIST_EXPIRE_DUPS_FIRST    # Удалять дубликаты первыми при переполнении
setopt HIST_IGNORE_DUPS          # Не записывать дубликаты подряд
setopt HIST_IGNORE_ALL_DUPS      # Удалять старые записи если есть новый дубликат
setopt HIST_FIND_NO_DUPS         # Не показывать дубликаты при поиске
setopt HIST_IGNORE_SPACE         # Не записывать команды начинающиеся с пробела
setopt HIST_SAVE_NO_DUPS         # Не сохранять дубликаты в файл
setopt HIST_REDUCE_BLANKS        # Удалять лишние пробелы из команд
setopt HIST_VERIFY               # Показать команду перед выполнением при !!
setopt SHARE_HISTORY             # Делиться историей между всеми сессиями
setopt HIST_BEEP                 # Beep при попытке доступа к несуществующей записи

# 📝 Игнорировать определенные команды
# -------------------------------------
# Не сохранять в истории эти команды
export HISTORY_IGNORE="(ls|cd|pwd|exit|date|* --help|man *|history*|clear|c)"

# 🔍 Улучшенный поиск в истории
# ------------------------------
# Стрелки вверх/вниз для поиска с учетом начала команды
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Ctrl+R для обратного поиска (обычно уже настроено)
bindkey '^R' history-incremental-search-backward

# PageUp/PageDown для быстрого перемещения
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward

# 🎯 Алиасы для работы с историей
# --------------------------------
alias h='history'
alias history='history -i'  # Показывать с timestamp
alias hl='history | less'   # История с пейджером
alias hs='history | grep'   # Поиск в истории

# Последние N команд
alias h10='history -10'
alias h20='history -20'
alias h50='history -50'

# 📊 Статистика использования команд
# -----------------------------------
# Топ 10 самых используемых команд
histtop() {
    history | \
    awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | \
    grep -v "./" | \
    column -c3 -s " " -t | \
    sort -nr | nl | head -n ${1:-10}
}

# Топ команд за сегодня
histtoday() {
    history -i | grep "$(date +%Y-%m-%d)" | \
    awk '{$1=$2=$3=""; print $0}' | \
    awk '{CMD[$1]++;count++;}END { for (a in CMD)print CMD[a] " " a;}' | \
    sort -nr | head -20
}

# 🔄 Функции для работы с историей
# ---------------------------------
# Удалить дубликаты из истории
histdedup() {
    cp ~/.zsh_history ~/.zsh_history.backup
    awk '!seen[$0]++' ~/.zsh_history > ~/.zsh_history.tmp
    mv ~/.zsh_history.tmp ~/.zsh_history
    echo "✅ History deduplicated! Backup saved to ~/.zsh_history.backup"
}

# Поиск и выполнение команды из истории
histrun() {
    if [ -z "$1" ]; then
        echo "Usage: histrun <search term>"
        return 1
    fi
    local cmd=$(history | grep -i "$1" | tail -1 | sed 's/^[ ]*[0-9]*[ ]*//')
    if [ -n "$cmd" ]; then
        echo "Executing: $cmd"
        eval "$cmd"
    else
        echo "No command found matching: $1"
    fi
}

# Бэкап истории
histbackup() {
    local backup_file="$HOME/.zsh_history.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zsh_history "$backup_file"
    echo "✅ History backed up to: $backup_file"
}

# 📈 История по дням недели
histweekday() {
    echo "📊 Commands by day of week:"
    history -i | \
    awk '{print $3}' | \
    awk -F- '{print strftime("%A", mktime($1" "$2" "$3" 0 0 0"))}' | \
    sort | uniq -c | sort -nr
}

# 🕐 История по часам
histhours() {
    echo "📊 Commands by hour:"
    history -i | \
    awk '{print $4}' | \
    cut -d: -f1 | \
    sort | uniq -c | sort -nr
}

# 🧹 Очистить историю (с подтверждением)
histclear() {
    echo "⚠️  This will clear your entire ZSH history!"
    echo -n "Are you sure? (y/N): "
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo "" > ~/.zsh_history
        echo "✅ History cleared!"
    else
        echo "❌ Cancelled"
    fi
}

# 💡 ADHD Tips
# ------------
# 1. Используй пробел перед командой чтобы НЕ сохранять её в истории
# 2. Используй histtop чтобы увидеть что чаще всего делаешь
# 3. Настрой алиасы для частых команд из histtop
# 4. Делай histbackup перед экспериментами
