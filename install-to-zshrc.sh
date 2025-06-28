#!/bin/bash
# 🚀 Install Automations to ~/.zshrc

echo "🔧 Setting up automations in ~/.zshrc..."

# Backup current .zshrc
cp ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d-%H%M%S)
echo "✅ Backup created"

# Check if already installed
if grep -q "AUTOMATION_LOADER" ~/.zshrc; then
    echo "⚠️ Automations already in ~/.zshrc"
    echo "Remove old version first? (y/n)"
    read answer
    if [[ "$answer" == "y" ]]; then
        sed -i '' '/# AUTOMATION_LOADER START/,/# AUTOMATION_LOADER END/d' ~/.zshrc
        echo "✅ Old version removed"
    else
        echo "❌ Installation cancelled"
        exit 1
    fi
fi

# Add to .zshrc
cat >> ~/.zshrc << 'EOF'

# AUTOMATION_LOADER START
# 🚀 DevOps Automations - Added $(date)
AUTOMATION_LOADER="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/automation-master-loader.zsh"
if [[ -f "$AUTOMATION_LOADER" ]]; then
    source "$AUTOMATION_LOADER"
fi
# AUTOMATION_LOADER END
EOF

echo "✅ Added to ~/.zshrc"
echo ""
echo "🎯 To activate now:"
echo "  source ~/.zshrc"
echo ""
echo "📊 Available commands:"
echo "  • monclaude - Monitor Claude agents"
echo "  • htgo - Launch HypeTrain workspace"
echo "  • twin1 - Launch Twin1 workspace"
echo "  • automation-help - See all commands"
echo ""
echo "💡 If you see errors, run:"
echo "  tail -20 ~/.zshrc"
