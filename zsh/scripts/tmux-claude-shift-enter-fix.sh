#!/bin/bash
# 🔧 Fix Shift+Enter for Claude Code in TMUX

echo "🔧 Fixing Shift+Enter behavior in TMUX..."

# 1. Убираем любые привязки к Shift+Enter
tmux unbind -n S-Enter 2>/dev/null
tmux unbind S-Enter 2>/dev/null

# 2. Настраиваем правильную передачу клавиш
cat << 'EOF' > /tmp/tmux-claude-fix.conf
# 🎯 Claude Code Key Fixes
# ========================

# Отключаем перехват Shift+Enter
unbind -n S-Enter
unbind S-Enter

# Передаем Shift+Enter как есть
bind -n S-Enter send-keys Escape "[13;2u"

# Альтернативный вариант для новой строки в Claude
bind -n C-Enter send-keys C-j

# Фикс для других полезных комбинаций
bind -n S-Up send-keys Escape "[1;2A"
bind -n S-Down send-keys Escape "[1;2B"
bind -n S-Right send-keys Escape "[1;2C"
bind -n S-Left send-keys Escape "[1;2D"

# Убеждаемся что обычный Enter работает
unbind -n Enter
unbind Enter
EOF

# 3. Применяем конфиг
tmux source-file /tmp/tmux-claude-fix.conf

echo "✅ Shift+Enter should now work as newline!"
echo ""
echo "🎯 Альтернативные способы:"
echo "  • Ctrl+Enter    - тоже новая строка"
echo "  • Ctrl+J        - универсальная новая строка"
echo "  • Option+Enter  - может работать"
echo ""
echo "💡 Если не помогло, попробуй перезапустить Claude Code"
