#!/bin/zsh
# 🎯 Generic TMUX Workspace Creator (DRY principle)
# Usage: create_tmux_workspace <name> <path1> <label1> <icon1> <path2> <label2> <icon2> ...

create_tmux_workspace() {
    local workspace_name=$1
    shift  # Remove workspace name from arguments
    
    # Validate arguments (must be divisible by 3: path, label, icon)
    if [ $(($# % 3)) -ne 0 ]; then
        echo "❌ Error: Arguments must be in groups of 3 (path, label, icon)"
        echo "Usage: create_tmux_workspace <name> <path1> <label1> <icon1> ..."
        return 1
    fi
    
    local num_panes=$(($# / 3))
    if [ $num_panes -ne 4 ]; then
        echo "❌ Error: Exactly 4 projects required (got $num_panes)"
        return 1
    fi
    
    echo "🚀 Launching $workspace_name workspace..."
    
    # Kill existing session if any
    tmux kill-session -t $workspace_name 2>/dev/null
    
    # Create new session
    tmux new-session -d -s $workspace_name
    
    # Create 4 panes layout
    tmux split-window -h -t $workspace_name:0
    tmux split-window -v -t $workspace_name:0.0
    tmux split-window -v -t $workspace_name:0.2
    
    echo "📂 Setting up directories..."
    
    # Setup each pane
    local pane_index=0
    while [ $# -gt 0 ]; do
        local path=$1
        local label=$2
        local icon=$3
        shift 3
        
        tmux send-keys -t $workspace_name:0.$pane_index "cd $path" C-m
        tmux send-keys -t $workspace_name:0.$pane_index "echo '$icon $label ready'" C-m
        tmux send-keys -t $workspace_name:0.$pane_index 'claudecd' C-m
        
        ((pane_index++))
    done
    
    echo "✅ Workspace created! Attaching..."
    sleep 1
    
    # Attach to session
    tmux attach-session -t $workspace_name
}

# 🚂 HypeTrain workspace (refactored to use generic function)
htgo() {
    create_tmux_workspace "hypetrain" \
        "/Users/user/__Repositories/HypeTrain" "Monorepo" "🚂" \
        "/Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden" "Garden" "🌱" \
        "/Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend" "Backend" "⚙️" \
        "/Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs" "Docs" "📚"
}

# 👯 Twin1 workspace
twin1() {
    create_tmux_workspace "twin1" \
        "/Users/user/____Sandruk/___PKM" "PKM" "🧠" \
        "/Users/user/__Repositories/LLMs-claude-code-exporter" "Exporter" "📤" \
        "/Users/user/__Repositories/LLMs-github-project-management-agents" "PM Agents" "🤖" \
        "/Users/user/__Repositories/tg-mcp-assistant-telegram-crm__developerisnow" "TG CRM" "💬"
}
