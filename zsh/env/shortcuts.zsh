#!/usr/bin/env zsh
# 🗂️ DIRECTORY SHORTCUTS - Quick navigation with $pkm or just pkm
# ==============================================================
# One place to manage all your important directories

# 🧠 PKM & Knowledge Management
export pkm="/Users/user/____Sandruk/___PKM"
export second_brain="$pkm/__SecondBrain"
export dailies="$second_brain/Dailies"
export dailies_outputs="$second_brain/Dailies_Outputs"
export vaults="$pkm/__Vaults_Databases"
export tools_vault="$vaults/__Tools__vault"
export outputs_ai="$pkm/_Outputs_AI"

# 📚 PARA Method Directories
export para="/Users/user/____Sandruk/___PARA"
export projects="$para/__Projects"
export areas="$para/__Areas"
export resources="$para/__Resources"
export archive="$para/__Archive"

# 💼 Career & DevOps
export career="$areas/_5_CAREER"
export devops="$career/DEVOPS"
export automations="$devops/automations"
export memory_bank="$devops/memory-bank"

# 🚂 HypeTrain Project
export hypetrain="/Users/user/__Repositories/HypeTrain"
export hypetrain_backend="$hypetrain/repositories/hypetrain-backend"
export hypetrain_garden="$hypetrain/repositories/hypetrain-garden"
export hypetrain_docs="$hypetrain/repositories/hypetrain-docs"
export hypetrain_frontend="$hypetrain/repositories/hypetrain-frontend"
export alex_pkm="$hypetrain/alex-PKM-hypetrain"

# 📂 Other Repositories
export repos="/Users/user/__Repositories"
export ccexporter="$repos/LLMs-claude-code-exporter"
export pm_agents="$repos/LLMs-github-project-management-agents"
export tg_crm="$repos/tg-mcp-assistant-telegram-crm__developerisnow"
export claude_task="$repos/claude-task-master"
export airpg="$repos/LLMs-airpg__belbix-master-week6-1"

# 🔧 Configuration Directories
export claude_config="/Users/user/.claude"
export claude_settings="/Users/user/.config/claude"
export zsh_config="/Users/user/.config/zsh"
export tmux_layouts="/Users/user/.tmux-layouts"

# 📦 Common Work Directories
export downloads="/Users/user/Downloads"
export desktop="/Users/user/Desktop"
export temp="$pkm/temp"

# 🌐 Cloud & Sync
export nextcloud="/Users/user/NextCloud2"
export backups="$nextcloud/Backups"

# ==============================================
# 🚀 NAVIGATION ALIASES - Just type the name!
# ==============================================

# PKM Navigation
alias pkm='cd $pkm'
alias brain='cd $second_brain'
alias dailies='cd $dailies'
alias outputs='cd $outputs_ai'
alias vaults='cd $vaults'
alias tools='cd $tools_vault'

# PARA Navigation
alias para='cd $para'
alias projects='cd $projects'
alias areas='cd $areas'
alias resources='cd $resources'
alias archive='cd $archive'

# Career & DevOps
alias career='cd $career'
alias devops='cd $devops'
alias auto='cd $automations'
alias automations='cd $automations'
alias memory='cd $memory_bank'

# HypeTrain Navigation
alias ht='cd $hypetrain'
alias hypetrain='cd $hypetrain'
alias htback='cd $hypetrain_backend'
alias htgarden='cd $hypetrain_garden'
alias htdocs='cd $hypetrain_docs'
alias htfront='cd $hypetrain_frontend'
alias htpkm='cd $alex_pkm'

# Other Projects
alias repos='cd $repos'
alias exporter='cd $ccexporter'
alias pmagents='cd $pm_agents'
alias tgcrm='cd $tg_crm'
alias taskmaster='cd $claude_task'
alias airpg='cd $airpg'

# Config Directories
alias cconfig='cd $claude_config'
alias csettings='cd $claude_settings'
alias zconfig='cd $zsh_config'

# Common Directories
alias dl='cd $downloads'
alias dt='cd $desktop'
alias tmp='cd $temp'

