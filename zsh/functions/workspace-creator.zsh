#!/usr/bin/env zsh
# 🎯 Universal Workspace Creator
# Usage: workspace <name> <layout> <paths...>
# Examples:
#   workspace dev 2v ~/project1 ~/project2
#   workspace work 3h ~/code ~/docs ~/notes
#   workspace ai 4q ~/agent1 ~/agent2 ~/agent3 ~/agent4

workspace() {
    local name=$1
    local layout=$2
    shift 2
    local paths=("$@")
    
    # Parse layout (2v, 3h, 4q, etc)
    local num_panes=${layout:0:1}
    local arrangement=${layout:1:1}
    
    # Validate inputs
    if [[ ! $num_panes =~ ^[2-4]$ ]]; then
        echo "❌ Number of panes must be 2-4"
        return 1
    fi
    
    if [[ ! $arrangement =~ ^[vhq]$ ]]; then
        echo "❌ Arrangement must be v(ertical), h(orizontal), or q(uadrant)"
        return 1
    fi
    
    if [[ ${#paths[@]} -ne $num_panes ]]; then
        echo "❌ Expected $num_panes paths, got ${#paths[@]}"
        return 1
    fi
    
    # Kill existing session if any
    tmux kill-session -t $name 2>/dev/null
    
    # Create new session
    tmux new-session -d -s $name -c "${paths[1]}"
    
    # Create layout based on arrangement
    case "$arrangement" in
        v) # Vertical splits
            for ((i=2; i<=$num_panes; i++)); do
                tmux split-window -h -t $name:0 -c "${paths[$i]}"
                tmux select-layout -t $name:0 even-horizontal
            done
            ;;
        h) # Horizontal splits
            for ((i=2; i<=$num_panes; i++)); do
                tmux split-window -v -t $name:0 -c "${paths[$i]}"
                tmux select-layout -t $name:0 even-vertical
            done
            ;;
        q) # Quadrant (only for 4 panes)
            if [[ $num_panes -ne 4 ]]; then
                echo "❌ Quadrant layout requires exactly 4 panes"
                return 1
            fi
            tmux split-window -h -t $name:0 -c "${paths[2]}"
            tmux split-window -v -t $name:0.0 -c "${paths[3]}"
            tmux split-window -v -t $name:0.2 -c "${paths[4]}"
            ;;
    esac
    
    # Attach to session
    tmux attach-session -t $name
}

# Quick numbered workspaces
w2v() { workspace "w2v" "2v" "$@"; }
w2h() { workspace "w2h" "2h" "$@"; }
w3v() { workspace "w3v" "3v" "$@"; }
w3h() { workspace "w3h" "3h" "$@"; }
w4q() { workspace "w4q" "4q" "$@"; }

# Smart workspace with claudecd support
workspace-claude() {
    local name=$1
    local layout=$2
    shift 2
    local paths=("$@")
    
    # Create base workspace
    workspace "$name" "$layout" "${paths[@]}" &
    sleep 1
    
    # Send claudecd to each pane
    local num_panes=${layout:0:1}
    for ((i=0; i<$num_panes; i++)); do
        tmux send-keys -t $name:0.$i 'claudecd' C-m
    done
    
    tmux attach-session -t $name
}

# Aliases for common patterns
alias w2='workspace-claude work2 2v'
alias w3='workspace-claude work3 3h'
alias w4='workspace-claude work4 4q'

# Help function
workspace-help() {
    cat << 'EOF'
🎯 WORKSPACE CREATOR USAGE
========================

Basic Syntax:
  workspace <name> <layout> <path1> <path2> ...

Layout Options:
  2v - 2 panes vertical   |  |
  2h - 2 panes horizontal ---
  3v - 3 panes vertical   |||
  3h - 3 panes horizontal ===
  4q - 4 panes quadrant   ⊞

Examples:
  # 2 vertical panes
  workspace dev 2v ~/frontend ~/backend
  
  # 3 horizontal panes  
  workspace monitor 3h ~/logs ~/metrics ~/alerts
  
  # 4 quadrant layout
  workspace ai 4q ~/agent1 ~/agent2 ~/agent3 ~/agent4

Quick Shortcuts:
  w2v ~/path1 ~/path2           # 2 vertical
  w3h ~/path1 ~/path2 ~/path3  # 3 horizontal
  w4q ~/p1 ~/p2 ~/p3 ~/p4      # 4 quadrant

Claude Integration:
  w2 ~/path1 ~/path2    # 2 panes + claudecd
  w3 ~/p1 ~/p2 ~/p3     # 3 panes + claudecd
  w4 ~/p1 ~/p2 ~/p3 ~/p4 # 4 panes + claudecd
EOF
}