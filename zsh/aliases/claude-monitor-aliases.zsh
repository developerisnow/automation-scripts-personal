#!/bin/zsh
# 🎯 Claude Monitoring Aliases (Long names as requested)

# Source the monitor functions
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/claude-monitor.zsh

# 📊 Monitoring commands with long names
alias monclaude='claude_monitor_live'              # Live monitor all agents
alias monclaude-stats='claude_workspace_stats'     # Quick stats by workspace
alias monclaude-dash='claude_dashboard'            # Full dashboard in tmux
alias monclaude-watch='claude_watch 70 10'         # Watch for high usage
alias monclaude-kill='claude_kill_heavy 80'        # Kill agents > 80% CPU
alias monclaude-export='claude_export_stats'       # Export stats to file
alias monclaude-sum='claude_summary'               # Summary
alias monclaude-killall='claude_kill_all'          # Kill all agents

# 🎨 Workspace-specific monitors
alias monclaude-ht='ps aux | command grep -E "claude" | command grep -E "HypeTrain|hypetrain" | command grep -v grep'
alias monclaude-tw='ps aux | command grep -E "claude" | command grep -E "PKM|LLMs-|tg-mcp" | command grep -v grep'

# 📈 Quick system check
monclaude-quick() {
    echo "🤖 CLAUDE QUICK CHECK - $(date '+%H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local count=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | wc -l)
    if [[ $count -eq 0 ]]; then
        echo "❌ No Claude agents running"
        return
    fi
    
    echo "✅ Active agents: $count"
    echo ""
    ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | \
        awk '{printf "PID: %-8s CPU: %-6s MEM: %-6s CMD: %s\n", $2, $3"%", $4"%", $11}'
}

alias monclaude-q='monclaude-quick'

echo "📊 Claude monitoring loaded! Commands:"
echo "  • monclaude         - Live monitor"
echo "  • monclaude-stats   - Workspace stats"
echo "  • monclaude-dash    - Full dashboard"
echo "  • monclaude-sum     - Quick summary"
echo "  • monclaude-q       - Quick check"
