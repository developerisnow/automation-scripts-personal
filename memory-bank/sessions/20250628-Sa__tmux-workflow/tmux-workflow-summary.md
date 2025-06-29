# TMUX Workflow Summary

## 🎯 Key Concepts & Commands

### Core Commands
| Command | Description | Usage |
|---------|------------|-------|
| `tmux new -s name` | Create new session | Start fresh workspace |
| `tmux attach -t name` | Attach to session | Resume work |
| `tmux ls` | List sessions | Check what's running |
| `tmux kill-session -t name` | Kill session | Clean up |
| `Ctrl+A d` | Detach | Leave session running |

### Pane Management
| Shortcut | Action | Use Case |
|----------|--------|----------|
| `Ctrl+A \|` | Split vertical | Side-by-side work |
| `Ctrl+A -` | Split horizontal | Top/bottom layout |
| `Ctrl+A h/j/k/l` | Navigate panes | Move between |
| `Ctrl+A z` | Zoom toggle | Focus one pane |
| `Ctrl+A x` | Kill pane | Close pane |
| `Ctrl+A q` | Exit copy mode | When stuck |

### Copy Mode
- `Ctrl+A [` - Enter copy mode
- `Space` - Start selection
- `Enter` - Copy to buffer
- `Ctrl+A ]` - Paste
- `q` - Exit copy mode

## 🚀 Workflow Patterns

### HypeTrain Multi-Repo Setup
```bash
# Launch workspace with 4 repos
htgo        # Creates 4 panes, auto-runs claudecd
hts         # Check status
htsave      # Save all outputs
htcheck     # Session details

# Quick attach/create
ht1         # Attach to existing or create new
```

### Pane Layout
```
┌─────────────────────┬─────────────────────┐
│ 🚂 Monorepo        │ 🌱 Garden/DevOps    │
│ /HypeTrain         │ /hypetrain-garden   │
├─────────────────────┼─────────────────────┤
│ ⚙️ Backend         │ 📚 Docs             │
│ /hypetrain-backend │ /hypetrain-docs     │
└─────────────────────┴─────────────────────┘
```

## 🛠️ Configuration Tips

### Basic ~/.tmux.conf
```bash
# Better prefix
set -g prefix C-a
unbind C-b

# Mouse support
set -g mouse on

# Vim-style navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# macOS fixes
set -g default-terminal "screen-256color"
set-window-option -g xterm-keys on

# Huge scrollback for AI outputs
set -g history-limit 50000

# Fast escape
set -s escape-time 0
```

### macOS Specific Fixes
```bash
# Fix Option+arrow keys
bind -n M-Left send-key M-b
bind -n M-Right send-key M-f

# Fix clipboard
set -g default-command "reattach-to-user-namespace -l $SHELL"
```

## 🐛 Common Issues & Solutions

### Stuck in Pane
```bash
Ctrl+A q              # Exit copy mode
Ctrl+A x              # Kill pane (confirm with y)
Ctrl+A : respawn-pane -k  # Restart pane
```

### Can't Switch Panes
- Check if in copy mode (`Ctrl+A q`)
- Use `Ctrl+A w` to see window list
- Try `Ctrl+A 0` or `Ctrl+A 1` for windows

### Command Not Found
```bash
source ~/.zshrc       # Reload shell config
chmod +x script.sh    # Make scripts executable
```

### Session Already Exists
```bash
tmux kill-session -t hypetrain  # Kill old session
tmux ls                         # Check what's running
```

## 📊 Best Practices

### For AI Coding (Claude/Cursor)
1. **Separate terminals** - Don't run AI agents in VS Code terminal
2. **Use tmux sessions** - Persistent across terminal restarts
3. **Large scrollback** - 50k+ lines for AI outputs
4. **Save frequently** - `htsave` before context switches

### ADHD-Friendly Setup
- **One command launch** - `htgo` starts everything
- **Visual layouts** - See all contexts at once
- **Quick switching** - `Ctrl+A` + number
- **Auto-setup** - Scripts handle navigation

### Session Management
```bash
# Daily workflow
morning: ht1          # Attach or create
during:  Ctrl+A z     # Zoom when focusing
breaks:  Ctrl+A d     # Detach, keep running
evening: htsave       # Save progress
```

## 🔧 Troubleshooting Scripts

### Simple Workspace Launcher
```bash
#!/bin/zsh
# Kill old session
tmux kill-session -t workspace 2>/dev/null

# Create new with 4 panes
tmux new-session -d -s workspace
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v

# Navigate to repos
tmux send-keys -t 0 'cd ~/repo1' C-m
tmux send-keys -t 1 'cd ~/repo2' C-m
tmux send-keys -t 2 'cd ~/repo3' C-m
tmux send-keys -t 3 'cd ~/repo4' C-m

# Attach
tmux attach-session -t workspace
```

### Status Check Function
```bash
workspace_status() {
    echo "Sessions:"
    tmux ls 2>/dev/null || echo "No sessions"
    echo "\nProcesses:"
    ps aux | grep -E "claude|cursor" | grep -v grep | wc -l
}
```

## 📝 STAR Learnings

### Multi-Agent Setup
- **S**: Need 4 AI agents running in parallel
- **T**: Create stable terminal environment
- **A**: Built tmux workspace with auto-launch
- **R**: One command = 4 agents ready

### Alias Conflicts
- **S**: Function names conflicting with aliases
- **T**: Resolve without breaking workflow
- **A**: Renamed to hypetrain1, ht1, simple scripts
- **R**: Clean startup, no errors

### macOS Integration
- **S**: Keyboard shortcuts broken in tmux
- **T**: Fix Option/Cmd keys for word navigation
- **A**: Added xterm-keys and key bindings
- **R**: Native macOS feel in tmux

## 🚀 Quick Reference Card

```
SESSION
new:    tmux new -s name
attach: tmux attach -t name  
detach: Ctrl+A d
list:   tmux ls

PANES
split:  Ctrl+A | or -
move:   Ctrl+A hjkl
zoom:   Ctrl+A z
kill:   Ctrl+A x

COPY
start:  Ctrl+A [
select: Space
copy:   Enter
paste:  Ctrl+A ]

HYPETRAIN
launch: htgo
attach: ht1
status: hts
save:   htsave
```