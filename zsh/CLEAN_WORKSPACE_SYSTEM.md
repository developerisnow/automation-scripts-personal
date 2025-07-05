# 🚀 Clean Terminal Workspace System
## iterm2 -> tmux -> neovim Chain

### 📋 System Overview

This clean system provides a streamlined workflow:
1. **iTerm2** - Terminal emulator
2. **tmux** - Session management
3. **neovim** - Modal editor

### 🎨 Available Layouts

| Layout | Description | Visual |
|--------|-------------|--------|
| `1` | Single pane with neovim only | `[neovim]` |
| `2h` | 2 horizontal panes (default) | `[neovim][terminal]` |
| `2v` | 2 vertical panes | `[neovim]/[terminal]` |
| `3` | 3 panes: nvim + 2 terminals | `[neovim][term1]/[term2]` |

### 🚀 Quick Commands

```bash
# Launch workspaces with layout
htgo              # HypeTrain with default 2h layout
htgo 3            # HypeTrain with 3-pane layout
twin1 2v          # Twin1 with vertical split
workspace mycode 1 /path/to/project

# Attach to existing sessions
ht                # Attach to hypetrain
tw                # Attach to twin1

# Management
wsls              # List active workspaces
wskill mycode     # Kill workspace
wsgo mycode       # Attach to workspace
```

### 🔧 Project Structure

```
automations/zsh/
├── functions/
│   ├── clean-workspace.zsh          # ✅ Core workspace functions
│   └── 20250626_deprecated_*         # 🗑️ Old files (archived)
├── aliases/
│   ├── clean-workspaces.zsh          # ✅ New clean aliases
│   └── tool-tmux-workspaces.zsh      # ✅ Updated workspace aliases
└── automation-master-loader.zsh      # ✅ Updated loader
```

### 📊 Migration Completed

**✅ Cleaned up deprecated files:**
- `tmux-workspace-fixed.zsh` → `20250701_deprecated_1run_fix_tmux-workspace-fixed.zsh`
- `tmux-workspace.zsh` → `20250626_deprecated_1run_fix_tmux-workspace.zsh`
- `hypetrain-fixes.zsh` → `20250626_deprecated_1run_fix_hypetrain-fixes.zsh`
- `tmux-workspaces-loader.zsh` → `20250626_deprecated_1run_fix_tmux-workspaces-loader.zsh`

**✅ Created clean system:**
- New layout-based workspace launcher
- Simple 1/2h/2v/3 layout options
- Integrated neovim startup
- Clean alias structure

### 💡 Usage Examples

```bash
# Start coding session with your preferred layout
htgo 2h           # Horizontal split for side-by-side work
htgo 3            # Triple pane for complex projects
htgo 1            # Focus mode with neovim only

# Quick project setup
workspace client-project 2v ~/work/client

# Session management
wsls              # See what's running
ht                # Jump back to hypetrain
wskill old-project # Clean up finished work
```

### 🎯 Next Steps

1. **Test the system**: Run `htgo` to try the new clean layout
2. **Choose your default**: Pick 1/2h/2v/3 based on your workflow
3. **Customize paths**: Update project directories in `clean-workspace.zsh`
4. **Add more workspaces**: Use `workspace` function for new projects

The system is now clean, documented, and ready for Claude Code integration! 🎉
