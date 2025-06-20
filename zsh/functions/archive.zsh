#!/usr/bin/env zsh

# Archive functions
xz() {
    sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh xz "$1"
}

zstd() {
    sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh zstd "$1"
}

# File content update automation
alias addContentToFiles='python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/updateFilesRecursively.py'

# Archive functions
alias backupairpg='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh backup /Users/user/__Repositories/LLMs-airpg__belbix'

# Generic repo backup function
backup_repo() {
    sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/archiveations_automations.sh backup "$1"
}