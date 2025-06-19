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
