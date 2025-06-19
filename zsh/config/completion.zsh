#!/usr/bin/env zsh
# 🔧 COMPLETION CONFIGURATION - Автодополнение команд
# ===================================================

# 🎯 Basic completion setup
# -------------------------
autoload -Uz compinit
compinit

# 🌟 Completion options
# ---------------------
setopt COMPLETE_IN_WORD     # Complete from both ends of a word
setopt ALWAYS_TO_END        # Move cursor to the end of a completed word
setopt PATH_DIRS            # Perform path search even on command names with slashes
setopt AUTO_MENU            # Show completion menu on a successive tab press
setopt AUTO_LIST            # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH     # If completed parameter is a directory, add a trailing slash
setopt MENU_COMPLETE        # Cycle through completion options

# 🎨 Completion styling
# ---------------------
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' verbose yes

# 📁 Directory completion
# -----------------------
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95=38;5;12'

# 🔍 Fuzzy matching
# -----------------
zstyle ':completion:*' completer _expand _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# 📊 Cache completion results
# ---------------------------
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$HOME/.cache/zsh-completion"

# 🚫 Ignore patterns
# ------------------
zstyle ':completion:*' ignored-patterns '.DS_Store' '__pycache__' '*.pyc' '*.pyo'

# 🔧 Specific command completions
# -------------------------------
# Git
zstyle ':completion:*:*:git:*' script /usr/local/share/zsh/site-functions/_git

# Kill
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# 📝 Descriptions
# ---------------
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
