#!/bin/bash
# 🐭 TMUX Mouse Scroll Fix

echo "🔧 Fixing TMUX mouse scroll..."

# 1. Убеждаемся что mouse включен
tmux set -g mouse on

# 2. Фиксим scroll bindings для macOS + iTerm2
tmux unbind -n MouseDrag1Pane 2>/dev/null
tmux unbind -n WheelUpPane 2>/dev/null
tmux unbind -n WheelDownPane 2>/dev/null

# 3. Настраиваем правильный скролл
cat << 'EOF' > /tmp/tmux-mouse-fix.conf
# 🐭 Mouse support for macOS + iTerm2
set -g mouse on

# Scroll with mouse wheel
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M

# Click to select pane
bind -n MouseDown1Pane select-pane -t= \; send-keys -M

# Double/Triple click to select word/line
bind -n DoubleClick1Pane select-pane -t= \; if -F -t= '#{||:#{pane_in_mode},#{mouse_any_flag}}' 'send -M' 'copy-mode -H ; send -X select-word'
bind -n TripleClick1Pane select-pane -t= \; if -F -t= '#{||:#{pane_in_mode},#{mouse_any_flag}}' 'send -M' 'copy-mode -H ; send -X select-line'
EOF

# 4. Применяем фикс
tmux source-file /tmp/tmux-mouse-fix.conf

echo "✅ Mouse scroll fixed!"
echo ""
echo "🎯 Теперь должно работать:"
echo "  • Клик мышкой - выбор панели"
echo "  • Scroll wheel - прокрутка"
echo "  • Option + Scroll - быстрая прокрутка"
echo ""
echo "⚠️ Если не работает, попробуй:"
echo "  1. Выйти из tmux: Ctrl+Space, d"
echo "  2. Зайти снова: tmux attach"
