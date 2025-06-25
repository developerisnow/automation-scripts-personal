#!/usr/bin/env zsh
# 🤖 Gemini Cli Code aliases

# Standard Gemini
alias gemini='gemini --verbose'

# Gemini Dangerous (skip permissions)
alias geminid='gemini --verbose --no-review'

# Gemini Continue (session management)
alias geminicd='gemini --verbose --no-review --continue'

# Gemini Resume
alias geminird='gemini --verbose --no-review --resume'

# Short aliases
alias gm='gemini'
alias gmd='geminid'
alias gmcd='geminicd'
alias gmrd='geminird'