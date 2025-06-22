#!/usr/bin/env zsh
# 🛠️ Code2Prompt Aliases
# ----------------------
# c2p = code to prompt (основная команда)
alias c2p='code2prompt'

# Варианты с разными флагами
alias c2pf='code2prompt --include-folders'  # Включить структуру папок
alias c2pr='code2prompt --recursive'        # Рекурсивно все файлы
alias c2px='code2prompt --exclude'          # С исключениями

# Быстрые варианты для разных языков
alias py2p='code2prompt --ext py'    # Только Python файлы
alias js2p='code2prompt --ext js'    # Только JavaScript
alias ts2p='code2prompt --ext ts'    # Только TypeScript
alias md2p='code2prompt --ext md'    # Только Markdown
# ac2p = all code to prompt (весь код в prompt)
alias ac2p='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh'

# Функции для разных языков
ac2pts() {
    sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh "$1" ts
}

ac2ppy() {
    sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/code2prompt.sh "$1" py
}

alias s2p='/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/search2prompt.sh "$@"'
alias curs2p='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/CursorRulesMemorybankTasks2Prompt.sh'