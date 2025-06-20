#!/usr/bin/env zsh
# 🔮 OBSIDIAN TOOLS - Инструменты для работы с Obsidian
# =====================================================
#  obsidian2prompt

# Default paths and settings
export O2P_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obs2prompt_obsidian_to_prompt.py"
export O2P_OUTPUT_DIR="/Users/user/____Sandruk/___PKM/temp"
export OBSIDIAN_VAULT_PATH="/Users/user/____Sandruk/___PKM"

# Create output directory if it doesn't exist
[ ! -d "$O2P_OUTPUT_DIR" ] && mkdir -p "$O2P_OUTPUT_DIR"

# Main o2p function
function o2p {
    local start_file="$1"
    local depth="${2:-1}"
    local debug_flag="${3:-}"

    # Check if script exists
    if [ ! -f "$O2P_SCRIPT_PATH" ]; then
        echo "Error: Script not found at $O2P_SCRIPT_PATH"
        return 1
    fi

    # Check if input file is provided
    if [ -z "$start_file" ]; then
        echo "Usage: o2p <filename> [depth] [debug]"
        echo "Example: o2p 'my note.md' 2"
        return 1
    fi

    # Execute python script
    if [ -n "$debug_flag" ]; then
        python3 "$O2P_SCRIPT_PATH" "$start_file" \
            --vault "$OBSIDIAN_VAULT_PATH" \
            --depth "$depth" \
            --output "$O2P_OUTPUT_DIR/aggregate_${start_file%.md}.txt" \
            --debug
    else
        python3 "$O2P_SCRIPT_PATH" "$start_file" \
            --vault "$OBSIDIAN_VAULT_PATH" \
            --depth "$depth" \
            --output "$O2P_OUTPUT_DIR/aggregate_${start_file%.md}.txt"
    fi
}

# Convenience functions
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

# Setup check function
function o2p-check {
    echo "Checking o2p setup..."
    echo "Script path: $O2P_SCRIPT_PATH"
    echo "Vault path: $OBSIDIAN_VAULT_PATH"
    echo "Output directory: $O2P_OUTPUT_DIR"
    
    if [ -f "$O2P_SCRIPT_PATH" ]; then
        echo "✅ Script exists"
    else
        echo "❌ Script not found"
    fi
    
    if [ -d "$OBSIDIAN_VAULT_PATH" ]; then
        echo "✅ Vault exists"
    else
        echo "❌ Vault not found"
    fi
    
    if [ -d "$O2P_OUTPUT_DIR" ]; then
        echo "✅ Output directory exists"
    else
        echo "❌ Output directory not found"
    fi
    
    echo "Python environment:"
    which python3 || echo "❌ Python3 not found"
    python3 --version || echo "❌ Cannot get Python version"
    
    echo "Required packages:"
    if python3 -c "import pyperclip" 2>/dev/null; then
        echo "✅ pyperclip installed"
    else
        echo "❌ pyperclip not installed"
    fi
}

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
alias obsort='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obsidian_file_sorter.py --verbose'

# 📁 Quick Access to Obsidian Folders
# -----------------------------------
alias vault='cd ~/____Sandruk/PKM'
alias daily='cd ~/____Sandruk/PKM/__SecondBrain/Dailies'
alias templates='cd ~/____Sandruk/PKM/__SecondBrain/Templates'

# Navigation
alias obs-tasks='cd /Users/user/__Repositories/obsidian-tasks'
alias obs-tg='cd /Users/user/__Repositories/obsidian-telegram-sync__soberhacker'

alias promptextract='cd /Users/user/____Sandruk/___PKM && python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/prompts_extractor.py'

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
