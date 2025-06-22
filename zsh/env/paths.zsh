#!/usr/bin/env zsh
# 🛤️ PATH CONFIGURATION - Все модификации PATH в одном месте
# ==========================================================
# Этот файл загружается из .zshrc, НЕ из .zshenv
# (чтобы не дублировать если .zshenv уже загрузил базовые пути)

# 🏗️ Project-specific paths
# -------------------------
# HypeTrain
[[ -d "/Users/user/__Repositories/HypeTrain/bin" ]] && export PATH="/Users/user/__Repositories/HypeTrain/bin:$PATH"

# TaskMaster
[[ -d "/Users/user/__Repositories/claude-task-master/bin" ]] && export PATH="/Users/user/__Repositories/claude-task-master/bin:$PATH"

# Code2Prompt (если установлен локально)
[[ -d "/Users/user/__Repositories/LLMs-code2prompt__mufeedvh/target/release" ]] && export PATH="/Users/user/__Repositories/LLMs-code2prompt__mufeedvh/target/release:$PATH"

# 🛠️ Development Tools
# --------------------
# Kubernetes tools
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Android SDK (если используешь)
if [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export PATH="$ANDROID_HOME/emulator:$PATH"
    export PATH="$ANDROID_HOME/tools:$PATH"
    export PATH="$ANDROID_HOME/tools/bin:$PATH"
    export PATH="$ANDROID_HOME/platform-tools:$PATH"
fi

# Flutter
[[ -d "$HOME/flutter/bin" ]] && export PATH="$HOME/flutter/bin:$PATH"

# 🔧 Custom Scripts
# -----------------
# Твои личные скрипты
[[ -d "$HOME/____Sandruk/scripts" ]] && export PATH="$HOME/____Sandruk/scripts:$PATH"
[[ -d "$HOME/__Repositories/LLMs-own-scripts" ]] && export PATH="$HOME/__Repositories/LLMs-own-scripts:$PATH"

# 📊 Database clients
# -------------------
# PostgreSQL
[[ -d "/Applications/Postgres.app/Contents/Versions/latest/bin" ]] && export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"

# MySQL
[[ -d "/opt/homebrew/opt/mysql-client/bin" ]] && export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# 🎮 Game Development
# -------------------
# Unity Hub
[[ -d "/Applications/Unity/Hub/Editor" ]] && export PATH="/Applications/Unity/Hub/Editor:$PATH"

# 🔍 Search tools
# ---------------
# FZF
[[ -d "$HOME/.fzf/bin" ]] && export PATH="$HOME/.fzf/bin:$PATH"

# 📝 Text processing
# ------------------
# LaTeX
[[ -d "/Library/TeX/texbin" ]] && export PATH="/Library/TeX/texbin:$PATH"

# 🎨 Design tools CLI
# -------------------
# Figma
[[ -d "/Applications/Figma.app/Contents/MacOS" ]] && export PATH="/Applications/Figma.app/Contents/MacOS:$PATH"

# 🔐 Security tools
# -----------------
# GPG
[[ -d "/opt/homebrew/opt/gnupg/bin" ]] && export PATH="/opt/homebrew/opt/gnupg/bin:$PATH"

# 1Password CLI
[[ -d "/opt/homebrew/bin/op" ]] && export PATH="/opt/homebrew/bin:$PATH"

# 🌐 Cloud CLIs
# -------------
# AWS
[[ -d "$HOME/.local/bin/aws" ]] && export PATH="$HOME/.local/bin:$PATH"

# Google Cloud
[[ -d "$HOME/google-cloud-sdk/bin" ]] && export PATH="$HOME/google-cloud-sdk/bin:$PATH"
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/user/Programms/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/user/Programms/google-cloud-sdk/path.zsh.inc'; fi
##### START Google Cloud SDK #####
# Google Cloud SDK.
if [ -f '/Users/user/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/user/google-cloud-sdk/path.zsh.inc'; fi
##### END Google Cloud SDK #####

# The next line enables shell command completion for gcloud.
if [ -f '/Users/user/Programms/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/user/Programms/google-cloud-sdk/completion.zsh.inc'; fi

# Homebrew
[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:$PATH"

# 📱 Mobile Development
# ---------------------
# React Native
export REACT_NATIVE_HOME="$HOME/__Repositories"

# 🔧 Utility function to check PATH
# ---------------------------------
checkpath() {
    echo "🛤️  Current PATH entries:"
    echo $PATH | tr ':' '\n' | nl
}

# Remove duplicates from PATH
dedupe_path() {
    export PATH=$(echo -n $PATH | awk -v RS=: -v ORS=: '!seen[$0]++' | sed 's/:$//')
    echo "✅ PATH deduped!"
}

# Add to PATH safely (check if exists first)
pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
        echo "✅ Added to PATH: $1"
    else
        echo "⚠️  Skipped (not found or already in PATH): $1"
    fi
}

# 🎯 Debug info
# -------------
# Раскомментируй для отладки
# echo "📊 PATH entries count: $(echo $PATH | tr ':' '\n' | wc -l)"
# echo "🔍 First 5 PATH entries:"
# echo $PATH | tr ':' '\n' | head -5

export PATH="/Users/user/bin:/Users/user/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="/Users/user/Library/pnpm"
export PATH="$HOME/.pyenv/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/Users/user/.codeium/windsurf/bin:$PATH"
export PATH="/Users/user/.codeium/windsurf/bin:$PATH"
export PATH="$PATH:/Users/user/.cache/lm-studio/bin"
export PATH=$PATH:$(go env GOPATH)/bin

##### START PATH, other Globals #####
# Path
export PATH="/Users/user/bin:/Users/user/.local/bin:$PATH"

# History
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE=~/.zsh_history

##### END PATH #####

##### START NodeJS, NVMe, PNPM, etc. #####
# NVMe
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/Users/user/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
##### END NodeJS, NVMe, PNPM, etc. #####

##### START Python #####
# Load pyenv automatically by adding
   # the following to ~/.bashrc or ~/.zshrc:
export PATH="$HOME/.pyenv/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
# export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

##### END Python #####