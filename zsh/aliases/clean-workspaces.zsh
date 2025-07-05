#!/bin/zsh
# 🎯 Clean Terminal Workspace Aliases - ENHANCED with Path Support
# =================================================================

# Source the enhanced workspace functions
source /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/functions/clean-workspace.zsh

# 📁 Standalone Path Aliases (can be used anywhere)
alias back='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend'
alias front='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-frontend'
alias mono='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-monorepo'
alias api='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-api'
alias docs='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs'
alias garden='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden'
alias pkm='cd /Users/user/____Sandruk/___PKM'
alias repos='cd /Users/user/__Repositories'

# 🚀 Enhanced workspace aliases with path support
alias ht='ws_attach hypetrain'
alias tw='ws_attach twin1'

# 🎯 Specific Workspace Launchers (with default layouts)
alias htback='htgoback'           # Default 2h layout
alias htfront='htgofront'         # Default 2h layout  
alias htmono='htgomono'           # Default 2h layout
alias htapi='htgoapi'             # Default 2h layout
alias htdocs='htgodocs'           # Default 2h layout
alias htgarden='htgogarden'       # Default 2h layout
alias htpkm='htgopkm'             # Default 2h layout

# 🎨 Layout-specific workspace launchers
alias htback1='htgoback 1'        # Single pane backend
alias htback2h='htgoback 2h'      # Horizontal backend
alias htback2v='htgoback 2v'      # Vertical backend
alias htback3='htgoback 3'        # 3-pane backend

alias htfront1='htgofront 1'      # Single pane frontend
alias htfront2h='htgofront 2h'    # Horizontal frontend
alias htfront2v='htgofront 2v'    # Vertical frontend
alias htfront3='htgofront 3'      # 3-pane frontend

# 📋 Status checkers (enhanced)
alias htcheck='tmux info | grep hypetrain || echo "❌ No hypetrain session. Run: htgo"'
alias twcheck='tmux info | grep twin1 || echo "❌ No twin1 session. Run: twin1"'
alias backcheck='tmux info | grep hypetrain-backend || echo "❌ No backend session. Run: htback"'

# 💾 Save session outputs
alias htsave='tmux capture-pane -t hypetrain -p > hypetrain-session-$(date +%Y%m%d-%H%M).log && echo "✅ Saved hypetrain session"'
alias twsave='tmux capture-pane -t twin1 -p > twin1-session-$(date +%Y%m%d-%H%M).log && echo "✅ Saved twin1 session"'
alias backsave='tmux capture-pane -t hypetrain-backend -p > backend-session-$(date +%Y%m%d-%H%M).log && echo "✅ Saved backend session"'

# 🗑️ Kill sessions
alias htkill='ws_kill hypetrain'
alias twkill='ws_kill twin1'
alias backkill='ws_kill hypetrain-backend'
alias frontkill='ws_kill hypetrain-frontend'

# 📊 Enhanced workspace management
alias wslist='ws_list'
alias wspaths='ws_paths'            # Show all path aliases
alias wsadd='ws_add_path'           # Add new path alias

# 🎨 Quick layout launchers for current directory
alias ws1='workspace quick 1'       # Quick single pane
alias ws2h='workspace quick 2h'     # Quick horizontal
alias ws2v='workspace quick 2v'     # Quick vertical  
alias ws3='workspace quick 3'       # Quick 3-pane

# 💡 Enhanced help with examples
alias ws-help='echo "🚀 ENHANCED WORKSPACE COMMANDS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 QUICK LAUNCH WITH PATHS:
  htgo [layout] [path/alias]  - General hypetrain workspace
  htback [layout]             - Backend workspace (auto-path)
  htfront [layout]            - Frontend workspace (auto-path)
  htmono [layout]             - Monorepo workspace (auto-path)

📁 PATH ALIASES (standalone cd commands):
  back                        - cd to backend directory
  front                       - cd to frontend directory
  mono                        - cd to monorepo directory
  pkm                         - cd to PKM directory

🎨 LAYOUT OPTIONS:
  1     - Single pane (neovim only)
  2h    - 2 horizontal (neovim | terminal) [DEFAULT]
  2v    - 2 vertical (neovim / terminal)
  3     - 3 panes (neovim | terminal / terminal)

🔧 MANAGEMENT:
  wslist                      - List active workspaces
  wspaths                     - Show all path aliases
  wsadd <alias> <path>        - Add new path alias
  ws_kill <session>           - Kill specific session

💡 EXAMPLES:
  htgo 3 back                 - 3-pane layout in backend directory
  htback 2v                   - Vertical backend workspace
  workspace myproject 3 /custom/path
  htgo 2h pkm                 - Horizontal layout in PKM directory
  back && ls                  - Go to backend and list files

🚀 QUICK CURRENT DIRECTORY:
  ws1/ws2h/ws2v/ws3          - Launch workspace in current dir
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"'

# 🎯 Show path aliases on load
ws-paths-quick() {
    echo "📁 Quick Path Reference:"
    echo "back→backend | front→frontend | mono→monorepo | pkm→notes"
    echo "💡 Type 'wspaths' for full list"
}

# 🎨 Layout examples for specific paths
ws-examples-enhanced() {
    echo "🎨 ENHANCED WORKSPACE EXAMPLES:"
    echo ""
    echo "🚀 Backend Development:"
    echo "  htback 3              # 3-pane backend workspace"
    echo "  htgo 2v back          # Vertical layout in backend"
    echo "  workspace api 3 back  # Custom session name"
    echo ""
    echo "🎨 Frontend Development:"
    echo "  htfront 2h            # Horizontal frontend workspace"
    echo "  htgo 3 front          # 3-pane in frontend directory"
    echo ""
    echo "📚 Documentation Work:"
    echo "  htdocs 2v             # Vertical docs workspace"
    echo "  htpkm 1               # Focus mode in PKM"
    echo ""
    echo "🔀 Mixed Workflows:"
    echo "  workspace fullstack 3 mono  # Monorepo 3-pane"
    echo "  htgo 2h /custom/path        # Custom path"
    echo ""
    echo "📐 Layout Visualization:"
    echo "┌─────────┬─────────────────────┬─────────────┐"
    echo "│ Layout 3│     Layout 2h       │  Layout 2v  │"
    echo "├─────────┼─────────────────────┼─────────────┤"
    echo "│nvim│term│ neovim  │ terminal  │   neovim    │"
    echo "│    │term│         │           ├─────────────┤"
    echo "│    │    │         │           │  terminal   │"
    echo "└─────────┴─────────────────────┴─────────────┘"
}

# 🔧 Development shortcuts for common tasks
alias htdev='htback 3 && echo "🚀 Backend development environment ready!"'
alias htfull='htmono 3 && echo "🚀 Full-stack development environment ready!"'
alias htwrite='htpkm 2v && echo "📝 Writing environment ready!"'
