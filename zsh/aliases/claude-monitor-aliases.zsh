#!/bin/zsh
# 🎯 Claude Monitoring Aliases

# Source the monitor functions
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/claude-monitor.zsh

# 📊 Quick monitoring commands
alias monclaudem='claude_monitor_live'           # Live monitor all agents
alias monclaudes='claude_workspace_stats'        # Quick stats by workspace
alias monclauded='claude_dashboard'              # Full dashboard in tmux
alias monclaudew='claude_watch 70 10'           # Watch for high usage
alias monclaudek='claude_kill_heavy 80'         # Kill agents > 80% CPU
alias monclaudee='claude_export_stats'          # Export stats to file

# 🎨 Workspace-specific monitors
alias monclaudem-ht='ps aux | grep -E "claude" | grep -E "HypeTrain|hypetrain" | grep -v grep'
alias monclaudem-tw='ps aux | grep -E "claude" | grep -E "PKM|LLMs-|tg-mcp" | grep -v grep'

# 📈 Resource summaries
claude_summary() {
    echo "🤖 CLAUDE AGENTS SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local total_agents=$(ps aux | grep -E "claude-code|claudecd" | grep -v grep | wc -l)
    local total_cpu=$(ps aux | grep -E "claude-code|claudecd" | grep -v grep | awk '{sum+=$3} END {print sum}')
    local total_mem=$(ps aux | grep -E "claude-code|claudecd" | grep -v grep | awk '{sum+=$4} END {print sum}')
    
    echo "📊 Total Agents: $total_agents"
    echo "💻 Total CPU: ${total_cpu:-0}%"
    echo "🧠 Total Memory: ${total_mem:-0}%"
    echo ""
    
    # Per workspace
    echo "🚂 HypeTrain: $(ps aux | grep -E "claude" | grep -E "HypeTrain|hypetrain" | grep -v grep | wc -l) agents"
    echo "👯 Twin1: $(ps aux | grep -E "claude" | grep -E "PKM|LLMs-|tg-mcp" | grep -v grep | wc -l) agents"
}

alias monclaudesum='claude_summary'

# 🚨 Emergency kill all
claude_kill_all() {
    echo "⚠️ This will kill ALL Claude agents!"
    echo -n "Are you sure? (yes/no): "
    read answer
    if [[ "$answer" == "yes" ]]; then
        pkill -f "claude-code"
        pkill -f "claudecd"
        echo "✅ All Claude agents terminated"
    else
        echo "❌ Cancelled"
    fi
}

alias monclaudekall='claude_kill_all'

echo "📊 Claude monitoring loaded! Quick commands:"
echo "  • cm - Live monitor"
echo "  • cs - Quick stats"
echo "  • cd - Full dashboard"
echo "  • csum - Summary"
