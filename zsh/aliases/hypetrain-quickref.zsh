#!/usr/bin/env zsh
# 🚂 HYPETRAIN QUICK REFERENCE
# ============================

# Add this to your .zshrc or source directly
# source ~/hypetrain-quickref.zsh

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 DAILY WORKFLOW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Morning routine
morning() {
    echo "☕ Starting HypeTrain development..."
    echo "Choose your setup:"
    echo "  1) hypetrain1    - TMUX workspace (recommended)"
    echo "  2) hti           - iTerm2 only"
    echo "  3) ht1           - Attach to existing"
    echo ""
    echo "Then in each pane: claudecd (continue) or claude-code (new)"
}

# Quick status check
hs() {
    echo "🚂 HypeTrain Sessions:"
    echo "━━━━━━━━━━━━━━━━━━━━"
    tmux list-sessions 2>/dev/null | command grep hypetrain || echo "No tmux sessions"
    echo ""
    echo "🤖 Claude Processes:"
    local count=$(ps aux | command grep -E "claude" | command grep -v grep | wc -l)
    echo "Active agents: $count"
    ps aux | command grep -E "claude" | command grep -v grep | head -5
}

# Save all work
hsave() {
    local timestamp=$(date +%Y%m%d-%H%M)
    local filename="hypetrain-$timestamp.log"
    tsave "$filename"
    echo "💾 Saved to: $filename"
    echo "📍 Location: $(pwd)/$filename"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 QUICK ALIASES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Project navigation
alias ht-mono='cd /Users/user/__Repositories/HypeTrain'
alias ht-garden='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden'
alias ht-backend='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend'
alias ht-docs='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs'

# Quick commands in any directory
alias ht-status='hs'
alias ht-save='hsave'
alias ht-monitor='watch -n 1 claude-monitor'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 CHEATSHEET
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

hypetrain-help() {
    cat << 'EOF'
🚂 HYPETRAIN DAILY COMMANDS
===========================

🚀 START WORK
  hypetrain1     Launch TMUX workspace  
  ht1            Quick attach/create
  hti            iTerm2 version (no tmux)
  
📂 QUICK NAVIGATION  
  ht-mono        → Jump to monorepo
  ht-garden      → Jump to garden
  ht-backend     → Jump to backend
  ht-docs        → Jump to docs

🤖 CLAUDE COMMANDS (in each pane)
  claudecd       Continue previous session
  claude-code    Start new session
  cld            Quick alias
  
🔍 MONITORING
  hs             HypeTrain status
  claude-monitor Check all agents
  Ctrl+A 1       Switch to monitor window

💾 SAVE & SEARCH  
  hsave          Save all panes
  tsearch "err"  Search in all panes
  tsave custom   Save with custom name

⌨️ TMUX KEYS (Ctrl+A = prefix)
  Ctrl+A h/j/k/l Navigate panes
  Ctrl+A z       Zoom pane
  Ctrl+A d       Detach session
  Ctrl+A [       Copy mode
  Ctrl+A 0/1     Switch windows

🆘 EMERGENCY
  pkill -f claude     Kill all agents
  tmux kill-session   Kill tmux
  ht1                 Restart fresh
EOF
}

# Print reminder on load
echo "🚂 HypeTrain shortcuts loaded! Commands:"
echo "  • hypetrain1 - Start TMUX workspace"
echo "  • ht1 - Quick attach"  
echo "  • hypetrain-help - Show all commands"
