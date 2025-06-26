#!/bin/zsh
# 🔄 Reload Claude Monitoring v2

echo "🔄 Reloading Claude monitoring system..."

# Reload functions
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/claude-monitor.zsh

# Reload aliases
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/aliases/claude-monitor-aliases.zsh

echo "✅ Monitoring reloaded!"
echo ""

# Quick status check
echo "📊 Current Status:"
claude_summary

echo ""
echo "🎯 Quick Commands:"
echo "  monclaude       - Live monitor (fixed!)"
echo "  monclaude-q     - Quick check"
echo "  monclaude-sum   - Summary"
echo ""
echo "💡 Your htgo has only 1/4 agents running"
echo "   Check other panels with: tmux attach -t hypetrain"
