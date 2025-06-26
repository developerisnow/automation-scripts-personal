#!/bin/zsh
# 🎯 Claude Code Helpers

# Многострочный ввод через heredoc
claude-multi() {
    echo "📝 Enter multi-line prompt (Ctrl+D when done):"
    local prompt=$(cat)
    claude -p "$prompt"
}

# Claude с редактором
claude-edit() {
    local tmpfile=$(mktemp)
    ${EDITOR:-vim} "$tmpfile"
    if [[ -s "$tmpfile" ]]; then
        claude -p "$(cat $tmpfile)"
    fi
    rm -f "$tmpfile"
}

# Quick multiline с разделителем
claude-lines() {
    echo "📝 Enter lines (empty line to finish):"
    local lines=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
        lines="${lines}${line}\n"
    done
    claude -p "$lines"
}

# Алиасы для быстрого доступа
alias cm='claude-multi'
alias ce='claude-edit'
alias cl='claude-lines'

echo "🎯 Claude Code helpers loaded!"
echo ""
echo "📋 New commands:"
echo "  cm - Multi-line input (Ctrl+D to send)"
echo "  ce - Edit in vim/editor"
echo "  cl - Line by line (empty line to send)"
echo ""
echo "💡 In Claude Code use:"
echo "  Ctrl+J     - New line (works everywhere)"
echo "  Ctrl+Enter - Alternative new line"
echo "  \"\"\"text\"\"\" - Multi-line blocks"
