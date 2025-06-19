#!/usr/bin/env zsh
# 🐙 GIT ALIASES - Быстрые команды для Git
# ========================================
# ADHD tip: Группировка по действиям, а не по алфавиту!

# 🔍 Status & Info
# ----------------
alias g='git'
alias gs='git status'
alias gss='git status -s'  # Короткий формат
alias gsb='git status -sb' # Короткий + branch info

# 📝 Adding & Committing
# ----------------------
alias ga='git add'
alias gaa='git add --all'
alias gap='git add -p'  # Интерактивное добавление
alias gai='git add -i'  # Интерактивный режим

# Commits
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit -a'
# alias gcam='git commit -a -m'  # Закомментировано, т.к. есть функция ниже
alias gcamend='git commit --amend'
alias gcamend!='git commit --amend --no-edit'

# Quick commit all with message (заменяет alias gcam)
gcam() {
    git add --all && git commit -m "$1"
}

# 🌿 Branches
# -----------
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'  # Force delete

# Switch/Checkout
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcom='git checkout main'
alias gcod='git checkout develop'
alias gco-='git checkout -'  # Вернуться на предыдущую ветку

# 🔄 Pull & Push
# --------------
alias gl='git pull'
alias glr='git pull --rebase'
alias gp='git push'
alias gpf='git push --force-with-lease'  # Безопасный force push
alias gpu='git push --set-upstream origin $(git branch --show-current)'

# Push current branch
gpc() {
    git push origin $(git branch --show-current)
}

# 📊 Logs & History
# -----------------
alias glog='git log --oneline --graph --decorate'
alias gloga='git log --oneline --graph --decorate --all'
alias glogp='git log --oneline --graph --decorate --pretty=format:"%h %s %cr"'

# Beautiful log
alias gll='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

# 🔍 Diffs
# --------
alias gd='git diff'
alias gds='git diff --staged'
alias gdh='git diff HEAD'
alias gdt='git diff-tree --no-commit-id --name-only -r'  # Список файлов в коммите

# 🚀 Stash
# --------
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gsta='git stash apply'
alias gstd='git stash drop'
alias gstc='git stash clear'

# 🔄 Merging & Rebasing
# ---------------------
alias gm='git merge'
alias gma='git merge --abort'
alias gr='git rebase'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias gri='git rebase -i'

# 🧹 Cleanup
# ----------
alias gclean='git clean -fd'
alias gpristine='git reset --hard && git clean -dfx'

# 📍 Remote
# ---------
alias gremote='git remote'
alias grv='git remote -v'
alias gra='git remote add'
alias grr='git remote remove'

# 🏷️ Tags
# -------
alias gt='git tag'
alias gta='git tag -a'
alias gtd='git tag -d'

# 🚑 Undo & Fix
# -------------
alias gundo='git reset HEAD~1'
alias gundosoft='git reset --soft HEAD~1'
alias gundohard='git reset --hard HEAD~1'

# 📊 Stats & Info
# ---------------
# Кто больше всего коммитил
alias gcontrib='git shortlog -sn'

# Последние изменения по файлам
alias gchanged='git whatchanged -p --abbrev-commit --pretty=medium'

# 🎯 Useful Functions
# -------------------
# Клонировать и сразу перейти
gclone() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Найти и удалить merged branches
gcleanmerged() {
    git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
}

# Показать размер репозитория
greposize() {
    git count-objects -vH
}

# 🔥 Aliases для частых workflow
# ------------------------------
# Quick save (add all + commit + push)
alias gsave='git add -A && git commit -m "Quick save" && git push'

# WIP commit
