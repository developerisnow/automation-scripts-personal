#!/usr/bin/env zsh
# 🔮 OBSIDIAN TOOLS - Инструменты для работы с Obsidian
# =====================================================
# code2prompt, obsidian2prompt и другие конвертеры

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

# 📝 Obsidian to Prompt Scripts
# -----------------------------
# o2p = obsidian to prompt (основной скрипт)
# o2pd = obsidian to prompt with date (с датой)
# ac2p = all code to prompt (весь код в prompt)

# Основные команды (нужно будет заполнить пути из твоего .zshrc)
# alias o2p='...'    # obsidian to prompt
# alias o2pd='...'   # obsidian to prompt + date
# alias ac2p='...'   # all code to prompt

# 📊 Obsidian Stats & Analysis
# ----------------------------
# Подсчет заметок, слов, тегов
alias obs-count='find ~/____Sandruk/PKM -name "*.md" | wc -l'  # Количество .md файлов
alias obs-words='find ~/____Sandruk/PKM -name "*.md" -exec wc -w {} + | tail -1'  # Общее количество слов

# 🔄 Obsidian Sync & Backup
# -------------------------
# Быстрые команды для синхронизации и бэкапа
alias obs-backup='cd ~/____Sandruk/PKM && git add -A && git commit -m "Auto backup $(date +%Y-%m-%d_%H:%M)" && git push'
alias obs-pull='cd ~/____Sandruk/PKM && git pull'
alias obs-status='cd ~/____Sandruk/PKM && git status'

# 📁 Quick Access to Obsidian Folders
# -----------------------------------
alias vault='cd ~/____Sandruk/PKM'
alias daily='cd ~/____Sandruk/PKM/__SecondBrain/Dailies'
alias templates='cd ~/____Sandruk/PKM/__SecondBrain/Templates'

# 🔍 Search in Obsidian (через ripgrep)
# -------------------------------------
obs-search() {
    if [ -z "$1" ]; then
        echo "Usage: obs-search 'search term'"
        return 1
    fi
    rg "$1" ~/____Sandruk/PKM --type md
}

# Пример: obs-search "ADHD" → найдет все упоминания ADHD в vault

# 🏷️ Tag Management
# -----------------
obs-tags() {
    echo "📊 Top 20 tags in your vault:"
    grep -h "^#" ~/____Sandruk/PKM/**/*.md 2>/dev/null | 
    sed 's/ /\n/g' | 
    grep "^#" | 
    sort | uniq -c | 
    sort -rn | 
    head -20
}

# 📅 Daily Notes Helper
# ---------------------
obs-today() {
    local today=$(date +%Y-%m-%d)
    local file="~/____Sandruk/PKM/__SecondBrain/Dailies/${today}.md"
    if [ -f "$file" ]; then
        echo "Opening today's note: $today"
        open "$file"  # или code "$file" если предпочитаешь VSCode
    else
        echo "Creating today's note: $today"
        # Создать из шаблона если нужно
    fi
}

# === Migrated from old .zshrc ===
# Code2Prompt variants (убрали конфликтующие алиасы)
# alias ac2pts='code2prompt --ext ts'  # Конфликт с алиасом выше
# alias ac2ppy='code2prompt --ext py'  # Конфликт с алиасом выше

# O2P Script path
export O2P_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obs2prompt_obsidian_to_prompt.py"

# Main o2p function
function o2p() {
    if [ -z "$1" ]; then
        echo "Usage: o2p <filename> [depth] [debug]"
        echo "Example: o2p 'my note.md' 2"
        return 1
    fi
    python3 "$O2P_SCRIPT_PATH" "$@"
}

# Shortcuts for different depths
function o2p1() { 
    o2p "$1" 1
}

function o2p2() { 
    o2p "$1" 2
}

function o2p3() { 
    o2p "$1" 3
}

# Debug version
function o2pd() { 
    o2p "$1" 1 "debug"
}

# Check o2p setup
function o2p-check() {
    echo "Checking o2p setup..."
    echo "Script path: $O2P_SCRIPT_PATH"
    if [ -f "$O2P_SCRIPT_PATH" ]; then
        echo "✅ Script found"
    else
        echo "❌ Script not found!"
    fi
}

# === Migrated from old .zshrc ===
ac2pts() {
ac2ppy() {
export O2P_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obs2prompt_obsidian_to_prompt.py"
function o2p {
        echo "Usage: o2p <filename> [depth] [debug]"
        echo "Example: o2p 'my note.md' 2"
function o2p1() { 
    o2p "$1" 1
function o2p2() { 
    o2p "$1" 2
function o2p3() { 
    o2p "$1" 3
function o2pd() { 
    o2p "$1" 1 "debug"
function o2p-check {
    echo "Checking o2p setup..."
