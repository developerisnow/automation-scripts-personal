#!/bin/bash
# 🚨 TMUX Emergency Mouse Fix

echo "🚑 Emergency TMUX mouse fix..."

# 1. Убиваем все tmux сервера (осторожно!)
echo "⚠️ This will kill ALL tmux sessions!"
echo -n "Continue? (y/n): "
read answer

if [[ "$answer" != "y" ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# 2. Убиваем tmux
tmux kill-server 2>/dev/null

# 3. Создаем новый конфиг
cat > ~/.tmux.conf << 'EOF'
# 🎮 TMUX Config for macOS + iTerm2
# ==================================

# Change prefix to Ctrl+Space
set -g prefix C-Space
unbind C-b
bind C-Space send-prefix

# 🐭 MOUSE SUPPORT - FULL
# =====================
set -g mouse on

# Scroll behavior
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" \
    "send-keys -M" \
    "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"

bind -n WheelDownPane select-pane -t= \; send-keys -M

# Selection and copy
bind -n MouseDrag1Pane select-pane -t= \; send-keys -M
bind -n MouseDown1Pane select-pane -t= \; send-keys -M

# macOS clipboard integration
bind -n MouseDragEnd1Pane send-keys -M \; run-shell -b "tmux save-buffer - | pbcopy"

# 🎨 VISUAL
# ========
set -g default-terminal "screen-256color"
set -g history-limit 50000

# 🚀 NAVIGATION
# ============
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Window switching
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4

# 📋 COPY MODE
# ===========
setw -g mode-keys vi
EOF

echo "✅ New config created!"

# 4. Запускаем тестовую сессию
echo ""
echo "🚀 Starting test session..."
tmux new-session -d -s test
tmux split-window -h -t test:0
tmux split-window -v -t test:0.0
tmux split-window -v -t test:0.2

# 5. Тестовые команды для скролла
tmux send-keys -t test:0.0 'seq 1 100' C-m
tmux send-keys -t test:0.1 'seq 100 200' C-m
tmux send-keys -t test:0.2 'seq 200 300' C-m
tmux send-keys -t test:0.3 'seq 300 400' C-m

echo ""
echo "✅ Test session created!"
echo ""
echo "📋 NOW TEST:"
echo "  1. tmux attach -t test"
echo "  2. Click any pane with mouse"
echo "  3. Try scrolling with mouse wheel"
echo "  4. Should see numbers scrolling!"
echo ""
echo "🎯 Shortcuts:"
echo "  • Ctrl+Space, d = detach"
echo "  • Mouse click = select pane"
echo "  • Mouse wheel = scroll"
echo "  • Option+Wheel = fast scroll"
