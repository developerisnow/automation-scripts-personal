#!/bin/zsh
# 🎯 Claude Multi-Agent Monitor for 2 workspaces

# 📊 Real-time resource monitor for all claude processes
claude_monitor_live() {
    clear
    while true; do
        echo -e "\033[H\033[2J" # Clear screen
        echo "🤖 CLAUDE AGENTS MONITOR - $(date '+%H:%M:%S')"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Header
        printf "%-8s %-20s %-6s %-6s %-8s %-30s\n" "PID" "WORKSPACE" "CPU%" "MEM%" "TIME" "DIRECTORY"
        echo "───────────────────────────────────────────────────────────────────────────────"
        
        # Get all claude processes with details
        ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | while read -r line; do
            pid=$(echo "$line" | awk '{print $2}')
            cpu=$(echo "$line" | awk '{print $3}')
            mem=$(echo "$line" | awk '{print $4}')
            time=$(echo "$line" | awk '{print $10}')
            
            # Get working directory (macOS way)
            cwd=$(lsof -p $pid 2>/dev/null | command grep cwd | awk '{print $NF}' | head -1 || echo "N/A")
            
            # Determine workspace based on directory
            workspace="Unknown"
            if [[ "$cwd" == *"HypeTrain"* ]]; then
                workspace="🚂 HypeTrain"
            elif [[ "$cwd" == *"PKM"* ]]; then
                workspace="🧠 Twin1-PKM"
            elif [[ "$cwd" == *"LLMs-claude-code-exporter"* ]]; then
                workspace="📤 Twin1-Export"
            elif [[ "$cwd" == *"github-project-management"* ]]; then
                workspace="🤖 Twin1-PM"
            elif [[ "$cwd" == *"tg-mcp"* ]]; then
                workspace="💬 Twin1-TG"
            fi
            
            # Color coding based on CPU usage
            if (( $(echo "$cpu > 80" | bc -l) )); then
                color="\033[91m" # Red
            elif (( $(echo "$cpu > 50" | bc -l) )); then
                color="\033[93m" # Yellow
            else
                color="\033[92m" # Green
            fi
            
            printf "${color}%-8s %-20s %-6s %-6s %-8s %-30s\033[0m\n" \
                "$pid" "$workspace" "$cpu" "$mem" "$time" "${cwd##*/}"
        done
        
        echo ""
        echo "📊 SYSTEM OVERVIEW"
        echo "───────────────────────────────────────────────────────────────────────────────"
        
        # Total resources
        total_cpu=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | awk '{sum+=$3} END {print sum}')
        total_mem=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | awk '{sum+=$4} END {print sum}')
        agent_count=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | wc -l)
        
        echo "🤖 Active Agents: $agent_count"
        echo "💻 Total CPU: ${total_cpu:-0}%"
        echo "🧠 Total Memory: ${total_mem:-0}%"
        
        # System resources (macOS)
        if command -v top &> /dev/null; then
            cpu_info=$(top -l 1 | command grep "CPU usage" | head -1)
            if [[ -n "$cpu_info" ]]; then
                echo "🖥️ System: $cpu_info"
            fi
        fi
        
        echo ""
        echo "🔄 Refreshing every 5 seconds... (Ctrl+C to exit)"
        sleep 5
    done
}

# 📈 Resource usage per workspace
claude_workspace_stats() {
    echo "📊 CLAUDE WORKSPACE STATISTICS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # HypeTrain stats
    echo "🚂 HYPETRAIN WORKSPACE:"
    local ht_pids=$(ps aux | command grep -E "claude" | command grep -E "HypeTrain|hypetrain" | command grep -v grep | awk '{print $2}')
    if [[ -n "$ht_pids" ]]; then
        local ht_cpu=$(ps aux | command grep -E "claude" | command grep -E "HypeTrain|hypetrain" | command grep -v grep | awk '{sum+=$3} END {print sum}')
        local ht_mem=$(ps aux | command grep -E "claude" | command grep -E "HypeTrain|hypetrain" | command grep -v grep | awk '{sum+=$4} END {print sum}')
        local ht_count=$(echo "$ht_pids" | wc -l | tr -d ' ')
        echo "  Agents: $ht_count | CPU: ${ht_cpu:-0}% | Memory: ${ht_mem:-0}%"
    else
        echo "  No active agents"
    fi
    
    echo ""
    echo "👯 TWIN1 WORKSPACE:"
    local tw_pids=$(ps aux | command grep -E "claude" | command grep -E "PKM|LLMs-|tg-mcp" | command grep -v grep | awk '{print $2}')
    if [[ -n "$tw_pids" ]]; then
        local tw_cpu=$(ps aux | command grep -E "claude" | command grep -E "PKM|LLMs-|tg-mcp" | command grep -v grep | awk '{sum+=$3} END {print sum}')
        local tw_mem=$(ps aux | command grep -E "claude" | command grep -E "PKM|LLMs-|tg-mcp" | command grep -v grep | awk '{sum+=$4} END {print sum}')
        local tw_count=$(echo "$tw_pids" | wc -l | tr -d ' ')
        echo "  Agents: $tw_count | CPU: ${tw_cpu:-0}% | Memory: ${tw_mem:-0}%"
    else
        echo "  No active agents"
    fi
}

