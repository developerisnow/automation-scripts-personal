#!/usr/bin/env zsh

# 🌳 Tree Commands
# ----------------
alias treeFiles2='timestamp=$(date "+%Y-%m-%d_%H-%M") && tree -L 4 > "treeAllFiles_____Sandruk-${timestamp}.md" && tree -L 4 -if --noreport > "treeFiles_____Sandruk-${timestamp}.csv" && echo "Files saved: treeAllFiles_____Sandruk-${timestamp}.[md/csv]"'
alias treeFiles='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeFilesEnchanced.sh'
alias treeGitFiles='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeGitFilesEnchanced.sh'
alias treeFolders='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeProjectsAndRootFolders.sh'
alias treeStructure='sh /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/treeFoldersStructure.sh'

