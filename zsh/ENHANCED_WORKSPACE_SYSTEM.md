# 🚀 Enhanced Clean Terminal Workspace System
## iterm2 -> tmux -> neovim Chain with Path Aliases

### 📋 System Overview

Enhanced workflow with path aliases:
1. **iTerm2** - Terminal emulator
2. **tmux** - Session management with layouts
3. **neovim** - Modal editor (auto-starts in main pane)
4. **Path Aliases** - Quick navigation to common projects

### 🎨 Available Layouts + Path Support

| Layout | Description | Usage Example |
|--------|-------------|---------------|
| `1` | Single pane (neovim only) | `htgo 1 back` |
| `2h` | 2 horizontal panes (default) | `htback 2h` |
| `2v` | 2 vertical panes | `htfront 2v` |
| `3` | 3 panes: nvim + 2 terminals | `htgo 3 back` |

### 📁 Built-in Path Aliases

| Alias | Path | Usage |
|-------|------|-------|
| `back` | `/Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend` | `htgo 3 back` |
| `front` | `/Users/user/__Repositories/HypeTrain/repositories/hypetrain-frontend` | `htfront 2v` |
| `mono` | `/Users/user/__Repositories/HypeTrain/repositories/hypetrain-monorepo` | `htmono 3` |
| `api` | `/Users/user/__Repositories/HypeTrain/repositories/hypetrain-api` | `htapi 2h` |
| `docs` | `/Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs` | `htdocs 1` |
| `garden` | `/Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden` | `htgarden 2v` |
| `pkm` | `/Users/user/____Sandruk/___PKM` | `htpkm 2h` |
| `repos` | `/Users/user/__Repositories` | `htgo 3 repos` |

### 🚀 Enhanced Commands

#### **General Workspace Launcher (Your Request)**
```bash
# ✅ EXACTLY what you asked for:
htgo 3 back                    # 3-pane layout in backend directory
htgo 2v front                  # Vertical layout in frontend  
htgo 1 pkm                     # Single pane in PKM directory
htgo 2h /custom/path           # Custom absolute path

# Path aliases work anywhere:
workspace myproject 3 back     # Custom session name with backend path
```

#### **Specific Project Functions**
```bash
# ✅ Shortcuts for common workflows:
htgoback 3                     # Backend workspace (3-pane)
htgofront 2v                   # Frontend workspace (vertical)
htgomono 3                     # Monorepo workspace (3-pane)
htgoapi 2h                     # API workspace (horizontal)
```

#### **Standalone Path Navigation**
```bash
# ✅ Quick directory jumps:
back                           # cd to backend directory
front                          # cd to frontend directory
mono                           # cd to monorepo directory
pkm                            # cd to PKM directory
```

### 💡 Real-World Usage Examples

#### **Backend Development Session**
```bash
# Method 1: Using path alias
htgo 3 back

# Method 2: Using specific function  
htgoback 3

# Method 3: Custom session name
workspace backend-api 3 back

# All create the same result:
┌─────────┬─────────────┐
│         │   terminal  │
│ neovim  ├─────────────┤
│         │   terminal  │
└─────────┴─────────────┘
# In: /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend
```

#### **Quick Directory + Editor**
```bash
# Navigate and launch in one command
htgo 2v pkm                    # Vertical split in PKM for writing

# Or navigate first, then launch
back                           # Go to backend directory
htgo 3                         # Launch 3-pane in current (backend) directory
```

#### **Multi-Project Workflow**
```bash
# Terminal 1: Backend work
htgoback 3

# Terminal 2: Frontend work (new iTerm window)
htgofront 2v

# Terminal 3: Documentation (new iTerm window)  
htgodocs 1
```

### 🔧 Enhanced Workspace Management

```bash
# List active workspaces
wslist

# Show all path aliases and their validity
wspaths

# Add new path alias (temporary)
wsadd myproject /path/to/my/project

# Kill specific workspace
ws_kill hypetrain-backend

# Quick attach
ht                             # Attach to hypetrain
tw                             # Attach to twin1
```

### 📊 Command Reference

#### **Layout + Path Combinations**
```bash
# Single pane with different paths
htgo 1 back                    # Backend focus mode
htgo 1 front                   # Frontend focus mode
htgo 1 pkm                     # Writing focus mode

# Horizontal splits
htgo 2h back                   # Backend with side terminal
htgo 2h mono                   # Monorepo with side terminal

# Vertical splits  
htgo 2v front                  # Frontend with bottom terminal
htgo 2v docs                   # Docs with bottom terminal

# Triple pane power mode
htgo 3 back                    # Backend with 2 side terminals
htgo 3 mono                    # Monorepo with 2 side terminals
```

#### **Quick Development Setups**
```bash
# Predefined workflow aliases
htdev                          # htback 3 (backend development)
htfull                         # htmono 3 (full-stack development)  
htwrite                        # htpkm 2v (writing environment)
```

### 🎯 Path Resolution Logic

The system resolves paths in this order:
1. **Alias lookup**: `back` → `/Users/user/.../hypetrain-backend`
2. **Tilde expansion**: `~/projects` → `/Users/user/projects`
3. **Absolute path**: `/custom/path` (used as-is)
4. **Relative path**: `./subdir` → `$PWD/subdir`
5. **Current directory**: Empty/no param → `$PWD`

### ✅ Migration from Old System

**Old way:**
```bash
htgo                           # Fixed path, basic layout
twin1                          # Fixed path, basic layout
```

**Enhanced way:**
```bash
htgo 3 back                    # Flexible layout + path
htgoback 3                     # Specific function
htgo 2v front                  # Different project entirely
```

### 🔍 Troubleshooting

#### **Path Not Found**
```bash
# Check available aliases
wspaths

# Verify directory exists
ls -la /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend

# Add missing alias
wsadd newproject /path/to/project
```

#### **Wrong Directory**
```bash
# Check where workspace launched
pwd

# Relaunch with correct path
htgo 3 back
```

#### **Session Conflicts**
```bash
# List active sessions
wslist

# Kill conflicting session
ws_kill hypetrain-backend

# Relaunch
htgoback 3
```

### 🎉 Success! Your Enhanced System

✅ **`htgo 3 back`** - ✅ Works exactly as requested  
✅ **`htgoback 3`** - ✅ Specific project functions  
✅ **`back` alias** - ✅ Standalone directory navigation  
✅ **Path resolution** - ✅ Aliases, absolute, relative paths  
✅ **All layouts** - ✅ 1, 2h, 2v, 3 with any path  

**Test it now:**
```bash
# Reload your automation
source ~/.zshrc

# Test the exact command you wanted
htgo 3 back
```

The enhanced system maintains all previous functionality while adding the flexible path support you requested! 🚀
