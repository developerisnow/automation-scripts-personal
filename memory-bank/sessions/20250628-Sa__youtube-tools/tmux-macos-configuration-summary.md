# 🎯 TMUX Configuration for macOS - Summary

## 📋 Key macOS-Specific Configurations

### 🎮 1. Prefix Key Configuration
**Problem**: Default `Cmd+A` conflicts with macOS "Select All"
**Solution**: Change to `Ctrl+Space`

```bash
# ~/.tmux.conf
set -g prefix C-Space
unbind C-a
bind C-Space send-prefix
```

### 🖱️ 2. Mouse Support (Essential for macOS/iTerm2)
```bash
# Enable full mouse support
set -g mouse on
```

### ⌨️ 3. Keyboard Shortcuts for macOS

| Action | Key Binding | Description |
|--------|-------------|-------------|
| Prefix | `Ctrl+Space` | Activate tmux commands |
| Navigate Panes | `Ctrl+Space + h/j/k/l` | Vim-style movement |
| Window Switch | `Option+1/2/3/4` | Direct window access |
| Zoom Pane | `Ctrl+Space + z` | Toggle full screen |
| Detach | `Ctrl+Space + d` | Leave session running |

### 📋 4. Clipboard Integration
```bash
# macOS clipboard integration
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
```

### 🪟 5. Window & Pane Management

#### Split Commands
```bash
# Intuitive split commands
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
```

#### Pane Resizing
```bash
# Quick resize (escaped for zsh)
alias 'tpane>='='tmux resize-pane -R 10'
alias 'tpane<='='tmux resize-pane -L 10'
alias tpane+='tmux resize-pane -U 10'
alias tpane-='tmux resize-pane -D 10'
```

## 🚀 Workspace Configurations

### HypeTrain Workspace Layout
```
┌─────────────────────────┬─────────────────────────┐
│ 🚂 Monorepo            │ 🌱 Garden               │
│ /HypeTrain             │ /hypetrain-garden       │
├─────────────────────────┼─────────────────────────┤
│ ⚙️ Backend             │ 📚 Docs                 │
│ /hypetrain-backend     │ /hypetrain-docs         │
└─────────────────────────┴─────────────────────────┘
```

### Twin1 Workspace Layout
```
┌─────────────────────────┬─────────────────────────┐
│ 🧠 PKM                 │ 📤 Exporter             │
│ /____Sandruk/___PKM    │ /LLMs-claude-code-exp   │
├─────────────────────────┼─────────────────────────┤
│ 🤖 PM Agents           │ 💬 TG CRM               │
│ /LLMs-github-pm-agents │ /tg-mcp-assistant-crm   │
└─────────────────────────┴─────────────────────────┘
```

## 🛠️ iTerm2 Integration Settings

### Key Features for iTerm2 + TMUX
1. **256 Color Support**: `tmux -2`
2. **Terminal Override**: `set -ga terminal-overrides ",xterm-256color:Tc"`
3. **Large Scrollback**: `set-option -g history-limit 50000`
4. **Fast Key Response**: `set -s escape-time 0`

### iTerm2 Profile Settings
- Enable "Send text at start": `tmux attach || tmux new`
- Set "Semantic History": Working directory reporting
- Configure "Keys": Pass through Option as Meta

## 🎯 Quick Commands & Aliases

### Essential Aliases
```bash
# Session Management
alias tls='tmux ls'
alias ta='tmux attach -t'
alias tns='tmux new -s'
alias tks='tmux kill-session -t'

# Workspace Launchers
alias htgo='create_tmux_workspace "hypetrain" ...'
alias twin1='create_tmux_workspace "twin1" ...'

# Quick Attach
alias ht='tmux attach -t hypetrain || htgo'
alias tw1='tmux attach -t twin1 || twin1'

# Utilities
alias tsync='tmux setw synchronize-panes'
alias tcopy='tmux save-buffer - | pbcopy'
```

## 🔧 Common macOS Issues & Fixes

### 1. Copy Mode Stuck
```bash
# Exit copy mode in all panes
for pane in $(tmux list-panes -F '#P'); do
    tmux send-keys -t $pane q
done
```

### 2. Mouse Scroll Not Working
```bash
# Ensure mouse is enabled
tmux set -g mouse on
```

### 3. Prefix Key Not Working
```bash
# Reload config
tmux source-file ~/.tmux.conf
```

## 📚 Configuration Files Structure

```
automations/zsh/
├── functions/
│   └── tmux-workspace.zsh      # DRY workspace creator
├── aliases/
│   ├── tool-tmux.zsh          # TMUX aliases
│   └── tool-tmux-workspaces.zsh # Workspace aliases
├── scripts/
│   ├── tmux-macos-fix.sh      # Fix prefix conflicts
│   └── tmux-workspaces-loader.zsh # Load workspaces
└── TMUX_WORKSPACES_README.md  # Documentation
```

## 💡 Best Practices for macOS

1. **Use Mouse**: Take advantage of macOS trackpad/mouse support
2. **Visual Indicators**: Enable pane borders and status bar
3. **Consistent Prefix**: Stick with `Ctrl+Space` to avoid conflicts
4. **Clipboard Integration**: Use `pbcopy`/`pbpaste` for seamless copy/paste
5. **iTerm2 Integration**: Leverage iTerm2's tmux integration mode when needed

## 🚀 Quick Start
```bash
# 1. Apply macOS fixes
./tmux-macos-fix.sh

# 2. Source workspace loader
source tmux-workspaces-loader.zsh

# 3. Launch workspace
htgo  # or twin1
```

---
**Created**: 2025-06-28
**Category**: tmux, macOS, iTerm2
**Status**: Complete Summary