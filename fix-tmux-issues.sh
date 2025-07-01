#!/bin/bash
# 🔧 Fix TMUX + iTerm2 Issues

echo "🔧 Fixing TMUX configuration issues..."

# 1. Backup current tmux config
if [ -f ~/.tmux.conf ]; then
    cp ~/.tmux.conf ~/.tmux.conf.backup-$(date +%Y%m%d-%H%M%S)
    echo "✅ Backed up current config"
fi

# 2. Use the fixed config
cp ~/.tmux.conf.fixed ~/.tmux.conf
echo "✅ Installed fixed tmux config"

# 3. Kill all tmux sessions to start fresh
tmux kill-server 2>/dev/null
echo "✅ Cleared all tmux sessions"

# 4. Source the shortcuts
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/env/shortcuts.zsh
echo "✅ Loaded directory shortcuts"

# 5. Source the fixed workspace functions
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/tmux-workspace-fixed.zsh
echo "✅ Loaded fixed workspace functions"

echo ""
echo "🎯 FIXES APPLIED:"
echo "1. ✅ Directory shortcuts: Try 'cd \$pkm' or just 'pkm'"
echo "2. ✅ Fixed workspace launchers: Use 'htfix' or 'tw1fix'"
echo "3. ✅ Keyboard shortcuts: Option+arrows should work now"
echo ""
echo "🔧 ITERM2 SETTINGS TO CHECK:"
echo "1. Preferences → Profiles → Keys → Left Option Key = 'Esc+'"
echo "2. Remove any custom key mappings that conflict"
echo ""
echo "💡 TEST COMMANDS:"
echo "   cd \$pkm          # Should go to PKM directory"
echo "   htfix            # Launch fixed HypeTrain workspace"
echo "   tns test         # Create simple tmux session"