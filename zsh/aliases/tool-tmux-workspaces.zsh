#!/bin/zsh
# 🎯 TMUX Workspace Aliases - CLEAN VERSION
# ==========================================

# Source the clean workspace function (replaces old deprecated functions)
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/clean-workspace.zsh

# 🚀 Enhanced workspace aliases with layouts
# htgo and twin1 are defined in clean-workspace.zsh

# 🔍 Helper aliases for workspace management
alias ht='ws_attach hypetrain'
alias tw='ws_attach twin1'

# 📋 Status checkers (enhanced)
alias htcheck='tmux info | grep hypetrain || echo "❌ No hypetrain session. Run: htgo"'
alias twcheck='tmux info | grep twin1 || echo "❌ No twin1 session. Run: twin1"'

# 💾 Save session outputs
alias htsave='tmux capture-pane -t hypetrain -p > hypetrain-session-$(date +%Y%m%d-%H%M).log && echo "✅ Saved hypetrain session"'
alias twsave='tmux capture-pane -t twin1 -p > twin1-session-$(date +%Y%m%d-%H%M).log && echo "✅ Saved twin1 session"'

# 🗑️ Kill sessions
alias htkill='ws_kill hypetrain'
alias twkill='ws_kill twin1'

# 📊 List all workspace sessions
alias wslist='ws_list'

# 🎨 Layout-specific quick launches
alias htgo-single='htgo 1'         # Single pane
alias htgo-h='htgo 2h'              # Horizontal split
alias htgo-v='htgo 2v'              # Vertical split  
alias htgo-triple='htgo 3'          # 3-pane layout

alias twin-single='twin1 1'        # Single pane
alias twin-h='twin1 2h'            # Horizontal split
alias twin-v='twin1 2v'            # Vertical split
alias twin-triple='twin1 3'        # 3-pane layout

# 💡 Quick help
alias ws-quick-help='echo "🚀 QUICK WORKSPACE COMMANDS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 LAUNCH:
  htgo [1|2h|2v|3]  - HypeTrain workspace
  twin1 [1|2h|2v|3] - Twin1 workspace

🔧 MANAGE:
  ht / tw           - Attach to existing
  htkill / twkill   - Kill sessions
  wslist            - List all workspaces

🎨 LAYOUTS:
  1  = neovim only
  2h = neovim | terminal (default)
  2v = neovim / terminal  
  3  = neovim | (terminal / terminal)

💡 Type ws-help for full documentation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"'
