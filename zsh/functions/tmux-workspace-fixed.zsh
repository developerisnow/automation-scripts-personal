#!/bin/zsh
# 🎯 Fixed TMUX Workspace Creator
# Solves: keyboard shortcuts and pane switching issues

create_tmux_workspace_simple() {
    local workspace_name=$1
    shift
    
    echo "🚀 Launching $workspace_name workspace..."
    
    # Kill existing session if any
    tmux kill-session -t $workspace_name 2>/dev/null
    
    # Create new session WITHOUT detaching
    tmux new-session -s $workspace_name -n "Dev" \; \
        split-window -h \; \
        split-window -v \; \
        select-pane -t 0 \; \
        split-window -v \; \
        select-layout tiled
    
    echo "✅ Workspace created!"
}

# Fixed HypeTrain launcher
htgo_fixed() {
    # Kill existing session
    tmux kill-session -t hypetrain 2>/dev/null
    
    # Create session and layout first
    tmux new-session -d -s hypetrain -n "HypeTrain"
    
    # Create the 4-pane layout
    tmux split-window -h -t hypetrain:0
    tmux split-window -v -t hypetrain:0.0
    tmux split-window -v -t hypetrain:0.2
    
    # Send commands to each pane with delays
    tmux send-keys -t hypetrain:0.0 "cd /Users/user/__Repositories/HypeTrain && echo '🚂 Monorepo ready'" C-m
    tmux send-keys -t hypetrain:0.1 "cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden && echo '🌱 Garden ready'" C-m
    tmux send-keys -t hypetrain:0.2 "cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend && echo '⚙️ Backend ready'" C-m
    tmux send-keys -t hypetrain:0.3 "cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs && echo '📚 Docs ready'" C-m
    
    # DON'T send claudecd automatically - let user do it
    
    # Attach to session
    tmux attach-session -t hypetrain
}

# Fixed Twin1 launcher
twin1_fixed() {
    # Kill existing session
    tmux kill-session -t twin1 2>/dev/null
    
    # Create session and layout
    tmux new-session -d -s twin1 -n "Twin Projects"
    
    # Create the 4-pane layout
    tmux split-window -h -t twin1:0
    tmux split-window -v -t twin1:0.0
    tmux split-window -v -t twin1:0.2
    
    # Send commands to each pane
    tmux send-keys -t twin1:0.0 "cd /Users/user/____Sandruk/___PKM && echo '🧠 PKM ready'" C-m
    tmux send-keys -t twin1:0.1 "cd /Users/user/__Repositories/LLMs-claude-code-exporter && echo '📤 Exporter ready'" C-m
    tmux send-keys -t twin1:0.2 "cd /Users/user/__Repositories/LLMs-github-project-management-agents && echo '🤖 PM Agents ready'" C-m
    tmux send-keys -t twin1:0.3 "cd /Users/user/__Repositories/tg-mcp-assistant-telegram-crm__developerisnow && echo '💬 TG CRM ready'" C-m
    
    # Attach to session
    tmux attach-session -t twin1
}

# Super simple workspace creator
simple_workspace() {
    local name=${1:-workspace}
    local num_panes=${2:-4}
    
    tmux new-session -d -s $name
    
    case $num_panes in
        2)
            tmux split-window -h -t $name:0
            ;;
        3)
            tmux split-window -h -t $name:0
            tmux split-window -v -t $name:0.0
            ;;
        4)
            tmux split-window -h -t $name:0
            tmux split-window -v -t $name:0.0
            tmux split-window -v -t $name:0.2
            ;;
    esac
    
    tmux attach-session -t $name
}

# Aliases for the fixed versions
alias htfix='htgo_fixed'
alias tw1fix='twin1_fixed'
alias ws='simple_workspace'

echo "🔧 Fixed workspace functions loaded!"
echo "💡 Try: htfix, tw1fix, or ws <name> <num_panes>"