# 📈 Resource summaries
claude_summary() {
    echo "🤖 CLAUDE AGENTS SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local total_agents=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | wc -l | tr -d ' ')
    local total_cpu=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | awk '{sum+=$3} END {print sum}')
    local total_mem=$(ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | awk '{sum+=$4} END {print sum}')
    
    echo "📊 Total Agents: $total_agents"
    echo "💻 Total CPU: ${total_cpu:-0}%"
    echo "🧠 Total Memory: ${total_mem:-0}%"
    echo ""
    
    # Per workspace
    local ht_count=$(ps aux | command grep -E "claude" | command grep -E "HypeTrain|hypetrain" | command grep -v grep | wc -l | tr -d ' ')
    local tw_count=$(ps aux | command grep -E "claude" | command grep -E "PKM|LLMs-|tg-mcp" | command grep -v grep | wc -l | tr -d ' ')
    
    echo "🚂 HypeTrain: ${ht_count:-0} agents"
    echo "👯 Twin1: ${tw_count:-0} agents"
}

# 🎯 Kill high-resource agents
claude_kill_heavy() {
    local threshold=${1:-80}
    echo "🔍 Looking for agents using more than ${threshold}% CPU..."
    
    ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | while read -r line; do
        pid=$(echo "$line" | awk '{print $2}')
        cpu=$(echo "$line" | awk '{print $3}')
        
        if (( $(echo "$cpu > $threshold" | bc -l) )); then
            echo "⚠️ PID $pid using ${cpu}% CPU"
            echo -n "Kill this process? (y/n): "
            read answer
            if [[ "$answer" == "y" ]]; then
                kill -9 $pid
                echo "✅ Killed PID $pid"
            fi
        fi
    done
}

# 📊 Export stats to file
claude_export_stats() {
    local filename="claude-stats-$(date +%Y%m%d-%H%M%S).log"
    {
        echo "CLAUDE AGENTS RESOURCE REPORT"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        claude_workspace_stats
        echo ""
        echo "DETAILED PROCESS LIST:"
        echo "=================================="
        ps aux | command grep -E "claude-code|claudecd" | command grep -v grep
    } > "$filename"
    echo "📄 Stats exported to: $filename"
}

# 🎨 Pretty dashboard in tmux
claude_dashboard() {
    tmux new-session -d -s claude-monitor 2>/dev/null || tmux kill-session -t claude-monitor
    tmux new-session -d -s claude-monitor
    
    # Window 1: Live monitor
    tmux rename-window -t claude-monitor:0 'Live Monitor'
    tmux send-keys -t claude-monitor:0 'claude_monitor_live' C-m
    
    # Window 2: System monitor
    tmux new-window -t claude-monitor:1 -n 'System'
    tmux send-keys -t claude-monitor:1 'btop || htop || top' C-m
    
    # Window 3: Logs
    tmux new-window -t claude-monitor:2 -n 'Logs'
    tmux split-window -h -t claude-monitor:2
    tmux send-keys -t claude-monitor:2.0 'tail -f ~/.claude/logs/*.log 2>/dev/null || echo "Waiting for logs..."' C-m
    tmux send-keys -t claude-monitor:2.1 'watch -n 5 claude_workspace_stats' C-m
    
    tmux attach-session -t claude-monitor
}

# 🚨 Alert when resources are high
claude_watch() {
    local cpu_threshold=${1:-70}
    local mem_threshold=${2:-10}
    
    echo "👁️ Watching for CPU > ${cpu_threshold}% or Memory > ${mem_threshold}%"
    
    while true; do
        ps aux | command grep -E "claude-code|claudecd" | command grep -v grep | while read -r line; do
            pid=$(echo "$line" | awk '{print $2}')
            cpu=$(echo "$line" | awk '{print $3}')
            mem=$(echo "$line" | awk '{print $4}')
            
            if (( $(echo "$cpu > $cpu_threshold" | bc -l) )); then
                echo "🚨 [$(date '+%H:%M:%S')] PID $pid: CPU ${cpu}% (threshold: ${cpu_threshold}%)"
                # macOS notification
                if command -v osascript &> /dev/null; then
                    osascript -e "display notification \"PID $pid using ${cpu}% CPU\" with title \"Claude Alert\""
                fi
            fi
            
            if (( $(echo "$mem > $mem_threshold" | bc -l) )); then
                echo "🚨 [$(date '+%H:%M:%S')] PID $pid: Memory ${mem}% (threshold: ${mem_threshold}%)"
            fi
        done
        sleep 10
    done
}

# 🚨 Emergency kill all
claude_kill_all() {
    echo "⚠️ This will kill ALL Claude agents!"
    echo -n "Are you sure? (yes/no): "
    read answer
    if [[ "$answer" == "yes" ]]; then
        pkill -f "claude-code" 2>/dev/null
        pkill -f "claudecd" 2>/dev/null
        echo "✅ All Claude agents terminated"
    else
        echo "❌ Cancelled"
    fi
}

# Auto-export functions
export -f claude_monitor_live
export -f claude_workspace_stats
export -f claude_summary
export -f claude_kill_heavy
export -f claude_export_stats
export -f claude_dashboard
export -f claude_watch
export -f claude_kill_all
