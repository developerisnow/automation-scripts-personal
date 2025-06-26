#!/bin/zsh
# 🚂 HypeTrain Workspace Launcher

echo "🚂 Launching HypeTrain workspace..."

# Kill existing session if any
tmux kill-session -t hypetrain 2>/dev/null

# Create new session with 4 panes
tmux new-session -d -s hypetrain

# Create 4 panes
tmux split-window -h -t hypetrain:0
tmux split-window -v -t hypetrain:0.0  
tmux split-window -v -t hypetrain:0.2

# Setup each pane
echo "📂 Setting up directories..."

# Pane 0: Monorepo
tmux send-keys -t hypetrain:0.0 'cd /Users/user/__Repositories/HypeTrain' C-m
tmux send-keys -t hypetrain:0.0 'echo "🚂 Monorepo ready"' C-m
tmux send-keys -t hypetrain:0.0 'claudecd' C-m

# Pane 1: Garden
tmux send-keys -t hypetrain:0.1 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden' C-m
tmux send-keys -t hypetrain:0.1 'echo "🌱 Garden ready"' C-m
tmux send-keys -t hypetrain:0.1 'claudecd' C-m

# Pane 2: Backend
tmux send-keys -t hypetrain:0.2 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend' C-m
tmux send-keys -t hypetrain:0.2 'echo "⚙️ Backend ready"' C-m
tmux send-keys -t hypetrain:0.2 'claudecd' C-m

# Pane 3: Docs
tmux send-keys -t hypetrain:0.3 'cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs' C-m
tmux send-keys -t hypetrain:0.3 'echo "📚 Docs ready"' C-m
tmux send-keys -t hypetrain:0.3 'claudecd' C-m

echo "✅ Workspace created! Attaching..."
sleep 1

# Attach to session
tmux attach-session -t hypetrain
