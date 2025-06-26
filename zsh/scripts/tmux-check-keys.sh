#!/bin/bash
# 🔍 TMUX Key Binding Checker

echo "🔍 Checking TMUX key bindings..."

# Проверяем что привязано к Enter и Shift+Enter
echo ""
echo "📋 Current Enter bindings:"
tmux list-keys | grep -i enter || echo "No special Enter bindings"

echo ""
echo "🎯 Testing key codes..."
echo "Press Ctrl+C to exit"
echo ""

# Запускаем тест для проверки кодов клавиш
cat << 'EOF' > /tmp/test-keys.sh
#!/bin/bash
echo "Press keys to see their codes (Ctrl+C to exit):"
while IFS= read -rsn1 key; do
    printf 'Pressed: '
    if [[ -z "$key" ]]; then
        echo "ENTER"
    else
        echo "$key" | od -An -tx1
    fi
done
EOF

chmod +x /tmp/test-keys.sh

echo "🎹 Key test (запусти в tmux и вне tmux для сравнения):"
echo "  /tmp/test-keys.sh"
