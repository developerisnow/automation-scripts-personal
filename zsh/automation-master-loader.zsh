#!/bin/zsh
# 🚀 ZSH Automation Master Loader - CLEAN VERSION
# ================================================
# Loads all scripts from automations/zsh in correct order

# Base path
AUTOMATION_BASE="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh"

# 1️⃣ Environment variables
for file in $AUTOMATION_BASE/env/*.zsh; do
    [[ -f "$file" ]] && source "$file"
done

# 2️⃣ Functions (loaded first, used by aliases)
for file in $AUTOMATION_BASE/functions/*.zsh; do
    # Skip deprecated files
    if [[ -f "$file" ]] && [[ "$file" != *"deprecated"* ]]; then
        source "$file"
    fi
done

# 3️⃣ Config files
for file in $AUTOMATION_BASE/config/*.zsh; do
    [[ -f "$file" ]] && [[ "$file" != *.conf ]] && source "$file"
done

# 4️⃣ All aliases (except deprecated)
for file in $AUTOMATION_BASE/aliases/*.zsh; do
    if [[ -f "$file" ]] && [[ "$file" != *"deprecated"* ]]; then
        # Skip problematic files temporarily
        if [[ "$file" != *"hypetrain-quickref.zsh" ]] && [[ "$file" != *"tool-tmux.zsh" ]]; then
            source "$file"
        fi
    fi
done

# 5️⃣ Load specific loaders (skip deprecated)
[[ -f "$AUTOMATION_BASE/scripts/claude-monitor-loader.zsh" ]] && source "$AUTOMATION_BASE/scripts/claude-monitor-loader.zsh"
[[ -f "$AUTOMATION_BASE/scripts/claude-json-loader.zsh" ]] && source "$AUTOMATION_BASE/scripts/claude-json-loader.zsh"

# 6️⃣ Final touches
[[ -f "$AUTOMATION_BASE/zsh_last.zsh" ]] && source "$AUTOMATION_BASE/zsh_last.zsh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 CLEAN AUTOMATIONS LOADED!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Monitoring: monclaude, monclaude-stats"
echo "🎯 Workspaces: htgo [layout], twin1 [layout], workspace"
echo "📋 JSON Tools: claude-analyze, claude-status"
echo "🎨 Layouts: 1, 2h, 2v, 3"
echo ""
echo "💡 Type 'automation-help' or 'ws-help' for commands"
echo "💡 Type 'ws-examples' to see layout diagrams"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Enhanced help function
automation-help() {
    echo "🚀 AUTOMATION COMMANDS - CLEAN VERSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 MONITORING:"
    echo "  monclaude         - Live monitor all Claude agents"
    echo "  monclaude-stats   - Workspace statistics"
    echo "  monclaude-sum     - Quick summary"
    echo "  monclaude-dash    - Full dashboard"
    echo ""
    echo "🎯 CLEAN WORKSPACES (iTerm2 -> tmux -> neovim):"
    echo "  htgo [layout]     - Launch HypeTrain workspace"
    echo "  twin1 [layout]    - Launch Twin1 workspace"
    echo "  workspace <n> [layout] [dir] - Custom workspace"
    echo "  ht / tw           - Quick attach to existing sessions"
    echo ""
    echo "🎨 WORKSPACE LAYOUTS:"
    echo "  1                 - Single pane (neovim only)"
    echo "  2h                - 2 horizontal (neovim | terminal) [DEFAULT]"
    echo "  2v                - 2 vertical (neovim / terminal)"
    echo "  3                 - 3 panes (neovim | term / term)"
    echo ""
    echo "🔧 WORKSPACE MANAGEMENT:"
    echo "  wsls              - List active workspaces"
    echo "  wskill <n>     - Kill workspace"
    echo "  wsgo <n>       - Attach to workspace"
    echo "  ws-examples       - Show layout diagrams"
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
    echo "💡 EXAMPLES:"
    echo "  htgo 3            - Launch HypeTrain with 3-pane layout"
    echo "  workspace mycode 2v /path/to/project"
    echo "  twin1 1           - Launch Twin1 single pane"
    echo ""
    echo "📚 Documentation:"
    echo "  ls $AUTOMATION_BASE/*.md"
}
