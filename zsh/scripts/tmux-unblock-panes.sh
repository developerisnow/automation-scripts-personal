#!/bin/bash
# 🚨 TMUX Unblock All Panes

echo "🔓 Unblocking all TMUX panes..."

# Get session name
SESSION=${1:-hypetrain}

# Exit copy mode in all panes
echo "📋 Exiting copy mode..."
tmux list-panes -t $SESSION -F '#{pane_index}' | while read pane; do
    tmux send-keys -t $SESSION:0.$pane Escape 2>/dev/null
    tmux send-keys -t $SESSION:0.$pane q 2>/dev/null
done

# Make sure synchronize is off
echo "🔄 Disabling synchronize..."
tmux setw -t $SESSION synchronize-panes off

# Make sure zoom is off
echo "🔍 Disabling zoom..."
tmux resize-pane -t $SESSION -Z 2>/dev/null || true

# Reset mouse
echo "🐭 Resetting mouse..."
tmux set -t $SESSION mouse on

# Clear any selection
echo "🎯 Clearing selections..."
tmux send-keys -t $SESSION -X cancel 2>/dev/null || true

echo ""
echo "✅ All panes should be unblocked now!"
echo ""
echo "🎯 Test it:"
echo "  1. Click on each pane with mouse"
echo "  2. All should respond now"
echo ""
echo "💡 Tips to avoid this:"
echo "  • Use 'q' to exit copy mode"
echo "  • Don't use Ctrl+Space + [ unless needed"
echo "  • Click pane first, then type"
