#!/usr/bin/env zsh
# TaskMaster symlinks
alias tasksymlinks="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/taskmaster_symlinks_enhanced.py"
alias tasksymlinks-watch="python3 /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/taskmaster_symlinks_enhanced.py --watch /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/taskmaster_projects.txt"
alias tasksymlinks-start="launchctl load ~/Library/LaunchAgents/com.user.taskmaster-symlinks.plist"
alias tasksymlinks-stop="launchctl unload ~/Library/LaunchAgents/com.user.taskmaster-symlinks.plist"
alias tasksymlinks-status="launchctl list | grep taskmaster-symlinks"
alias tasksymlinks-logs="tail -f /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/logs/taskmaster-symlinks.log"

# 📋 TaskMaster
# -------------
alias tm='cd /Users/user/__Repositories/claude-task-master'
alias taskmaster='cd /Users/user/__Repositories/llm-claude-task-master__by_eyaltoledano'
