#!/bin/bash
# 🎯 TMUX Copy/Paste Fix for macOS

echo "🔧 Fixing TMUX copy/paste for macOS..."

# Backup existing config
if [[ -f ~/.tmux.conf ]]; then
    cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d-%H%M%S)
fi

# Add macOS clipboard support
cat >> ~/.tmux.conf << 'EOF'

# 📋 macOS Clipboard Integration
# ================================

# Enable mouse support
set -g mouse on

# Copy mode with macOS clipboard
set-option -g set-clipboard on

# Copy with mouse selection
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

# Double click to select word
bind-key -T copy-mode DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X copy-pipe-no-clear "pbcopy"
bind-key -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X copy-pipe-no-clear "pbcopy"

# Triple click to select line
bind-key -T copy-mode TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X copy-pipe-no-clear "pbcopy"
bind-key -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X copy-pipe-no-clear "pbcopy"

# Right click to paste
bind-key -T root MouseDown3Pane run-shell "pbpaste | tmux load-buffer - && tmux paste-buffer"

# 🎯 EASY COPY: Hold Option + Mouse Select → Cmd+C
# This bypasses tmux and uses iTerm2 directly!
EOF

# Reload tmux config if running
if tmux info &> /dev/null; then
    tmux source-file ~/.tmux.conf
    echo "✅ TMUX config reloaded!"
fi

echo ""
echo "📋 HOW TO COPY IN TMUX:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 EASIEST: Hold Option + Mouse Select → Cmd+C"
echo "📱 TMUX Way: Just select with mouse → auto-copies!"
echo "📋 Paste: Right click or Cmd+V"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
