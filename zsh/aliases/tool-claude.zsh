#!/usr/bin/env zsh
# 🤖 Claude Code aliases
# =====================

# ВАЖНО: Для многострочного ввода в Claude Code:
# 1. Запусти: claude-setup (или cc-setup) и выполни /terminal-setup
# 2. После этого Shift+Enter будет создавать новую строку
# 3. Альтернативы: 
#    - Используй \ в конце строки + Enter
#    - На Mac: Option+Enter (Alt+Enter)

# Main claude alias (if you prefer claude-code)
alias claude-code='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error'

# Quick shortcuts
alias cc='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error'
alias ccp='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error --print'  # For non-interactive output

# Setup for multiline input
alias claude-setup='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-setup'
alias cc-setup='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-setup'

# Original claude with errors visible (for debugging)
alias claude-debug='claude'

# Claude with specific tasks
alias cc-help='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error --help'
alias cc-init='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error /init'
alias cc-status='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error /status'

# For piping and scripting
alias claude-json='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error --print --output-format json'
alias claude-stream='/Users/user/.nvm/versions/node/v22.13.0/bin/claude-no-error --print --output-format stream-json'
