#!/bin/bash
# 🚨 Emergency fix script for tmux workspace issues

echo "🔧 Fixing tmux workspace issues..."

# Fix 1: Update tmux aliases to avoid syntax error
sed -i '' 's/alias tpane>=/alias "tpane>="/' /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/aliases/tool-tmux.zsh
sed -i '' 's/alias tpane<=/alias "tpane<="/' /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/aliases/tool-tmux.zsh

# Fix 2: Fix grep function in hypetrain-quickref.zsh
# Already using 'command grep' so this should be OK

echo "✅ Fixes applied!"
echo ""
echo "🚀 Now run:"
echo "  source ~/.zshrc"
echo "  twin1"
