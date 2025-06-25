#!/usr/bin/env zsh
# 🎨 iTerm2 Best Practices for AI Coding
# ======================================

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 iTerm2 AUTOMATION & SCRIPTING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Open new iTerm window
iterm-new() {
    osascript -e 'tell application "iTerm2" to create window with default profile'
}

# Split current pane vertically and run command
iterm-vsplit() {
    local cmd="${1:-zsh}"
    osascript -e "
    tell application \"iTerm2\"
        tell current session of current window
            split vertically with default profile
        end tell
        tell last session of current tab of current window
            write text \"$cmd\"
        end tell
    end tell"
}

# Split current pane horizontally and run command
iterm-hsplit() {
    local cmd="${1:-zsh}"
    osascript -e "
    tell application \"iTerm2\"
        tell current session of current window
            split horizontally with default profile
        end tell
        tell last session of current tab of current window
            write text \"$cmd\"
        end tell
    end tell"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🤖 AI WORKSPACE LAYOUTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Create AI coding workspace with claude agents
ai-iterm() {
    osascript << 'EOF'
    tell application "iTerm2"
        -- Create new window
        create window with default profile
        tell current window
            -- Get the first session
            set firstSession to current session
            
            -- Split vertically (creates right pane)
            tell firstSession
                split vertically with default profile
            end tell
            
            -- Get the right session and split it horizontally
            set rightSession to last session of current tab
            tell rightSession
                split horizontally with default profile
            end tell
            
            -- Split the original left pane horizontally too
            tell firstSession
                split horizontally with default profile
            end tell
            
            -- Now we have 4 panes, run commands
            tell session 1 of current tab
                write text "claude-code # Main agent"
            end tell
            
            tell session 2 of current tab
                write text "# Second agent ready"
            end tell
            
            tell session 3 of current tab
                write text "tail -f ~/.claude/logs/latest.log 2>/dev/null || echo 'Logs will appear here'"
            end tell
            
            tell session 4 of current tab
                write text "btop"
            end tell
        end tell
    end tell
EOF
}

# Quick claude session with log viewer
claude-iterm() {
    osascript << 'EOF'
    tell application "iTerm2"
        create window with default profile
        tell current window
            tell current session
                split vertically with default profile
                write text "claude-code"
            end tell
            tell last session of current tab
                write text "tail -f ~/.claude/logs/latest.log 2>/dev/null || watch -n 1 'echo Claude logs will appear here'"
            end tell
        end tell
    end tell
EOF
}

# Multi-tab AI workspace
ai-tabs() {
    osascript << 'EOF'
    tell application "iTerm2"
        create window with default profile
        tell current window
            -- Tab 1: Main claude
            set name of current tab to "Claude Main"
            tell current session
                write text "claude-code"
            end tell
            
            -- Tab 2: Claude debug
            create tab with default profile
            set name of current tab to "Claude Debug"
            tell current session
                write text "claude --verbose"
            end tell
            
            -- Tab 3: Monitoring
            create tab with default profile
            set name of current tab to "Monitoring"
            tell current session
                split horizontally with default profile
                write text "btop"
            end tell
            tell last session of current tab
                write text "tail -f ~/.claude/logs/*.log"
            end tell
            
            -- Go back to first tab
            select tab 1
        end tell
    end tell
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 PROFILE MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Switch to specific profile
iterm-profile() {
    local profile="${1:-Default}"
    osascript -e "
    tell application \"iTerm2\"
        tell current session of current window
            set profile to \"$profile\"
        end tell
    end tell"
}

# Create minimal profile for AI agents
iterm-create-ai-profile() {
    echo "
📝 To create AI-optimized profiles in iTerm2:

1. Open iTerm2 → Preferences → Profiles
2. Create these profiles:

🤖 'AI Simple' Profile:
   - Colors: Minimal theme (Tango Dark works well)
   - Text: Monaco 13pt
   - Terminal: Unlimited scrollback
   - Keys: Natural Text Editing preset
   - Advanced: Disable animations

🐛 'AI Debug' Profile:
   - Same as above but with:
   - Window: Show mark indicators
   - Terminal: Log output to ~/ai-debug.log
   - Status Bar: Enable with CPU, Memory, Network

📊 'AI Monitor' Profile:
   - Colors: Dark background for less eye strain
   - Window: Transparency 10%
   - Status Bar: Full monitoring widgets

3. Assign Hotkeys:
   - Cmd+Shift+1 → AI Simple
   - Cmd+Shift+2 → AI Debug  
   - Cmd+Shift+3 → AI Monitor
"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📸 CAPTURE & LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Start logging current session
iterm-log-start() {
    local logfile="${1:-~/iterm-session-$(date +%Y%m%d-%H%M%S).log}"
    osascript -e "
    tell application \"iTerm2\"
        tell current session of current window
            start logging to \"$logfile\"
        end tell
    end tell"
    echo "📝 Logging to: $logfile"
}

# Stop logging
iterm-log-stop() {
    osascript -e '
    tell application "iTerm2"
        tell current session of current window
            stop logging
        end tell
    end tell'
}

# Capture pane to clipboard
iterm-capture() {
    osascript -e '
    tell application "iTerm2"
        tell current session of current window
            set sessionContents to text
            set the clipboard to sessionContents
        end tell
    end tell'
    echo "📋 Session contents copied to clipboard"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 ITERM2 + TMUX INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Launch tmux in iTerm with proper integration
iterm-tmux() {
    osascript << 'EOF'
    tell application "iTerm2"
        create window with default profile
        tell current window
            tell current session
                -- Enable native tmux integration
                write text "tmux -CC new -s ai-workspace"
            end tell
        end tell
    end tell
EOF
}

# Attach to tmux session with iTerm integration
iterm-tmux-attach() {
    local session="${1:-ai-workspace}"
    osascript -e "
    tell application \"iTerm2\"
        create window with default profile
        tell current window
            tell current session
                write text \"tmux -CC attach -t $session\"
            end tell
        end tell
    end tell"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ PERFORMANCE OPTIMIZATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Disable GPU rendering for problem sessions
iterm-fix-gpu() {
    osascript -e '
    tell application "iTerm2"
        tell current session of current window
            set use GPU renderer to false
        end tell
    end tell'
    echo "🔧 GPU rendering disabled for current session"
}

# Clear scrollback buffer
iterm-clear-buffer() {
    osascript -e '
    tell application "iTerm2"
        tell current session of current window
            tell application "System Events" to keystroke "k" using command down
        end tell
    end tell'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 QUICK ACTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Broadcast input to all panes (like tmux sync)
iterm-broadcast() {
    echo "
📢 To broadcast input in iTerm2:
1. Cmd+Shift+I → Toggle broadcast
2. Or: Shell → Broadcast Input → To All Panes
"
}

# Quick split with claude
alias isplit='iterm-vsplit "claude-code"'
alias ihsplit='iterm-hsplit "claude-code"'

# Quick monitoring split
imon() {
    iterm-vsplit "btop"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛠️ ITERM2 CONFIG RECOMMENDATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

iterm-optimize() {
    cat << 'EOF'
🚀 iTerm2 OPTIMIZATION FOR AI CODING
====================================

1️⃣ GENERAL SETTINGS
   □ Preferences → General → Selection
     ✓ Copy to pasteboard on selection
     ✓ Applications in terminal may access clipboard
   
   □ Preferences → General → Window
     ✓ Adjust window when changing font size

2️⃣ APPEARANCE
   □ Preferences → Appearance → Tabs
     ✓ Show tab bar even when there is only one tab
     ✓ Show tab numbers
   
   □ Theme: Minimal or Compact

3️⃣ PROFILES → DEFAULT → GENERAL
   □ Working Directory: Reuse previous session's directory
   □ Shortcut Key: Set a hotkey for quick access

4️⃣ PROFILES → DEFAULT → TERMINAL
   □ Scrollback lines: Unlimited
   □ ✓ Enable mouse reporting
   □ ✓ Terminal may report window title

5️⃣ PROFILES → DEFAULT → KEYS
   □ Presets: Natural Text Editing
   □ Add custom keys:
     - Cmd+K → Clear Buffer
     - Cmd+/ → Find Cursor

6️⃣ ADVANCED SETTINGS (search in Advanced)
   □ Disable animation: Yes
   □ GPU rendering: Yes (disable if issues)
   □ Scrollback buffer size in MB: 100
   □ Maximum number of characters per line: 10000

7️⃣ STATUS BAR (Profiles → Session)
   □ Enable Status Bar
   □ Add components:
     - CPU Usage
     - Memory Usage  
     - Current Directory
     - Git Branch
     - Clock

8️⃣ HOTKEY WINDOW
   □ Keys → Hotkey → Create Dedicated Hotkey Window
   □ Set to: Cmd+` (or your preference)
   □ Pin hotkey window: Floating window

9️⃣ SHELL INTEGRATION
   □ Install: iTerm2 → Install Shell Integration
   □ This enables:
     - Better command history
     - Automatic profile switching
     - Upload/download with drag & drop

🎯 KEYBOARD SHORTCUTS TO REMEMBER
   Cmd+D          Split vertically
   Cmd+Shift+D    Split horizontally
   Cmd+[/]        Navigate between panes
   Cmd+Shift+I    Broadcast input
   Cmd+Shift+E    Show timestamps
   Cmd+Option+E   Search all tabs
   Cmd+;          Autocomplete from history
   
💡 PRO TIPS
   - Use Cmd+Click on URLs/paths to open
   - Hold Option to select rectangular regions
   - Use Cmd+F for better search than terminal search
   - Install "iterm2-badge" for visual pane identification
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 HELP & CHEATSHEET
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

iterm-help() {
    cat << 'EOF'
🎨 iTerm2 + AI CODING CHEATSHEET
================================

🚀 QUICK LAUNCHERS
  ai-iterm        4-pane AI workspace
  claude-iterm    Claude + logs split
  ai-tabs         Multi-tab setup
  iterm-tmux      Launch with tmux integration

📐 SPLITS & LAYOUTS  
  iterm-vsplit    Vertical split + command
  iterm-hsplit    Horizontal split + command
  isplit          Quick claude split
  imon            Quick monitoring split

📸 CAPTURE & LOGGING
  iterm-log-start [file]    Start logging
  iterm-log-stop           Stop logging
  iterm-capture            Copy pane to clipboard
  iterm-clear-buffer       Clear scrollback

🎨 PROFILES
  iterm-profile [name]     Switch profile
  Cmd+Shift+1             AI Simple profile
  Cmd+Shift+2             AI Debug profile
  Cmd+Shift+3             AI Monitor profile

⚡ KEYBOARD SHORTCUTS
  Cmd+D                   Split vertically
  Cmd+Shift+D             Split horizontally
  Cmd+[/]                 Navigate panes
  Cmd+Option+←/→          Navigate tabs
  Cmd+Shift+I             Broadcast input
  Cmd+Click               Open URL/path
  Cmd+Shift+H             Paste history
  Cmd+;                   Autocomplete

🔧 TROUBLESHOOTING
  iterm-fix-gpu           Disable GPU for session
  iterm-optimize          Show optimization guide

💡 TIPS
  - Use profiles for different AI contexts
  - Status bar for monitoring resources
  - Shell integration for better history
  - Hotkey window for quick access
EOF
}

# Show quick tips on load
echo "🎨 iTerm2 aliases loaded! Run 'iterm-help' for commands"
