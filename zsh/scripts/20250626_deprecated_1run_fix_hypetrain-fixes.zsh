#!/bin/zsh
# 🛠️ Quick fixes for HypeTrain

# Fix hs conflict - use different name
hts() {
    echo "🚂 HypeTrain Sessions:"
    echo "━━━━━━━━━━━━━━━━━━━━"
    tmux list-sessions 2>/dev/null | grep hypetrain || echo "No tmux sessions"
    echo ""
    echo "🤖 Claude Processes:"
    ps aux | grep -E "claude" | grep -v grep | wc -l | xargs echo "Active agents:"
}

# Fix hsave
htsave() {
    local timestamp=$(date +%Y%m%d-%H%M)
    local filename="hypetrain-$timestamp.log"
    
    for pane in 0.0 0.1 0.2 0.3; do
        echo "=== Pane $pane ===" >> "$filename"
        tmux capture-pane -t hypetrain:0.$pane -p >> "$filename" 2>/dev/null
    done
    
    echo "💾 Saved to: $filename"
}

# Simple launcher
htgo() {
    /Users/user/hypetrain-workspace.sh
}

# Status check
htcheck() {
    if tmux has-session -t hypetrain 2>/dev/null; then
        echo "✅ HypeTrain session is running"
        echo "Panes:"
        tmux list-panes -t hypetrain:0 -F "  #{pane_index}: #{pane_current_path}"
    else
        echo "❌ No HypeTrain session found"
        echo "Run: htgo"
    fi
}

echo "🚂 HypeTrain fixes loaded!"
echo "Commands:"
echo "  htgo    - Launch workspace with claudecd"
echo "  hts     - Check status"
echo "  htsave  - Save all panes"
echo "  htcheck - Check session details"
