#!/usr/bin/env zsh
# 🚀 TMUX Best Practices for AI Coding
# =====================================

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 TMUX QUICK START
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Start tmux with proper colors for iTerm2
alias tm='tmux -2'
alias tmux='tmux -2'

# Quick session management
alias tls='tmux ls'
alias ta='tmux attach -t'
alias tns='tmux new -s'
alias tks='tmux kill-session -t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚂 HYPETRAIN PROJECT WORKSPACE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Launch HypeTrain development workspace (tmux version)
hypetrain1() {
    tmux new-session -d -s hypetrain
    
    # Window 1: Multi-repo development
    tmux rename-window -t hypetrain:0 'HypeTrain-Dev'
    
    # Create 4 panes for 4 repos
    tmux split-window -h -t hypetrain:0
    tmux split-window -v -t hypetrain:0.0
    tmux split-window -v -t hypetrain:0.2
    
    # Navigate to repos and try to continue sessions
    # Pane 1: Monorepo
    tmux send-keys -t hypetrain:0.0 'cd /Users/user/__Repositories/HypeTrain' C-m
    tmux send-keys -t hypetrain:0.0 'echo "🚂 Monorepo | Try: claudecd or claude-code"' C-m
    
    # Pane 2: DevOps
    tmux send-keys -t hypetrain:0.1 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden' C-m
    tmux send-keys -t hypetrain:0.1 'echo "🌱 DevOps Garden | Try: claudecd or claude-code"' C-m
    
    # Pane 3: Backend
    tmux send-keys -t hypetrain:0.2 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend' C-m
    tmux send-keys -t hypetrain:0.2 'echo "⚙️ Backend | Try: claudecd or claude-code"' C-m
    
    # Pane 4: Docs (frontend ready for future)
    tmux send-keys -t hypetrain:0.3 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs' C-m
    tmux send-keys -t hypetrain:0.3 'echo "📚 Docs | Try: claudecd or claude-code"' C-m
    # Future: hypetrain-frontend
    
    # Window 2: Monitoring & Logs
    tmux new-window -t hypetrain:1 -n 'Monitor'
    tmux split-window -h -t hypetrain:1
    tmux send-keys -t hypetrain:1.0 'btop' C-m
    tmux send-keys -t hypetrain:1.1 'tail -f ~/.claude/logs/*.log 2>/dev/null || echo "Claude logs will appear here"' C-m
    
    # Attach to session
    tmux attach-session -t hypetrain
}

# Quick restore HypeTrain session
ht1() {
    if tmux has-session -t hypetrain 2>/dev/null; then
        tmux attach-session -t hypetrain
    else
        hypetrain1
    fi
}

