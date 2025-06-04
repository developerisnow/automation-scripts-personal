#!/bin/bash

# Code2Prompt Aliases Setup
# Добавляет алиасы в shell конфигурационные файлы

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIASES_CONTENT="$SCRIPT_DIR/aliases.txt"
HYPETRAIN_ALIASES_GENERATOR="$SCRIPT_DIR/generate_aliases.sh"

# Функции для определения shell
get_shell_config_file() {
    case $SHELL in
        */zsh)
            echo "$HOME/.zshrc"
            ;;
        */bash)
            echo "$HOME/.bashrc"
            ;;
        */fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Основная функция установки
install_aliases() {
    local config_file=$(get_shell_config_file)
    
    echo "🔧 Setting up Code2Prompt aliases..."
    echo "Shell: $SHELL"
    echo "Config file: $config_file"
    echo ""
    
    # Создаём резервную копию
    if [ -f "$config_file" ]; then
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ Backup created: ${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Удаляем старые aliases если есть
    if grep -q "# Code2Prompt Aliases" "$config_file" 2>/dev/null; then
        echo "🧹 Removing old aliases..."
        sed -i.bak '/# Code2Prompt Aliases/,/# End Code2Prompt Aliases/d' "$config_file"
    fi
    
    # Добавляем новые aliases
    echo "" >> "$config_file"
    echo "# Code2Prompt Aliases" >> "$config_file"
    echo "# Auto-generated - do not edit manually" >> "$config_file"
    echo "" >> "$config_file"
    
    # Генерируем и добавляем основные алиасы
    if [ -f "$ALIASES_CONTENT" ]; then
        cat "$ALIASES_CONTENT" >> "$config_file"
        echo "✅ Basic aliases added from $ALIASES_CONTENT"
    fi
    
    echo "" >> "$config_file"
    echo "# HypeTrain specific aliases" >> "$config_file"
    
    # Генерируем и добавляем HypeTrain алиасы
    if [ -x "$HYPETRAIN_ALIASES_GENERATOR" ]; then
        "$HYPETRAIN_ALIASES_GENERATOR" >> "$config_file"
        echo "✅ HypeTrain aliases generated and added"
    else
        echo "⚠️  HypeTrain aliases generator not found or not executable"
    fi
    
    echo "" >> "$config_file"
    echo "# End Code2Prompt Aliases" >> "$config_file"
    
    echo ""
    echo "✅ Aliases successfully installed to $config_file"
    echo ""
    echo "🔄 To reload aliases, run:"
    echo "   source $config_file"
    echo ""
    echo "📋 Available aliases:"
    echo "   c2p, ccode2prompt  - Main commands"
    echo "   hc2pHelp          - HypeTrain aliases help"
    echo "   hc2pQualityControl - Quality control context"
    echo "   hc2pSource        - Source code context"
    echo "   hc2pAllApps       - All applications"
    echo "   hc2pAllLibs       - All libraries"
    echo "   ...and many more (run hc2pHelp for full list)"
}

# Функция удаления
uninstall_aliases() {
    local config_file=$(get_shell_config_file)
    
    echo "🧹 Removing Code2Prompt aliases from $config_file..."
    
    if [ -f "$config_file" ] && grep -q "# Code2Prompt Aliases" "$config_file"; then
        sed -i.bak '/# Code2Prompt Aliases/,/# End Code2Prompt Aliases/d' "$config_file"
        echo "✅ Aliases removed successfully"
        echo "🔄 Please reload your shell: source $config_file"
    else
        echo "ℹ️  No aliases found to remove"
    fi
}

# Функция проверки
check_aliases() {
    local config_file=$(get_shell_config_file)
    
    echo "🔍 Checking Code2Prompt aliases status..."
    echo "Config file: $config_file"
    echo ""
    
    if [ -f "$config_file" ] && grep -q "# Code2Prompt Aliases" "$config_file"; then
        echo "✅ Aliases are installed"
        echo ""
        echo "📋 Installed sections:"
        grep -n "^# " "$config_file" | grep -A5 -B5 "Code2Prompt\|HypeTrain"
    else
        echo "❌ Aliases are not installed"
        echo ""
        echo "💡 Run './setup_aliases.sh install' to install them"
    fi
}

# Функция обновления
update_aliases() {
    echo "🔄 Updating Code2Prompt aliases..."
    uninstall_aliases
    sleep 1
    install_aliases
    echo "✅ Aliases updated successfully"
}

# Показать помощь
show_help() {
    echo "Code2Prompt Aliases Setup"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install    - Install aliases to shell config"
    echo "  uninstall  - Remove aliases from shell config"
    echo "  update     - Update existing aliases"
    echo "  check      - Check if aliases are installed"
    echo "  help       - Show this help"
    echo ""
    echo "Files:"
    echo "  aliases.txt           - Basic aliases template"
    echo "  generate_aliases.sh   - HypeTrain aliases generator"
    echo ""
    echo "Generated aliases include:"
    echo "  • c2p, ccode2prompt - Main code2prompt commands"
    echo "  • hc2p* - HypeTrain specific contexts"
    echo "  • Aggregate functions for bulk generation"
    echo "  • Template shortcuts for common use cases"
}

# Главная логика
case "${1:-install}" in
    install)
        install_aliases
        ;;
    uninstall|remove)
        uninstall_aliases
        ;;
    update)
        update_aliases
        ;;
    check|status)
        check_aliases
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 