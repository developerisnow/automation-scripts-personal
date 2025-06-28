#!/bin/zsh
# 🚀 ZSH Automation Master Loader
# ================================
# Загружает все скрипты из automations/zsh в правильном порядке

# Base path
AUTOMATION_BASE="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh"

# 1️⃣ Environment variables
for file in $AUTOMATION_BASE/env/*.zsh; do
    [[ -f "$file" ]] && source "$file"
done

# 2️⃣ Functions (loaded first, used by aliases)
for file in $AUTOMATION_BASE/functions/*.zsh; do
    [[ -f "$file" ]] && source "$file"
done

# 3️⃣ Config files
for file in $AUTOMATION_BASE/config/*.zsh; do
    [[ -f "$file" ]] && [[ "$file" != *.conf ]] && source "$file"
done

# 4️⃣ All aliases (except problematic ones for now)
for file in $AUTOMATION_BASE/aliases/*.zsh; do
    if [[ -f "$file" ]]; then
        # Skip problematic files temporarily
        if [[ "$file" != *"hypetrain-quickref.zsh" ]] && [[ "$file" != *"tool-tmux.zsh" ]]; then
            source "$file"
        fi
    fi
done

# 5️⃣ Load specific loaders
[[ -f "$AUTOMATION_BASE/scripts/claude-monitor-loader.zsh" ]] && source "$AUTOMATION_BASE/scripts/claude-monitor-loader.zsh"
[[ -f "$AUTOMATION_BASE/scripts/claude-json-loader.zsh" ]] && source "$AUTOMATION_BASE/scripts/claude-json-loader.zsh"
[[ -f "$AUTOMATION_BASE/scripts/tmux-workspaces-loader.zsh" ]] && source "$AUTOMATION_BASE/scripts/tmux-workspaces-loader.zsh"

# 6️⃣ Final touches
[[ -f "$AUTOMATION_BASE/zsh_last.zsh" ]] && source "$AUTOMATION_BASE/zsh_last.zsh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 AUTOMATIONS LOADED!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Monitoring: monclaude, monclaude-stats"
echo "🎯 Workspaces: htgo, twin1"
echo "📋 JSON Tools: claude-analyze, claude-status"
echo ""
echo "💡 Type 'automation-help' for full command list"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Help function
automation-help() {
    echo "🚀 AUTOMATION COMMANDS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 MONITORING:"
    echo "  monclaude         - Live monitor all Claude agents"
    echo "  monclaude-stats   - Workspace statistics"
    echo "  monclaude-sum     - Quick summary"
    echo "  monclaude-dash    - Full dashboard"
    echo ""
    echo "🎯 WORKSPACES:"
    echo "  htgo              - Launch HypeTrain workspace"
    echo "  twin1             - Launch Twin1 workspace"
    echo "  ht                - Attach to HypeTrain"
    echo "  tw1               - Attach to Twin1"
    echo ""
    echo "📋 JSON AUTOMATION:"
    echo "  claude-analyze    - Analyze project in background"
    echo "  claude-status     - Check all sessions"
    echo "  claude-batch      - Batch analyze directory"
    echo ""
    echo "🛠️ TMUX FIXES:"
    echo "  tmux-unblock-panes - Unblock stuck panes"
    echo "  tmux set -g mouse on - Enable mouse"
    echo ""
    echo "📚 Documentation:"
    echo "  ls $AUTOMATION_BASE/*.md"
}
