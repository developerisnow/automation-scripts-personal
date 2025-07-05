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

alias pkgtoken='echo ${NPM_TOKEN: -8}'
alias pkgauth='curl -sI -H "Authorization: token $NPM_TOKEN" https://npm.pkg.github.com/@infludb-inc%2fhypetrain-common | head -3'
alias pkgtesturl='npm view @infludb-inc/hypetrain-common dist.tarball'
alias pkgcommon='npm view @infludb-inc/hypetrain-common versions --json | jq length'

alias ghapitest='gh api developerisnow --jq .login'

# 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
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
alias gwip='git add -A && git commit -m "WIP: Work in progress"'

# Sync with upstream
alias gsync='git fetch upstream && git merge upstream/main'

# === Migrated from old .zshrc ===
alias gitc='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git_commit_push.sh'
alias gitdoc='git add docs .cursor package.json && git commit -m "docs" --no-verify'
alias gitsrc='git add docs src package.json && git commit -m "[WIP]src folder updates" --no-verify'
alias gittest='git add docs test package.json && git commit -m "[WIP] tests" --no-verify'
alias gitall='git add . && git commit -m "update" --no-verify'
alias gitstatus='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git_status_with_modified.sh'
alias gitp='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git_push.sh'
alias gitcurs='git add CLAUDE.md .claude AGENTS.md .specstory .cursor .taskmaster .gitignore .cursorignore .cursorindexingignore HypeTrain/docs-hypetrain-alex/ && git commit -m "chore(docs)"'
alias githf='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/gitflow_hotfix.sh'
alias githf2='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/gitflow_hotfix2.sh'
alias gitmy='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/script_git_workflow.sh'
alias gitcom='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git_commit.sh'
alias gittag='git tag --sort=-creatordate | head -n 2'
alias gitfe='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/gitflow_feature.sh'
alias gitre='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/gitflow_release.sh'
alias gitdiff='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git_diff_files_and_content.sh'
alias gitpulls='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/gitpull.py'
alias greprpg='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/grep_airpg.sh'
alias git2txtl='git2txt --local'
alias gardendev='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden-fix && pwd && git status && git log -1 && gh run list --workflow=garden.yml --repo infludb-inc/hypetrain-garden --limit=3 && gh workflow run garden.yml --ref fix/garden -f backend=feat/add-script-quotas-token/us/506-2467 -f frontend=story/1029 -f env-name=debug -f env-type=dev -f force_rebuild=true'
alias gardenstage='cd /Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden-fix && pwd && git status && git log -1 && gh run list --workflow=garden-dev.yml --repo infludb-inc/hypetrain-garden --limit=3 && gh workflow run garden-stage.yml --ref fix/garden -f backend=feat/add-script-quotas-token/us/506-2467 -f frontend=story/1029 -f env-name=stage-debug1 -f load_production_data=true -f clean_database=true -f pgadmin=true'
alias gardendevstage='gardendev && gardenstage'
alias gitignoreAggregate='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor/gitignoreAggregation.py $@'

alias analysegit='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py'
alias analysegit-filtered='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py --typesexclude="md,json" --exclude-hidden --foldersexclude="test,logs"'
alias analysegit-last='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py --lastcommits'
alias analysegit-branches='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git-files-list-commits-analyzer.py --branches'

# 🤖 Claude-specific commits
alias gitclaude='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git/git-claude/git_claude_commit.sh'
