#!/bin/zsh
# 🎯 TMUX Workspace Aliases (DRY + KISS)

# Source the generic workspace function
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/tmux-workspace.zsh

# 🚀 Quick aliases for workspaces
# htgo - already defined in tmux-workspace.zsh
# twin1 - already defined in tmux-workspace.zsh

# 🔍 Helper aliases for all workspaces
alias ht='tmux attach-session -t hypetrain 2>/dev/null || echo "❌ No hypetrain session. Run: htgo"'
alias tw1='tmux attach-session -t twin1 2>/dev/null || echo "❌ No twin1 session. Run: twin1"'

# 📋 Status checkers
alias htcheck='tmux info | grep hypetrain || echo "❌ No hypetrain session found"'
alias tw1check='tmux info | grep twin1 || echo "❌ No twin1 session found"'

# 💾 Save outputs
alias htsave='tsave hypetrain-session-$(date +%Y%m%d-%H%M).log'
alias tw1save='tsave twin1-session-$(date +%Y%m%d-%H%M).log'

# 🗑️ Kill sessions
alias htkill='tmux kill-session -t hypetrain 2>/dev/null && echo "✅ hypetrain killed" || echo "❌ No session to kill"'
alias tw1kill='tmux kill-session -t twin1 2>/dev/null && echo "✅ twin1 killed" || echo "❌ No session to kill"'

# 📊 List all workspace sessions
alias wslist='echo "🎯 Active workspaces:" && tmux list-sessions 2>/dev/null | grep -E "(hypetrain|twin1)" || echo "No workspaces active"'