# Cloud & Backup
alias cloud='cd $nextcloud'
alias backup='cd $backups'

# ==============================================
# 🎯 SMART NAVIGATION FUNCTIONS
# ==============================================

# Go to directory and list contents
cdl() {
    cd "$1" && ls -la
}

# Go to path variable and list
goto() {
    local target=$(eval echo \$$1)
    if [[ -d "$target" ]]; then
        cd "$target" && ls -la
    else
        echo "❌ Directory not found for variable: $1"
        echo "💡 Available shortcuts:"
        shortcuts-list | grep "$1"
    fi
}

# List all path shortcuts
shortcuts-list() {
    echo "🗂️  DIRECTORY SHORTCUTS"
    echo "===================="
    echo ""
    echo "📂 PKM & Knowledge:"
    echo "  pkm         → $pkm"
    echo "  brain       → $second_brain"
    echo "  dailies     → $dailies"
    echo "  outputs     → $outputs_ai"
    echo ""
    echo "🚂 HypeTrain:"
    echo "  ht          → $hypetrain"
    echo "  htback      → Backend"
    echo "  htgarden    → Garden"
    echo "  htdocs      → Docs"
    echo ""
    echo "💼 Work Areas:"
    echo "  devops      → $devops"
    echo "  auto        → $automations"
    echo "  memory      → $memory_bank"
    echo ""
    echo "📦 Projects:"
    echo "  repos       → $repos"
    echo "  exporter    → Claude Exporter"
    echo "  pmagents    → PM Agents"
    echo ""
    echo "💡 Usage: Just type the shortcut name!"
    echo "         Or use: cd \$pkm"
}

# Quick jump with fzf
fzf-jump() {
    local selected=$(shortcuts-list | grep "→" | fzf --height 40% --reverse | awk '{print $1}')
    if [[ -n "$selected" ]]; then
        eval "$selected"
    fi
}

# Bind to Ctrl+G for quick go
bindkey -s '^g' 'fzf-jump\n'

# ==============================================
# 🔍 QUICK SEARCHES
# ==============================================

# Search in PKM
search-pkm() {
    rg "$1" $pkm
}

# Search in current project
search-here() {
    rg "$1" .
}

# Find files in PKM
find-pkm() {
    find $pkm -name "*$1*" -type f | head -20
}

# ==============================================
# 📍 BOOKMARKS (persistent across sessions)
# ==============================================

# Save current directory as bookmark
bookmark-save() {
    local name="${1:-$(basename $PWD)}"
    echo "export bookmark_$name='$PWD'" >> ~/.zsh_bookmarks
    source ~/.zsh_bookmarks
    echo "✅ Bookmarked '$PWD' as '$name'"
    echo "💡 Usage: bm $name"
}

# Go to bookmark
bm() {
    local bookmark_var="bookmark_$1"
    local target=$(eval echo \$$bookmark_var)
    if [[ -d "$target" ]]; then
        cd "$target"
        echo "📍 Jumped to bookmark: $1"
        pwd
    else
        echo "❌ Bookmark not found: $1"
        echo "💡 Available bookmarks:"
        bookmarks-list
    fi
}

# List bookmarks
bookmarks-list() {
    echo "📍 SAVED BOOKMARKS"
    echo "=================="
    if [[ -f ~/.zsh_bookmarks ]]; then
        cat ~/.zsh_bookmarks | sed 's/export bookmark_/  /' | sed 's/=/ → /'
    else
        echo "  No bookmarks saved yet"
        echo "  Use: bookmark-save <name>"
    fi
}

# Alias for bookmarks list
alias bookmarks='bookmarks-list'

# Load bookmarks file if exists
[[ -f ~/.zsh_bookmarks ]] && source ~/.zsh_bookmarks

# ==============================================
# 🚀 STARTUP MESSAGE
# ==============================================

echo "📂 Directory shortcuts loaded!"
echo "💡 Quick access: 'pkm', 'ht', 'devops' or 'shortcuts-list'"