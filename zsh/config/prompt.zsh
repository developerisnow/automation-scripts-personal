#!/usr/bin/env zsh
# 🎨 PROMPT CONFIGURATION - Настройка командной строки
# ===================================================

# 🚀 Starship prompt (если установлен)
# ------------------------------------
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
    # Starship настраивается через ~/.config/starship.toml
    return
fi

# 📍 Fallback: Simple ZSH prompt
# ------------------------------
# Если Starship не установлен, используем простой промпт

# Включить подстановку в промпте
setopt PROMPT_SUBST

# Цвета
autoload -U colors && colors

# Git branch function
git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Simple prompt with git branch
PROMPT='%{$fg[cyan]%}%c%{$reset_color%} %{$fg[green]%}$(git_branch)%{$reset_color%} %(?.%{$fg[green]%}❯.%{$fg[red]%}❯)%{$reset_color%} '

# Right prompt with time
RPROMPT='%{$fg[yellow]%}%*%{$reset_color%}'

# 💡 Tips for customization:
# -------------------------
# %n - username
# %m - hostname
# %~ - current directory (full path)
# %c - current directory (last component)
# %* - time
# %D - date
# %(?..) - conditional based on last exit code

# 🎯 Alternative prompts (uncomment to use)
# -----------------------------------------
# Minimal
# PROMPT='%c ❯ '

# With username@host
# PROMPT='%n@%m:%~ ❯ '

# With full path
# PROMPT='%{$fg[blue]%}%~%{$reset_color%} ❯ '

# Two-line prompt
# PROMPT='%{$fg[cyan]%}%~%{$reset_color%} %{$fg[green]%}$(git_branch)%{$reset_color%}
# ❯ '