# HypeTrain with automatic session continues
hypetrain-auto() {
    tmux new-session -d -s hypetrain-auto
    
    # Create 4 panes
    tmux split-window -h -t hypetrain-auto:0
    tmux split-window -v -t hypetrain-auto:0.0
    tmux split-window -v -t hypetrain-auto:0.2
    
    # Auto-start with continue in each repo
    tmux send-keys -t hypetrain-auto:0.0 'cd /Users/user/__Repositories/HypeTrain && claudecd' C-m
    tmux send-keys -t hypetrain-auto:0.1 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden && claudecd' C-m
    tmux send-keys -t hypetrain-auto:0.2 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend && claudecd' C-m
    tmux send-keys -t hypetrain-auto:0.3 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs && claudecd' C-m
    
    tmux attach-session -t hypetrain-auto
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🤖 AI CODING SESSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Launch AI coding workspace with 4 panes
ai-workspace() {
    tmux new-session -d -s ai-workspace
    
    # Window 1: Main coding
    tmux rename-window -t ai-workspace:0 'AI-Agents'
    tmux send-keys -t ai-workspace:0 'echo "🤖 AI Workspace Ready"' C-m
    
    # Split into 4 panes
    tmux split-window -h -t ai-workspace:0
    tmux split-window -v -t ai-workspace:0.0
    tmux split-window -v -t ai-workspace:0.2
    
    # Launch different AI agents
    tmux send-keys -t ai-workspace:0.0 'claude-code' C-m
    tmux send-keys -t ai-workspace:0.1 'echo "Pane 2: Ready for second agent"' C-m
    tmux send-keys -t ai-workspace:0.2 'echo "Pane 3: Ready for logs"' C-m
    tmux send-keys -t ai-workspace:0.3 'htop' C-m
    
    # Window 2: Monitoring
    tmux new-window -t ai-workspace:1 -n 'Monitor'
    tmux send-keys -t ai-workspace:1 'btop' C-m
    
    # Attach to session
    tmux attach-session -t ai-workspace
}

# Quick AI session for single agent
ai-quick() {
    tmux new-session -d -s ai-quick
    tmux send-keys -t ai-quick:0 'claude-code' C-m
    tmux split-window -h -t ai-quick:0
    tmux send-keys -t ai-quick:0.1 'tail -f ~/.claude/logs/latest.log 2>/dev/null || echo "No logs yet"' C-m
    tmux attach-session -t ai-quick
}

# Multi-agent parallel session (for complex tasks)
ai-parallel() {
    local task="${1:-default-task}"
    tmux new-session -d -s ai-parallel
    
    # Create 4 panes for 4 agents
    tmux split-window -h -t ai-parallel:0
    tmux split-window -v -t ai-parallel:0.0
    tmux split-window -v -t ai-parallel:0.2
    
    # Run same task in all panes with different approaches
    tmux send-keys -t ai-parallel:0.0 "claude-code # Agent 1" C-m
    tmux send-keys -t ai-parallel:0.1 "claude-code # Agent 2" C-m
    tmux send-keys -t ai-parallel:0.2 "claude-code # Agent 3" C-m
    tmux send-keys -t ai-parallel:0.3 "claude-code # Agent 4" C-m
    
    tmux attach-session -t ai-parallel
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔄 SYNCHRONIZE PANES (KILLER FEATURE!)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Toggle synchronize panes
alias tsync='tmux setw synchronize-panes'

# Launch synchronized AI agents
ai-sync() {
    tmux new-session -d -s ai-sync
    tmux split-window -h -t ai-sync:0
    tmux split-window -v -t ai-sync:0.0
    tmux split-window -v -t ai-sync:0.2
    
    # Enable sync
    tmux setw -t ai-sync:0 synchronize-panes on
    
    # Now whatever you type goes to ALL panes!
    tmux attach-session -t ai-sync
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 COPY/PASTE ENHANCEMENTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copy tmux buffer to macOS clipboard
alias tcopy='tmux save-buffer - | pbcopy'

# Search through all panes
tsearch() {
    tmux capture-pane -J -p -S -1000 | command grep -i "$1"
}

# Save all panes output to file
tsave() {
    local filename="${1:-tmux-capture-$(date +%Y%m%d-%H%M%S).log}"
    for pane in $(tmux list-panes -F '#P'); do
        echo "=== Pane $pane ===" >> "$filename"
        tmux capture-pane -p -t $pane -S -1000 >> "$filename"
        echo "" >> "$filename"
    done
    echo "💾 Saved to: $filename"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 LAYOUTS & PRESETS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Common layouts
alias tlayout-even='tmux select-layout even-horizontal'
alias tlayout-main='tmux select-layout main-vertical'
alias tlayout-tiled='tmux select-layout tiled'

# Save/restore layouts
tsave-layout() {
    local name="${1:-default}"
    tmux display-message -p "#{window_layout}" > ~/.tmux-layouts/$name
    echo "💾 Layout saved as: $name"
}

trestore-layout() {
    local name="${1:-default}"
    if [[ -f ~/.tmux-layouts/$name ]]; then
        tmux select-layout "$(cat ~/.tmux-layouts/$name)"
        echo "✅ Layout restored: $name"
    else
        echo "❌ Layout not found: $name"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 PRODUCTIVITY SHORTCUTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Quick pane switching
alias tpane='tmux display-panes'
alias tlast='tmux last-pane'

# Resize panes quickly
alias tpane+='tmux resize-pane -U 10'
alias tpane-='tmux resize-pane -D 10'
alias 'tpane>='='tmux resize-pane -R 10'
alias 'tpane<='='tmux resize-pane -L 10'

# Monitor activity
tmonitor() {
    tmux set-window-option monitor-activity on
    tmux set-option -g visual-activity on
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 TMUX CONFIG GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

tmux-init() {
    cat > ~/.tmux.conf << 'EOF'
# 🚀 TMUX Config for AI Coding on M3 Mac
# ======================================

# Better prefix key (Ctrl+A instead of Ctrl+B)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse
set -g mouse on

# Better colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Huge scrollback for AI outputs
set-option -g history-limit 50000

# Fast key sequences
set -s escape-time 0

# Window numbering from 1
set -g base-index 1
setw -g pane-base-index 1

# Easy splits
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Easy reload
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Copy mode improvements
setw -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# Status bar
set -g status-position bottom
set -g status-style bg=colour234,fg=colour137
set -g status-left '#[fg=colour233,bg=colour245,bold] #S '
set -g status-right '#[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 50

# Pane borders
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour51

# Messages
set -g message-style fg=colour232,bg=colour166

# Window status
setw -g window-status-current-style fg=colour81,bg=colour238,bold
setw -g window-status-current-format ' #I:#W#F '
EOF
    echo "✅ TMUX config created at ~/.tmux.conf"
    echo "🔄 Run 'tmux source ~/.tmux.conf' to reload"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 CHEATSHEET
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

tmux-help() {
    cat << 'EOF'
🚀 TMUX CHEATSHEET FOR AI CODING
================================

📌 BASICS (prefix = Ctrl+A)
  Ctrl+A ?     Show all keybindings
  Ctrl+A d     Detach from session
  Ctrl+A [     Enter copy mode
  Ctrl+A ]     Paste buffer

🪟 WINDOWS
  Ctrl+A c     New window
  Ctrl+A n     Next window
  Ctrl+A p     Previous window
  Ctrl+A 0-9   Go to window 0-9
  Ctrl+A ,     Rename window

📐 PANES
  Ctrl+A |     Split vertically
  Ctrl+A -     Split horizontally
  Ctrl+A h/j/k/l  Navigate panes (vim-style)
  Ctrl+A z     Zoom pane
  Ctrl+A !     Break pane into window
  
🔄 SYNC PANES (for parallel AI agents)
  :setw synchronize-panes on   Type in ALL panes
  :setw synchronize-panes off  Back to normal

📋 COPY MODE (vim-style)
  Ctrl+A [     Enter copy mode
  Space        Start selection
  v            Visual selection
  y            Copy to clipboard
  q            Exit copy mode

💡 AI WORKFLOW COMMANDS
  ai-workspace    4-pane AI setup
  ai-quick       Quick claude session
  ai-parallel    Multi-agent setup
  ai-sync        Synchronized agents
  tsearch <text> Search all panes
  tsave          Save all output

🎯 PRO TIPS
  - Use 'tsync' to toggle pane sync
  - 'tcopy' copies tmux buffer to macOS clipboard
  - Mouse works! Click, scroll, select
  - Huge scrollback (50k lines) for AI outputs
EOF
}

# Auto-create layouts directory
[[ ! -d ~/.tmux-layouts ]] && mkdir -p ~/.tmux-layouts

# Show help on first load
echo "🚀 TMUX aliases loaded! Run 'tmux-help' for cheatsheet"
