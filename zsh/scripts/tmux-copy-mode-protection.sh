#!/bin/bash
# 🛡️ TMUX Copy Mode Protection

# Добавь в ~/.tmux.conf чтобы не попадать случайно в copy mode
cat >> ~/.tmux.conf << 'EOF'

# 🛡️ Protection from accidental copy mode
# Отключаем автоматический вход в copy mode при скролле
set -g mouse on
setw -g mode-keys vi

# Меняем триггер copy mode на двойной prefix
unbind [
bind [ copy-mode

# Visual indicator when in copy mode
set -g mode-style "bg=yellow,fg=black,bold"

# Auto-exit copy mode after 30 seconds of inactivity
set -g @copy_mode_timeout 30
EOF

# Reload config
tmux source-file ~/.tmux.conf 2>/dev/null

echo "✅ Copy mode protection enabled!"
echo ""
echo "🎯 Now you need DOUBLE tap:"
echo "  Ctrl+Space, Ctrl+Space, [ = enter copy mode"
echo "  Single Ctrl+Space + [ = nothing happens"
